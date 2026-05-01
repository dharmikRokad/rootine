import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entity/habit.dart';
import '../domain/entity/habit_achievement.dart';
import '../domain/entity/habit_completion.dart';
import '../domain/service/habit_stats_service.dart';
import 'habit_providers.dart';
import 'stats_providers.dart';

final achievementCelebrationStatusProvider = StreamProvider<Map<String, bool>>((ref) {
  return ref.watch(habitRepositoryProvider).watchAchievementCelebrationStatus();
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

      final achievements = HabitStatsService.buildOverallAchievements(
        habits,
        completions,
        stats,
      );
      final celebrationStatus =
          celebrationStatusValue.value ?? const <String, bool>{};

      return AsyncValue.data(
        HabitStatsService.withCelebrationState(
          achievements,
          scope: 'overall',
          celebrationStatus: celebrationStatus,
        ),
      );
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
      final achievements = HabitStatsService.buildHabitAchievements(stats);
      final celebrationStatus =
          celebrationStatusValue.value ?? const <String, bool>{};
      return AsyncValue.data(
        HabitStatsService.withCelebrationState(
          achievements,
          scope: 'habit:$habitId',
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
    final key = HabitStatsService.scopedAchievementKey('overall', achievement.id);
    if (celebrationStatus.containsKey(key)) {
      continue;
    }
    await repository.ensureAchievementUnlocked(key);
  }
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
      final key = HabitStatsService.scopedAchievementKey('habit:$habitId', achievement.id);
      if (celebrationStatus.containsKey(key)) {
        continue;
      }
      await repository.ensureAchievementUnlocked(key);
    }
  },
);
