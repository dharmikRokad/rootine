import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_helpers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/firestore_habit_repository.dart';
import '../data/habit_repository.dart';
import '../domain/habit.dart';
import '../domain/habit_category.dart';
import '../domain/habit_achievement.dart';
import '../domain/habit_completion.dart';
import '../domain/habit_detail_stats.dart';
import '../domain/habit_stats.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    throw StateError('User must be authenticated before loading habits.');
  }

  return FirestoreHabitRepository(FirebaseFirestore.instance, user.uid);
});

final selectedDateProvider = StateProvider<DateTime>((_) {
  return normalizeDate(DateTime.now());
});

final selectedCategoryFilterProvider = StateProvider<String?>((_) => null);

final categoriesBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(habitRepositoryProvider).ensureSystemCategories();
});

final categoriesProvider = StreamProvider<List<HabitCategory>>((ref) {
  return ref.watch(habitRepositoryProvider).watchCategories();
});

final categoryByIdProvider = Provider<Map<String, HabitCategory>>((ref) {
  final categoriesValue = ref.watch(categoriesProvider);
  return {
    for (final category in categoriesValue.value ?? const <HabitCategory>[])
      category.id: category,
  };
});

final habitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitRepositoryProvider).watchHabits();
});

final archivedHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitRepositoryProvider).watchArchivedHabits();
});

final allHabitsProvider = Provider<AsyncValue<List<Habit>>>((ref) {
  final active = ref.watch(habitsProvider);
  final archived = ref.watch(archivedHabitsProvider);

  if (active.isLoading || archived.isLoading) {
    return const AsyncValue.loading();
  }
  if (active.hasError) {
    return AsyncValue.error(active.error!, active.stackTrace!);
  }
  if (archived.hasError) {
    return AsyncValue.error(archived.error!, archived.stackTrace!);
  }

  return AsyncValue.data([
    ...(active.value ?? const <Habit>[]),
    ...(archived.value ?? const <Habit>[]),
  ]);
});

final completionsProvider = StreamProvider<List<HabitCompletion>>((ref) {
  return ref.watch(habitRepositoryProvider).watchCompletions();
});

final achievementCelebrationStatusProvider = StreamProvider<Map<String, bool>>((
  ref,
) {
  return ref.watch(habitRepositoryProvider).watchAchievementCelebrationStatus();
});

final dueHabitsForSelectedDateProvider = Provider<AsyncValue<List<Habit>>>((
  ref,
) {
  final date = ref.watch(selectedDateProvider);
  final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);
  final habitsValue = ref.watch(habitsProvider);

  return habitsValue.whenData(
    (habits) => habits
        .where((habit) => habit.isScheduledOn(date))
        .where(
          (habit) =>
              selectedCategoryId == null ||
              habit.categoryId == selectedCategoryId,
        )
        .toList(),
  );
});

final completionSetForSelectedDateProvider = Provider<AsyncValue<Set<String>>>((
  ref,
) {
  final date = ref.watch(selectedDateProvider);
  final completionsValue = ref.watch(completionsProvider);

  return completionsValue.whenData(
    (completions) => completions
        .where((completion) => dateKey(completion.date) == dateKey(date))
        .map((completion) => completion.habitId)
        .toSet(),
  );
});

final habitStatsProvider = Provider<AsyncValue<HabitStats>>((ref) {
  final habitsValue = ref.watch(habitsProvider);
  final completionsValue = ref.watch(completionsProvider);

  if (habitsValue.isLoading || completionsValue.isLoading) {
    return const AsyncValue.loading();
  }
  if (habitsValue.hasError) {
    return AsyncValue.error(habitsValue.error!, habitsValue.stackTrace!);
  }
  if (completionsValue.hasError) {
    return AsyncValue.error(
      completionsValue.error!,
      completionsValue.stackTrace!,
    );
  }

  final habits = habitsValue.value ?? <Habit>[];
  final completions = completionsValue.value ?? <HabitCompletion>[];
  return AsyncValue.data(_buildStats(habits, completions));
});

