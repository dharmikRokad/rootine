import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/date_helpers.dart';
import '../domain/habit.dart';
import '../domain/habit_category.dart';
import '../domain/habit_completion.dart';
import 'habit_repository.dart';

class FirestoreHabitRepository implements HabitRepository {
  FirestoreHabitRepository(this._firestore, this._userId);

  final FirebaseFirestore _firestore;
  final String _userId;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_userId);

  CollectionReference<Map<String, dynamic>> get _habitsCollection =>
      _userDoc.collection('habits');

  CollectionReference<Map<String, dynamic>> get _completionsCollection =>
      _userDoc.collection('completions');

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _userDoc.collection('categories');

    CollectionReference<Map<String, dynamic>> get _achievementUnlocksCollection =>
      _userDoc.collection('achievementUnlocks');

  @override
  Stream<List<Habit>> watchHabits() {
    return _habitsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Habit.fromMap(doc.id, doc.data()))
              .where((habit) => !habit.archived)
              .toList(),
        );
  }

  @override
  Stream<List<Habit>> watchArchivedHabits() {
    return _habitsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Habit.fromMap(doc.id, doc.data()))
              .where((habit) => habit.archived)
              .toList(),
        );
  }

  @override
  Stream<List<HabitCategory>> watchCategories() {
    return _categoriesCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HabitCategory.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<HabitCompletion>> watchCompletions() {
    return _completionsCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => HabitCompletion.fromMap(doc.data()))
          .toList(),
    );
  }

  @override
  Stream<Map<String, bool>> watchAchievementCelebrationStatus() {
    return _achievementUnlocksCollection.snapshots().map((snapshot) {
      return {
        for (final doc in snapshot.docs)
          doc.id: (doc.data()['celebratedAt'] as int?) != null,
      };
    });
  }

  @override
  Future<void> addHabit(Habit habit) {
    return _habitsCollection.doc(habit.id).set(habit.toMap());
  }

  @override
  Future<void> updateHabit(Habit habit) {
    return _habitsCollection.doc(habit.id).update(habit.toMap());
  }

  @override
  Future<void> archiveHabit(String habitId) {
    return _habitsCollection.doc(habitId).update({'archived': true});
  }

  @override
  Future<void> unarchiveHabit(String habitId) {
    return _habitsCollection.doc(habitId).update({'archived': false});
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    final completions = await _completionsCollection
        .where('habitId', isEqualTo: habitId)
        .get();

    final batch = _firestore.batch();
    for (final doc in completions.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_habitsCollection.doc(habitId));
    await batch.commit();
  }

  @override
  Future<void> addCategory(HabitCategory category) {
    return _categoriesCollection.doc(category.id).set(category.toMap());
  }

  @override
  Future<void> updateCategory(HabitCategory category) {
    return _categoriesCollection.doc(category.id).update(category.toMap());
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    final habits = await _habitsCollection
        .where('categoryId', isEqualTo: categoryId)
        .get();

    final batch = _firestore.batch();
    for (final habitDoc in habits.docs) {
      batch.update(habitDoc.reference, {'categoryId': null});
    }
    batch.delete(_categoriesCollection.doc(categoryId));
    await batch.commit();
  }

  @override
  Future<void> ensureSystemCategories() async {
    final snapshot = await _categoriesCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final now = DateTime.now();
    for (final item in defaultHabitCategories) {
      batch.set(
        _categoriesCollection.doc(item.id),
        HabitCategory(
          id: item.id,
          name: item.name,
          colorValue: item.colorValue,
          isSystem: true,
          createdAt: now,
        ).toMap(),
      );
    }
    await batch.commit();
  }

  @override
  Future<void> setHabitCompletion({
    required String habitId,
    required DateTime date,
    required bool isDone,
    String? note,
  }) {
    final normalized = normalizeDate(date);
    final id = '${habitId}_${dateKey(normalized)}';
    final doc = _completionsCollection.doc(id);

    if (!isDone) {
      return doc.delete();
    }

    return doc.set(
      HabitCompletion(
        habitId: habitId,
        date: normalized,
        completedAt: DateTime.now(),
        note: note,
      ).toMap(),
    );
  }

  @override
  Future<void> setHabitCompletionNote({
    required String habitId,
    required DateTime date,
    required String note,
  }) {
    final normalized = normalizeDate(date);
    final id = '${habitId}_${dateKey(normalized)}';
    final doc = _completionsCollection.doc(id);
    return doc.set({
      'habitId': habitId,
      'date': dateKey(normalized),
      'completedAt': DateTime.now().millisecondsSinceEpoch,
      'note': note.trim(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> ensureAchievementUnlocked(String achievementKey) async {
    final doc = _achievementUnlocksCollection.doc(achievementKey);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      if (snapshot.exists) {
        return;
      }

      transaction.set(doc, {
        'unlockedAt': DateTime.now().millisecondsSinceEpoch,
        'celebratedAt': null,
      });
    });
  }

  @override
  Future<void> markAchievementsCelebrated(List<String> achievementKeys) async {
    if (achievementKeys.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final key in achievementKeys) {
      final doc = _achievementUnlocksCollection.doc(key);
      batch.set(doc, {'celebratedAt': now}, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
