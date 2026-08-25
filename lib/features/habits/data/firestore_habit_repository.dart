import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/date_helpers.dart';
import '../domain/entity/habit.dart';
import '../domain/entity/habit_category.dart';
import '../domain/entity/habit_completion.dart';
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
  Future<void> ensureSystemCategories(
    List<({String id, String name, int colorValue})> categories,
  ) async {
    final snapshot = await _categoriesCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final now = DateTime.now();
    for (final item in categories) {
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
  }) async {
    final normalized = normalizeDate(date);
    final id = '${habitId}_${dateKey(normalized)}';
    final doc = _completionsCollection.doc(id);

    final cleanNote = note?.trim();
    if (!isDone && (cleanNote == null || cleanNote.isEmpty)) {
      final snap = await doc.get();
      if (snap.exists) {
        final existingNote = snap.data()?['note'] as String?;
        if (existingNote == null || existingNote.trim().isEmpty) {
          return doc.delete();
        } else {
          return doc.set({
            'isCompleted': false,
          }, SetOptions(merge: true));
        }
      }
      return;
    }

    return doc.set(
      HabitCompletion(
        habitId: habitId,
        date: normalized,
        completedAt: DateTime.now(),
        isCompleted: isDone,
        note: cleanNote,
      ).toMap(),
      SetOptions(merge: true),
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
    final cleanNote = note.trim();

    return doc.set({
      'habitId': habitId,
      'date': dateKey(normalized),
      'completedAt': Timestamp.now(),
      'note': cleanNote.isEmpty ? null : cleanNote,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteAllUserData() async {
    await _deleteCollection(_habitsCollection);
    await _deleteCollection(_completionsCollection);
    await _deleteCollection(_categoriesCollection);
    await _userDoc.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    const batchSize = 300;
    while (true) {
      final snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
