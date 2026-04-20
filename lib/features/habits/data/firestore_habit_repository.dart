import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/date_helpers.dart';
import '../domain/habit.dart';
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
  Future<void> setHabitCompletion({
    required String habitId,
    required DateTime date,
    required bool isDone,
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
      ).toMap(),
    );
  }
}
