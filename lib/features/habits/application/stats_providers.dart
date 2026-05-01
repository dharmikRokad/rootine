import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_strings.dart';
import '../domain/entity/habit.dart';
import '../domain/entity/habit_completion.dart';
import '../domain/entity/habit_detail_stats.dart';
import '../domain/entity/habit_stats.dart';
import '../domain/service/habit_stats_service.dart';
import 'habit_providers.dart';

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
  return AsyncValue.data(HabitStatsService.buildStats(habits, completions));
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
          StateError(AppStrings.habitNotFound),
          StackTrace.current,
        );
      }

      final completions = completionsValue.value ?? <HabitCompletion>[];
      return AsyncValue.data(
        HabitStatsService.buildHabitDetailStats(habit, completions),
      );
    });
