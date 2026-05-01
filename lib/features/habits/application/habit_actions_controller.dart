import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entity/habit.dart';
import '../domain/entity/habit_category.dart';
import '../domain/service/habit_stats_service.dart';
import '../data/habit_repository.dart';
import 'habit_providers.dart';

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
        .map((id) => HabitStatsService.scopedAchievementKey(scope, id))
        .toList();
    return _repository.markAchievementsCelebrated(keys);
  }
}