final overallAchievementsProvider =
    Provider<AsyncValue<List<HabitAchievement>>>((ref) {
      final habitsValue = ref.watch(habitsProvider);
      final completionsValue = ref.watch(completionsProvider);
      final statsValue = ref.watch(habitStatsProvider);
      final celebrationStatusValue = ref.watch(
        achievementCelebrationStatusProvider,
      );

      if (habitsValue.isLoading ||
          completionsValue.isLoading ||
          statsValue.isLoading ||
          celebrationStatusValue.isLoading) {
        return const AsyncValue.loading();
      }
      if (habitsValue.hasError) {
        return AsyncValue.error(habitsValue.error!, habitsValue.stackTrace!);
      }
      if (completionsValue.hasError) {
        return AsyncValue.error(
          completionsValue.error!,
          completionsValue.stackTrace!,
        );
      }
      if (statsValue.hasError) {
        return AsyncValue.error(statsValue.error!, statsValue.stackTrace!);
      }
      if (celebrationStatusValue.hasError) {
        return AsyncValue.error(
          celebrationStatusValue.error!,
          celebrationStatusValue.stackTrace!,
        );
      }

      final habits = habitsValue.value ?? const <Habit>[];
      final completions = completionsValue.value ?? const <HabitCompletion>[];
      final stats = statsValue.value;
      if (stats == null) {
        return const AsyncValue.data(<HabitAchievement>[]);
      }

      final achievements = _buildOverallAchievements(
        habits,
        completions,
        stats,
      );
      final celebrationStatus =
          celebrationStatusValue.value ?? const <String, bool>{};

      return AsyncValue.data(
        _withCelebrationState(
          achievements,
          scope: 'overall',
          celebrationStatus: celebrationStatus,
        ),
      );
    });

final syncOverallAchievementUnlocksProvider = FutureProvider<void>((ref) async {
  final achievements = ref.watch(overallAchievementsProvider).value;
  final celebrationStatus =
      ref.watch(achievementCelebrationStatusProvider).value ??
      const <String, bool>{};

  if (achievements == null) {
    return;
  }

  final repository = ref.watch(habitRepositoryProvider);
  for (final achievement in achievements) {
    if (!achievement.unlocked) {
      continue;
    }
    final key = _scopedAchievementKey('overall', achievement.id);
    if (celebrationStatus.containsKey(key)) {
      continue;
    }
    await repository.ensureAchievementUnlocked(key);
  }
});

final habitDetailStatsProvider =
    Provider.family<AsyncValue<HabitDetailStats>, String>((ref, habitId) {
      final habitsValue = ref.watch(allHabitsProvider);
      final completionsValue = ref.watch(completionsProvider);

      if (habitsValue.isLoading || completionsValue.isLoading) {
        return const AsyncValue.loading();
      }
      if (habitsValue.hasError) {
        return AsyncValue.error(habitsValue.error!, habitsValue.stackTrace!);
      }
      if (completionsValue.hasError) {
        return AsyncValue.error(
          completionsValue.error!,
          completionsValue.stackTrace!,
        );
      }

      final habits = habitsValue.value ?? <Habit>[];
      final habit = habits.where((h) => h.id == habitId).firstOrNull;
      if (habit == null) {
        return AsyncValue.error(
          StateError('Habit not found'),
          StackTrace.current,
        );
      }

      final completions = completionsValue.value ?? <HabitCompletion>[];
      return AsyncValue.data(_buildHabitDetailStats(habit, completions));
    });

final habitAchievementsProvider =
    Provider.family<AsyncValue<List<HabitAchievement>>, String>((ref, habitId) {
      final detailStatsValue = ref.watch(habitDetailStatsProvider(habitId));
      final celebrationStatusValue = ref.watch(
        achievementCelebrationStatusProvider,
      );

      if (detailStatsValue.isLoading || celebrationStatusValue.isLoading) {
        return const AsyncValue.loading();
      }
      if (detailStatsValue.hasError) {
        return AsyncValue.error(
          detailStatsValue.error!,
          detailStatsValue.stackTrace!,
        );
      }
      if (celebrationStatusValue.hasError) {
        return AsyncValue.error(
          celebrationStatusValue.error!,
          celebrationStatusValue.stackTrace!,
        );
      }

      final stats = detailStatsValue.value;
      if (stats == null) {
        return const AsyncValue.data(<HabitAchievement>[]);
      }
      final achievements = _buildHabitAchievements(stats);
      final celebrationStatus =
          celebrationStatusValue.value ?? const <String, bool>{};
      return AsyncValue.data(
        _withCelebrationState(
          achievements,
          scope: 'habit:$habitId',
          celebrationStatus: celebrationStatus,
        ),
      );
    });

