import '../../../core/date_helpers.dart';

class HabitCompletion {
  const HabitCompletion({
    required this.habitId,
    required this.date,
    required this.completedAt,
  });

  final String habitId;
  final DateTime date;
  final DateTime completedAt;

  String get id => '${habitId}_${dateKey(date)}';

  Map<String, Object?> toMap() {
    return {
      'habitId': habitId,
      'date': dateKey(date),
      'completedAt': completedAt.millisecondsSinceEpoch,
    };
  }

  static HabitCompletion fromMap(Map<String, dynamic> map) {
    final dateParts = ((map['date'] as String?) ?? '').split('-');
    DateTime parsedDate;
    if (dateParts.length == 3) {
      parsedDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
    } else {
      parsedDate = DateTime.now();
    }

    final completedRaw = map['completedAt'];
    final completedAt = completedRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(completedRaw)
        : DateTime.now();

    return HabitCompletion(
      habitId: (map['habitId'] as String?) ?? '',
      date: normalizeDate(parsedDate),
      completedAt: completedAt,
    );
  }
}
