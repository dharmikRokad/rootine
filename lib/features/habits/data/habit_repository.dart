import '../domain/entity/habit.dart';
import '../domain/entity/habit_category.dart';
import '../domain/entity/habit_completion.dart';

abstract class HabitRepository {
  Stream<List<Habit>> watchHabits();

  Stream<List<Habit>> watchArchivedHabits();

  Stream<List<HabitCategory>> watchCategories();

  Stream<List<HabitCompletion>> watchCompletions();

  Future<void> addHabit(Habit habit);

  Future<void> updateHabit(Habit habit);

  Future<void> archiveHabit(String habitId);

  Future<void> unarchiveHabit(String habitId);

  Future<void> deleteHabit(String habitId);

  Future<void> addCategory(HabitCategory category);

  Future<void> updateCategory(HabitCategory category);

  Future<void> deleteCategory(String categoryId);

  Future<void> ensureSystemCategories(
    List<({String id, String name, int colorValue})> categories,
  );

  Future<void> setHabitCompletion({
    required String habitId,
    required DateTime date,
    required bool isDone,
    String? note,
  });

  Future<void> setHabitCompletionNote({
    required String habitId,
    required DateTime date,
    required String note,
  });

  Future<void> deleteAllUserData();
}