final syncHabitAchievementUnlocksProvider = FutureProvider.family<void, String>(
  (ref, habitId) async {
    final achievements = ref.watch(habitAchievementsProvider(habitId)).value;
    final celebrationStatus =
        ref.watch(achievementCelebrationStatusProvider).value ??
        const <String, bool>{};

    if (achievements == null) {
      return;
    }

    final repository = ref.watch(habitRepositoryProvider);
    for (final achievement in achievements) {
      if (!achievement.unlocked) {
        continue;
      }
      final key = _scopedAchievementKey('habit:$habitId', achievement.id);
      if (celebrationStatus.containsKey(key)) {
        continue;
      }
      await repository.ensureAchievementUnlocked(key);
    }
  },
);

HabitDetailStats _buildHabitDetailStats(
  Habit habit,
  List<HabitCompletion> completions,
) {
  final today = normalizeDate(DateTime.now());
  final completedKeys = completions
      .where((completion) => completion.habitId == habit.id)
      .map((completion) => dateKey(completion.date))
      .toSet();

  var currentStreak = 0;
  for (var i = 0; i < 365; i++) {
    final day = today.subtract(Duration(days: i));
    if (!habit.isScheduledOn(day)) {
      continue;
    }

    final done = completedKeys.contains(dateKey(day));
    if (!done) {
      break;
    }
    currentStreak++;
  }

  var rolling = 0;
  var best = 0;
  final streakHistory = <HabitStreakPoint>[];
  for (var i = 29; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    if (habit.isScheduledOn(day) && completedKeys.contains(dateKey(day))) {
      rolling++;
    } else if (habit.isScheduledOn(day)) {
      rolling = 0;
    }

    if (rolling > best) {
      best = rolling;
    }
    streakHistory.add(HabitStreakPoint(date: day, streak: rolling));
  }

  var due30 = 0;
  var completed30 = 0;
  for (var i = 0; i < 30; i++) {
    final day = today.subtract(Duration(days: i));
    if (!habit.isScheduledOn(day)) {
      continue;
    }
    due30++;
    if (completedKeys.contains(dateKey(day))) {
      completed30++;
    }
  }

  final heatmap = <HabitHeatmapCell>[];
  for (var i = 83; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    HabitHeatmapStatus status;
    if (!habit.isScheduledOn(day)) {
      status = HabitHeatmapStatus.notScheduled;
    } else if (completedKeys.contains(dateKey(day))) {
      status = HabitHeatmapStatus.completed;
    } else {
      status = HabitHeatmapStatus.missed;
    }
    heatmap.add(HabitHeatmapCell(date: day, status: status));
  }

  final weekly = <HabitWeeklyAdherencePoint>[];
  final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
  for (var i = 7; i >= 0; i--) {
    final weekStart = startOfThisWeek.subtract(Duration(days: i * 7));
    var due = 0;
    var completed = 0;
    for (var d = 0; d < 7; d++) {
      final day = weekStart.add(Duration(days: d));
      if (!habit.isScheduledOn(day)) {
        continue;
      }
      due++;
      if (completedKeys.contains(dateKey(day))) {
        completed++;
      }
    }
    weekly.add(
      HabitWeeklyAdherencePoint(
        weekStart: weekStart,
        due: due,
        completed: completed,
      ),
    );
  }

  final recentNotes =
      completions
          .where((completion) => completion.habitId == habit.id)
          .where((completion) => (completion.note ?? '').trim().isNotEmpty)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  return HabitDetailStats(
    habit: habit,
    currentStreak: currentStreak,
    bestStreak: best,
    last30Due: due30,
    last30Completed: completed30,
    streakHistory: streakHistory,
    heatmap: heatmap,
    weeklyAdherence: weekly,
    recentNotes: recentNotes
        .map(
          (completion) => HabitCompletionNoteItem(
            date: completion.date,
            note: (completion.note ?? '').trim(),
          ),
        )
        .take(20)
        .toList(),
  );
}

