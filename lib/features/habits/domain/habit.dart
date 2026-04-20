import '../../../core/date_helpers.dart';

enum HabitFrequency { daily, weekly, monthly, interval }

extension HabitFrequencyLabel on HabitFrequency {
  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.interval:
        return 'Every n days';
    }
  }
}

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.frequency,
    required this.createdAt,
    this.intervalDays,
    this.anchor,
    this.archived = false,
  });

  final String id;
  final String name;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final int? intervalDays;
  final int? anchor;
  final bool archived;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'frequency': frequency.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'intervalDays': intervalDays,
      'anchor': anchor,
      'archived': archived,
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    HabitFrequency? frequency,
    DateTime? createdAt,
    int? intervalDays,
    int? anchor,
    bool? archived,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      intervalDays: intervalDays ?? this.intervalDays,
      anchor: anchor ?? this.anchor,
      archived: archived ?? this.archived,
    );
  }

  bool isScheduledOn(DateTime day) {
    final selectedDay = normalizeDate(day);

    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        final targetWeekday = anchor ?? createdAt.weekday;
        return selectedDay.weekday == targetWeekday;
      case HabitFrequency.monthly:
        final targetDay = anchor ?? createdAt.day;
        return selectedDay.day == targetDay;
      case HabitFrequency.interval:
        final start = normalizeDate(createdAt);
        final diff = selectedDay.difference(start).inDays;
        if (diff < 0) {
          return false;
        }
        final interval = intervalDays ?? 1;
        return diff % interval == 0;
    }
  }

  static Habit fromMap(String id, Map<String, dynamic> map) {
    final createdRaw = map['createdAt'];
    final createdAt = createdRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(createdRaw)
        : DateTime.now();

    return Habit(
      id: id,
      name: (map['name'] as String?) ?? 'Untitled Habit',
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == map['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      createdAt: createdAt,
      intervalDays: map['intervalDays'] as int?,
      anchor: map['anchor'] as int?,
      archived: (map['archived'] as bool?) ?? false,
    );
  }
}
