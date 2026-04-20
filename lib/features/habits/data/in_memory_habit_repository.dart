import 'dart:async';

import '../../../core/date_helpers.dart';
import '../domain/habit.dart';
import '../domain/habit_completion.dart';
import 'habit_repository.dart';

class InMemoryHabitRepository implements HabitRepository {
  final _habits = <Habit>[];
  final _completions = <String, HabitCompletion>{};
  final _habitsController = StreamController<List<Habit>>.broadcast();
  final _completionsController =
      StreamController<List<HabitCompletion>>.broadcast();

  InMemoryHabitRepository() {
    _emit();
  }

  void _emit() {
    _habitsController.add(List.unmodifiable(_habits));
    _completionsController.add(List.unmodifiable(_completions.values));
  }

  @override
  Stream<List<Habit>> watchHabits() async* {
    yield List.unmodifiable(_habits.where((habit) => !habit.archived));
    yield* _habitsController.stream.map(
      (habits) => habits.where((habit) => !habit.archived).toList(),
    );
  }

  @override
  Stream<List<Habit>> watchArchivedHabits() async* {
    yield List.unmodifiable(_habits.where((habit) => habit.archived));
    yield* _habitsController.stream.map(
      (habits) => habits.where((habit) => habit.archived).toList(),
    );
  }

  @override
  Stream<List<HabitCompletion>> watchCompletions() async* {
    yield List.unmodifiable(_completions.values);
    yield* _completionsController.stream;
  }

  @override
  Future<void> addHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    _habits.add(habit);
    _emit();
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index == -1) {
      _habits.add(habit);
    } else {
      _habits[index] = habit;
    }
    _emit();
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) {
      return;
    }

    _habits[index] = _habits[index].copyWith(archived: true);
    _emit();
  }

  @override
  Future<void> unarchiveHabit(String habitId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) {
      return;
    }

    _habits[index] = _habits[index].copyWith(archived: false);
    _emit();
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    _completions.removeWhere((_, completion) => completion.habitId == habitId);
    _emit();
  }

  @override
  Future<void> setHabitCompletion({
    required String habitId,
    required DateTime date,
    required bool isDone,
  }) async {
    final normalized = normalizeDate(date);
    final id = '${habitId}_${dateKey(normalized)}';
    if (isDone) {
      _completions[id] = HabitCompletion(
        habitId: habitId,
        date: normalized,
        completedAt: DateTime.now(),
      );
    } else {
      _completions.remove(id);
    }

    _emit();
  }
}