HabitStats _buildStats(List<Habit> habits, List<HabitCompletion> completions) {
  final today = normalizeDate(DateTime.now());
  final completionIndex = <String, Set<String>>{};

  for (final completion in completions) {
    final key = dateKey(completion.date);
    final set = completionIndex.putIfAbsent(key, () => <String>{});
    set.add(completion.habitId);
  }

  int countDue(DateTime date) {
    return habits.where((habit) => habit.isScheduledOn(date)).length;
  }

  int countDone(DateTime date) {
    final key = dateKey(date);
    final set = completionIndex[key] ?? <String>{};
    return habits
        .where((habit) => habit.isScheduledOn(date) && set.contains(habit.id))
        .length;
  }

  ({int due, int done}) rangeTotals(int startOffsetDays, int days) {
    var totalDue = 0;
    var totalDone = 0;
    for (var i = startOffsetDays; i < startOffsetDays + days; i++) {
      final day = today.subtract(Duration(days: i));
      totalDue += countDue(day);
      totalDone += countDone(day);
    }
    return (due: totalDue, done: totalDone);
  }

  double rateFromTotals(({int due, int done}) totals) {
    if (totals.due == 0) {
      return 0;
    }
    return totals.done / totals.due;
  }

  int currentStreak(Habit habit) {
    var streak = 0;
    for (var i = 0; i < 365; i++) {
      final day = today.subtract(Duration(days: i));
      if (!habit.isScheduledOn(day)) {
        continue;
      }

      final done = completionIndex[dateKey(day)]?.contains(habit.id) ?? false;
      if (!done) {
        break;
      }
      streak++;
    }
    return streak;
  }

  var best = 0;
  for (final habit in habits) {
    best = max(best, currentStreak(habit));
  }

  final weekTotals = rangeTotals(0, 7);
  final previousWeekTotals = rangeTotals(7, 7);
  final monthTotals = rangeTotals(0, 30);

  final weekdayDue = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
  final weekdayDone = <int, int>{for (var i = 1; i <= 7; i++) i: 0};

  for (var i = 0; i < 56; i++) {
    final day = today.subtract(Duration(days: i));
    final weekday = day.weekday;
    weekdayDue[weekday] = (weekdayDue[weekday] ?? 0) + countDue(day);
    weekdayDone[weekday] = (weekdayDone[weekday] ?? 0) + countDone(day);
  }

  var bestWeekday = today.weekday;
  var bestWeekdayRate = 0.0;
  for (var weekday = 1; weekday <= 7; weekday++) {
    final due = weekdayDue[weekday] ?? 0;
    final done = weekdayDone[weekday] ?? 0;
    if (due == 0) {
      continue;
    }
    final rate = done / due;
    if (rate > bestWeekdayRate) {
      bestWeekdayRate = rate;
      bestWeekday = weekday;
    }
  }

  final weekRate = rateFromTotals(weekTotals);
  final previousWeekRate = rateFromTotals(previousWeekTotals);
  final monthRate = rateFromTotals(monthTotals);
  final consistencyScore = ((weekRate * 0.6) + (monthRate * 0.4))
      .clamp(0, 1)
      .toDouble();

  final rolling7DayRate = <HabitRollingRatePoint>[];
  for (var i = 29; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final totals = rangeTotals(i, 7);
    rolling7DayRate.add(
      HabitRollingRatePoint(date: day, rate: rateFromTotals(totals)),
    );
  }

  final weekdayPerformance = List.generate(
    7,
    (index) => HabitWeekdayPerformancePoint(
      weekday: index + 1,
      due: weekdayDue[index + 1] ?? 0,
      completed: weekdayDone[index + 1] ?? 0,
    ),
  );

  return HabitStats(
    todayTotal: countDue(today),
    todayCompleted: countDone(today),
    activeHabits: habits.length,
    weekRate: weekRate,
    previousWeekRate: previousWeekRate,
    monthRate: monthRate,
    last30Due: monthTotals.due,
    last30Completed: monthTotals.done,
    consistencyScore: consistencyScore,
    bestWeekday: bestWeekday,
    bestWeekdayRate: bestWeekdayRate,
    momentum: weekRate - previousWeekRate,
    bestStreak: best,
    last14Days: buildTrend(14, today, countDue, countDone),
    last7Days: buildTrend(7, today, countDue, countDone),
    rolling7DayRate: rolling7DayRate,
    weekdayPerformance: weekdayPerformance,
  );
}

