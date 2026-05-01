import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_strings.dart';
import '../../../core/date_helpers.dart';
import '../../../core/remote_config_service.dart';
import '../../auth/application/auth_controller.dart';
import '../data/firestore_habit_repository.dart';
import '../data/habit_repository.dart';
import '../domain/entity/habit.dart';
import '../domain/entity/habit_category.dart';
import '../domain/entity/habit_completion.dart';

/// Holds the [RemoteConfigService] instance that was initialised in [main].
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  throw UnimplementedError(AppStrings.remoteConfigProviderNotOverridden);
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    throw StateError(AppStrings.userMustBeAuthenticated);
  }
  return FirestoreHabitRepository(FirebaseFirestore.instance, user.uid);
});

final selectedDateProvider = StateProvider<DateTime>((_) {
  return normalizeDate(DateTime.now());
});

final selectedCategoryFilterProvider = StateProvider<String?>((_) => null);

final categoriesBootstrapProvider = FutureProvider<void>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  final categories = remoteConfig.defaultCategories;
  await ref.read(habitRepositoryProvider).ensureSystemCategories(categories);
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
