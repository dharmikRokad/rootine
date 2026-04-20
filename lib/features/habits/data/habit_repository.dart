import '../domain/habit.dart';
import '../domain/habit_completion.dart';

abstract class HabitRepository {
  Stream<List<Habit>> watchHabits();

  Stream<List<Habit>> watchArchivedHabits();

  Stream<List<HabitCompletion>> watchCompletions();

  Future<void> addHabit(Habit habit);

  Future<void> updateHabit(Habit habit);

  Future<void> archiveHabit(String habitId);

  Future<void> unarchiveHabit(String habitId);

  Future<void> deleteHabit(String habitId);

  Future<void> setHabitCompletion({
    required String habitId,
    required DateTime date,
    required bool isDone,
  });
}