List<HabitTrendPoint> buildTrend(
  int days,
  DateTime today,
  int Function(DateTime) countDue,
  int Function(DateTime) countDone,
) {
  final points = <HabitTrendPoint>[];
  for (var i = days - 1; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    points.add(
      HabitTrendPoint(date: day, due: countDue(day), completed: countDone(day)),
    );
  }
  return points;
}

List<HabitAchievement> _buildOverallAchievements(
  List<Habit> habits,
  List<HabitCompletion> completions,
  HabitStats stats,
) {
  final completionCount = completions.length;
  final categoriesUsed = habits
      .where((habit) => habit.categoryId != null)
      .map((h) => h.categoryId)
      .toSet()
      .length;
  final perfectToday =
      stats.todayTotal > 0 && stats.todayCompleted == stats.todayTotal;

  return [
    HabitAchievement(
      id: 'first_checkin',
      title: 'First Check-in',
      description: 'Complete your first habit check-in.',
      unlocked: completionCount >= 1,
      progress: _progress(completionCount, 1),
      targetLabel: '$completionCount/1 completions',
    ),
    HabitAchievement(
      id: 'week_streak',
      title: 'Week Warrior',
      description: 'Reach a 7-check-in streak on any habit.',
      unlocked: stats.bestStreak >= 7,
      progress: _progress(stats.bestStreak, 7),
      targetLabel: '${stats.bestStreak}/7 streak',
    ),
    HabitAchievement(
      id: 'monthly_master',
      title: 'Monthly Master',
      description: 'Hit 80% completion rate over the last 30 days.',
      unlocked: stats.monthRate >= 0.8 && stats.last30Due >= 10,
      progress: _progress((stats.monthRate * 100).round(), 80),
      targetLabel: '${(stats.monthRate * 100).toStringAsFixed(0)}%/80%',
    ),
    HabitAchievement(
      id: 'perfect_today',
      title: 'Perfect Day',
      description: 'Complete every scheduled habit for today.',
      unlocked: perfectToday,
      progress: stats.todayTotal == 0
          ? 0
          : _progress(stats.todayCompleted, stats.todayTotal),
      targetLabel: '${stats.todayCompleted}/${stats.todayTotal} today',
    ),
    HabitAchievement(
      id: 'category_explorer',
      title: 'Category Explorer',
      description: 'Track habits across 3 different categories.',
      unlocked: categoriesUsed >= 3,
      progress: _progress(categoriesUsed, 3),
      targetLabel: '$categoriesUsed/3 categories',
    ),
  ];
}

List<HabitAchievement> _buildHabitAchievements(HabitDetailStats stats) {
  final notesCount = stats.recentNotes.length;

  return [
    HabitAchievement(
      id: 'first_rep',
      title: 'First Rep',
      description: 'Complete this habit at least once.',
      unlocked: stats.bestStreak >= 1,
      progress: _progress(stats.bestStreak, 1),
      targetLabel: '${stats.bestStreak}/1 streak',
    ),
    HabitAchievement(
      id: 'streak_3',
      title: 'Triple Streak',
      description: 'Reach a 3-check-in streak on this habit.',
      unlocked: stats.bestStreak >= 3,
      progress: _progress(stats.bestStreak, 3),
      targetLabel: '${stats.bestStreak}/3 streak',
    ),
    HabitAchievement(
      id: 'streak_7',
      title: 'Unbreakable Week',
      description: 'Reach a 7-check-in streak on this habit.',
      unlocked: stats.bestStreak >= 7,
      progress: _progress(stats.bestStreak, 7),
      targetLabel: '${stats.bestStreak}/7 streak',
    ),
    HabitAchievement(
      id: 'habit_consistency',
      title: 'Precision Mode',
      description: 'Achieve 90% adherence for this habit over 30 days.',
      unlocked: stats.last30Rate >= 0.9 && stats.last30Due >= 10,
      progress: _progress((stats.last30Rate * 100).round(), 90),
      targetLabel: '${(stats.last30Rate * 100).toStringAsFixed(0)}%/90%',
    ),
    HabitAchievement(
      id: 'note_keeper',
      title: 'Reflective Runner',
      description: 'Capture 5 completion notes for this habit.',
      unlocked: notesCount >= 5,
      progress: _progress(notesCount, 5),
      targetLabel: '$notesCount/5 notes',
    ),
  ];
}

