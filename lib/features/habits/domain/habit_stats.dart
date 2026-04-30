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

class HabitRollingRatePoint {
  const HabitRollingRatePoint({required this.date, required this.rate});

  final DateTime date;
  final double rate;
}

class HabitWeekdayPerformancePoint {
  const HabitWeekdayPerformancePoint({
    required this.weekday,
    required this.due,
    required this.completed,
  });

  final int weekday;
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
    required this.activeHabits,
    required this.weekRate,
    required this.previousWeekRate,
    required this.monthRate,
    required this.last30Due,
    required this.last30Completed,
    required this.consistencyScore,
    required this.bestWeekday,
    required this.bestWeekdayRate,
    required this.momentum,
    required this.bestStreak,
    required this.last14Days,
    required this.last7Days,
    required this.rolling7DayRate,
    required this.weekdayPerformance,
  });

  final int todayTotal;
  final int todayCompleted;
  final int activeHabits;
  final double weekRate;
  final double previousWeekRate;
  final double monthRate;
  final int last30Due;
  final int last30Completed;
  final double consistencyScore;
  final int bestWeekday;
  final double bestWeekdayRate;
  final double momentum;
  final int bestStreak;
  final List<HabitTrendPoint> last14Days;
  final List<HabitTrendPoint> last7Days;
  final List<HabitRollingRatePoint> rolling7DayRate;
  final List<HabitWeekdayPerformancePoint> weekdayPerformance;

  double get todayRate {
    if (todayTotal == 0) {
      return 0;
    }
    return todayCompleted / todayTotal;
  }
}
