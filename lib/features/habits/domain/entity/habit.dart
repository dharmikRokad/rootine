import '../../../../core/date_helpers.dart';

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
    this.categoryId,
    this.intervalDays,
    this.anchor,
    this.archived = false,
    // YYYY-MM-DD string: the calendar day the habit was created.
    // Stored as a date-only string to avoid timezone drift when the device
    // moves across time zones between creation and future reads.
    // Null for legacy documents – falls back to a far-past epoch so that
    // historical completions are preserved instead of being hidden.
    this.startDate,
    // YYYY-MM-DD string: the calendar day the *current* schedule took effect.
    // Updated to today whenever frequency / anchor / intervalDays changes so
    // the new schedule is not back-projected onto past days.
    // Null for legacy documents – no schedule cutoff is applied.
    this.scheduleUpdatedAt,
  });

  final String id;
  final String name;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final String? categoryId;
  final int? intervalDays;
  final int? anchor;
  final bool archived;
  final String? startDate;
  final String? scheduleUpdatedAt;

  // Parses a stored YYYY-MM-DD string into a local midnight DateTime.
  // Falls back to a far-past epoch on malformed input so that corrupted
  // Firestore data doesn't cause a runtime crash; the habit will simply
  // appear from the beginning of time (same safe default as legacy documents).
  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return DateTime(2000);
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return DateTime(2000);
    }
  }

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'frequency': frequency.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'categoryId': categoryId,
      'intervalDays': intervalDays,
      'anchor': anchor,
      'archived': archived,
      'startDate': startDate,
      'scheduleUpdatedAt': scheduleUpdatedAt,
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    HabitFrequency? frequency,
    DateTime? createdAt,
    String? categoryId,
    int? intervalDays,
    int? anchor,
    bool? archived,
    String? startDate,
    String? scheduleUpdatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      categoryId: categoryId ?? this.categoryId,
      intervalDays: intervalDays ?? this.intervalDays,
      anchor: anchor ?? this.anchor,
      archived: archived ?? this.archived,
      startDate: startDate ?? this.startDate,
      scheduleUpdatedAt: scheduleUpdatedAt ?? this.scheduleUpdatedAt,
    );
  }

  bool isScheduledOn(DateTime day) {
    final selectedDay = normalizeDate(day);

    // --- creation-date boundary ---
    // Prefer the timezone-stable startDate string. Fall back to normalizing
    // the createdAt timestamp for habits created before startDate was added.
    // Legacy habits with neither field use a far-past epoch so all their
    // historical completions remain visible (fixes Comment 1).
    final effectiveStart = startDate != null
        ? _parseDate(startDate!)
        : normalizeDate(createdAt);

    if (selectedDay.isBefore(effectiveStart)) {
      return false;
    }

    // --- schedule boundary ---
    // When the schedule (frequency / anchor / intervalDays) was changed after
    // creation, don't project the new schedule backwards onto days before the
    // change. Only applied when the field is present; legacy habits have no
    // cutoff so their existing view is unchanged (fixes Comment 4).
    final DateTime? scheduleStart =
        scheduleUpdatedAt != null ? _parseDate(scheduleUpdatedAt!) : null;

    if (scheduleStart != null && selectedDay.isBefore(scheduleStart)) {
      return false;
    }

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
        // Use scheduleUpdatedAt as the interval origin when available so the
        // interval cadence restarts from the day the schedule was set.
        final refDate = scheduleStart ?? effectiveStart;
        final diff = selectedDay.difference(refDate).inDays;
        if (diff < 0) {
          return false;
        }
        final interval = intervalDays ?? 1;
        return diff % interval == 0;
    }
  }

  static Habit fromMap(String id, Map<String, dynamic> map) {
    final createdRaw = map['createdAt'];
    // Fix Comment 1: use a far-past epoch as the fallback so that legacy
    // habits without a stored createdAt timestamp preserve all historical
    // data instead of being treated as "created today".
    final createdAt = createdRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(createdRaw)
        : DateTime(2000);

    return Habit(
      id: id,
      name: (map['name'] as String?) ?? 'Untitled Habit',
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == map['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      createdAt: createdAt,
      categoryId: map['categoryId'] as String?,
      intervalDays: map['intervalDays'] as int?,
      anchor: map['anchor'] as int?,
      archived: (map['archived'] as bool?) ?? false,
      startDate: map['startDate'] as String?,
      scheduleUpdatedAt: map['scheduleUpdatedAt'] as String?,
    );
  }
}
