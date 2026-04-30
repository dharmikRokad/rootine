import 'habit.dart';

enum HabitHeatmapStatus { completed, missed, notScheduled }

class HabitHeatmapCell {
  const HabitHeatmapCell({required this.date, required this.status});

  final DateTime date;
  final HabitHeatmapStatus status;
}

class HabitStreakPoint {
  const HabitStreakPoint({required this.date, required this.streak});

  final DateTime date;
  final int streak;
}

class HabitWeeklyAdherencePoint {
  const HabitWeeklyAdherencePoint({
    required this.weekStart,
    required this.due,
    required this.completed,
  });

  final DateTime weekStart;
  final int due;
  final int completed;

  double get rate {
    if (due == 0) {
      return 0;
    }
    return completed / due;
  }
}

class HabitDetailStats {
  const HabitDetailStats({
    required this.habit,
    required this.currentStreak,
    required this.bestStreak,
    required this.last30Due,
    required this.last30Completed,
    required this.streakHistory,
    required this.heatmap,
    required this.weeklyAdherence,
    required this.recentNotes,
  });

  final Habit habit;
  final int currentStreak;
  final int bestStreak;
  final int last30Due;
  final int last30Completed;
  final List<HabitStreakPoint> streakHistory;
  final List<HabitHeatmapCell> heatmap;
  final List<HabitWeeklyAdherencePoint> weeklyAdherence;
  final List<HabitCompletionNoteItem> recentNotes;

  double get last30Rate {
    if (last30Due == 0) {
      return 0;
    }
    return last30Completed / last30Due;
  }
}

class HabitCompletionNoteItem {
  const HabitCompletionNoteItem({required this.date, required this.note});

  final DateTime date;
  final String note;
}
