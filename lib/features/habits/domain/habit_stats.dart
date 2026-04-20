class HabitTrendPoint {
  const HabitTrendPoint({
    required this.date,
    required this.due,
    required this.completed,
  });

  final DateTime date;
  final int due;
  final int completed;

  double get rate {
    if (due == 0) {
      return 0;
    }
    return completed / due;
  }
}

class HabitStats {
  const HabitStats({
    required this.todayTotal,
    required this.todayCompleted,
    required this.weekRate,
    required this.monthRate,
    required this.bestStreak,
    required this.last14Days,
    required this.last7Days,
  });

  final int todayTotal;
  final int todayCompleted;
  final double weekRate;
  final double monthRate;
  final int bestStreak;
  final List<HabitTrendPoint> last14Days;
  final List<HabitTrendPoint> last7Days;

  double get todayRate {
    if (todayTotal == 0) {
      return 0;
    }
    return todayCompleted / todayTotal;
  }
}