double _progress(int value, int target) {
  if (target <= 0) {
    return 0;
  }
  return (value / target).clamp(0, 1).toDouble();
}

String _scopedAchievementKey(String scope, String achievementId) {
  return '$scope::$achievementId';
}

List<HabitAchievement> _withCelebrationState(
  List<HabitAchievement> achievements, {
  required String scope,
  required Map<String, bool> celebrationStatus,
}) {
  return achievements.map((achievement) {
    final key = _scopedAchievementKey(scope, achievement.id);
    final celebrated = celebrationStatus[key];
    final isNewlyUnlocked = achievement.unlocked && celebrated == false;
    return achievement.copyWith(isNewlyUnlocked: isNewlyUnlocked);
  }).toList();
}

final habitActionsProvider = Provider<HabitActions>((ref) {
  return HabitActions(ref.watch(habitRepositoryProvider));
});

class HabitActions {
  HabitActions(this._repository);

  final HabitRepository _repository;

  Future<void> createHabit({
    required String name,
    required HabitFrequency frequency,
    String? categoryId,
    int? intervalDays,
    int? anchor,
  }) {
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}_${Random().nextInt(9999)}';

    return _repository.addHabit(
      Habit(
        id: id,
        name: name,
        frequency: frequency,
        categoryId: categoryId,
        intervalDays: intervalDays,
        anchor: anchor,
        createdAt: now,
      ),
    );
  }

  Future<void> editHabit({
    required Habit habit,
    required String name,
    required HabitFrequency frequency,
    String? categoryId,
    int? intervalDays,
    int? anchor,
  }) {
    return _repository.updateHabit(
      habit.copyWith(
        name: name,
        frequency: frequency,
        categoryId: categoryId,
        intervalDays: intervalDays,
        anchor: anchor,
      ),
    );
  }

  Future<void> archiveHabit(String habitId) {
    return _repository.archiveHabit(habitId);
  }

  Future<void> unarchiveHabit(String habitId) {
    return _repository.unarchiveHabit(habitId);
  }

  Future<void> deleteHabit(String habitId) {
    return _repository.deleteHabit(habitId);
  }

  Future<void> setCompleted({
    required String habitId,
    required DateTime date,
    required bool isDone,
    String? note,
  }) {
    return _repository.setHabitCompletion(
      habitId: habitId,
      date: date,
      isDone: isDone,
      note: note,
    );
  }

  Future<void> setCompletionNote({
    required String habitId,
    required DateTime date,
    required String note,
  }) {
    return _repository.setHabitCompletionNote(
      habitId: habitId,
      date: date,
      note: note,
    );
  }

  Future<HabitCategory> createCategory({
    required String name,
    required int colorValue,
  }) async {
    final now = DateTime.now();
    final id = 'cat_${now.microsecondsSinceEpoch}_${Random().nextInt(9999)}';
    final category = HabitCategory(
      id: id,
      name: name,
      colorValue: colorValue,
      isSystem: false,
      createdAt: now,
    );
    await _repository.addCategory(category);
    return category;
  }

  Future<void> updateCategory({
    required HabitCategory category,
    required String name,
    int? colorValue,
  }) {
    return _repository.updateCategory(
      category.copyWith(
        name: name,
        colorValue: colorValue ?? category.colorValue,
      ),
    );
  }

  Future<void> deleteCategory(String categoryId) {
    return _repository.deleteCategory(categoryId);
  }

  Future<void> markAchievementsCelebrated(
    String scope,
    List<String> achievementIds,
  ) {
    final keys = achievementIds
        .map((id) => _scopedAchievementKey(scope, id))
        .toList();
    return _repository.markAchievementsCelebrated(keys);
  }
}
