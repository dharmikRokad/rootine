import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_helpers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/firestore_habit_repository.dart';
import '../data/habit_repository.dart';
import '../domain/habit.dart';
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

final dueHabitsForSelectedDateProvider = Provider<AsyncValue<List<Habit>>>((
  ref,
) {
  final date = ref.watch(selectedDateProvider);
  final habitsValue = ref.watch(habitsProvider);

  return habitsValue.whenData(
    (habits) => habits.where((habit) => habit.isScheduledOn(date)).toList(),
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

  return HabitDetailStats(
    habit: habit,
    currentStreak: currentStreak,
    bestStreak: best,
    last30Due: due30,
    last30Completed: completed30,
    streakHistory: streakHistory,
    heatmap: heatmap,
    weeklyAdherence: weekly,
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

  double rangeRate(int days) {
    var totalDue = 0;
    var totalDone = 0;
    for (var i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      totalDue += countDue(day);
      totalDone += countDone(day);
    }
    if (totalDue == 0) {
      return 0;
    }
    return totalDone / totalDue;
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

  return HabitStats(
    todayTotal: countDue(today),
    todayCompleted: countDone(today),
    weekRate: rangeRate(7),
    monthRate: rangeRate(30),
    bestStreak: best,
    last14Days: buildTrend(14, today, countDue, countDone),
    last7Days: buildTrend(7, today, countDue, countDone),
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

final habitActionsProvider = Provider<HabitActions>((ref) {
  return HabitActions(ref.watch(habitRepositoryProvider));
});

class HabitActions {
  HabitActions(this._repository);

  final HabitRepository _repository;

  Future<void> createHabit({
    required String name,
    required HabitFrequency frequency,
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
    int? intervalDays,
    int? anchor,
  }) {
    return _repository.updateHabit(
      habit.copyWith(
        name: name,
        frequency: frequency,
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
  }) {
    return _repository.setHabitCompletion(
      habitId: habitId,
      date: date,
      isDone: isDone,
    );
  }
}
