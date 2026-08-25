import 'dart:math';

import '../../../../core/date_helpers.dart';
import '../entity/habit.dart';
import '../entity/habit_completion.dart';
import '../entity/habit_detail_stats.dart';
import '../entity/habit_stats.dart';

class HabitStatsService {
  static HabitDetailStats buildHabitDetailStats(
    Habit habit,
    List<HabitCompletion> completions,
  ) {
    final today = normalizeDate(DateTime.now());
    final completedKeys = completions
        .where((completion) => completion.habitId == habit.id)
        .where((completion) => completion.isCompleted)
        .map((completion) => dateKey(completion.date))
        .toSet();

    var currentStreak = 0;
    for (var i = 0; i < 365; i++) {
      final day = today.subtract(Duration(days: i));
      if (!habit.isScheduledOn(day)) {
        continue;
      }

      final done = completedKeys.contains(dateKey(day));
      if (!done) {
        break;
      }
      currentStreak++;
    }

    var rolling = 0;
    var best = 0;
    final streakHistory = <HabitStreakPoint>[];
    for (var i = 29; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      if (habit.isScheduledOn(day) && completedKeys.contains(dateKey(day))) {
        rolling++;
      } else if (habit.isScheduledOn(day)) {
        rolling = 0;
      }

      if (rolling > best) {
        best = rolling;
      }
      streakHistory.add(HabitStreakPoint(date: day, streak: rolling));
    }

    var due30 = 0;
    var completed30 = 0;
    for (var i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      if (!habit.isScheduledOn(day)) {
        continue;
      }
      due30++;
      if (completedKeys.contains(dateKey(day))) {
        completed30++;
      }
    }

    final earliestCompletionDate = completions
        .where((completion) => completion.habitId == habit.id)
        .map((completion) => completion.date)
        .fold<DateTime?>(null, (min, d) => min == null || d.isBefore(min) ? d : min);

    final baseDate = earliestCompletionDate != null && earliestCompletionDate.isBefore(habit.createdAt)
        ? earliestCompletionDate
        : habit.createdAt;

    var daysBack = today.difference(normalizeDate(baseDate)).inDays + 30;
    if (daysBack < 365) {
      daysBack = 365;
    }

    final heatmap = <HabitHeatmapCell>[];
    for (var i = daysBack; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      HabitHeatmapStatus status;
      if (!habit.isScheduledOn(day)) {
        status = HabitHeatmapStatus.notScheduled;
      } else if (completedKeys.contains(dateKey(day))) {
        status = HabitHeatmapStatus.completed;
      } else {
        status = HabitHeatmapStatus.missed;
      }
      heatmap.add(HabitHeatmapCell(date: day, status: status));
    }

    final weekly = <HabitWeeklyAdherencePoint>[];
    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    for (var i = 7; i >= 0; i--) {
      final weekStart = startOfThisWeek.subtract(Duration(days: i * 7));
      var due = 0;
      var completed = 0;
      for (var d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (!habit.isScheduledOn(day)) {
          continue;
        }
        due++;
        if (completedKeys.contains(dateKey(day))) {
          completed++;
        }
      }
      weekly.add(
        HabitWeeklyAdherencePoint(
          weekStart: weekStart,
          due: due,
          completed: completed,
        ),
      );
    }

    final recentNotes =
        completions
            .where((completion) => completion.habitId == habit.id)
            .where((completion) => (completion.note ?? '').trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return HabitDetailStats(
      habit: habit,
      currentStreak: currentStreak,
      bestStreak: best,
      last30Due: due30,
      last30Completed: completed30,
      streakHistory: streakHistory,
      heatmap: heatmap,
      weeklyAdherence: weekly,
      recentNotes: recentNotes
          .map(
            (completion) => HabitCompletionNoteItem(
              date: completion.date,
              note: (completion.note ?? '').trim(),
            ),
          )
          .take(20)
          .toList(),
    );
  }

  static HabitStats buildStats(
    List<Habit> habits,
    List<HabitCompletion> completions,
  ) {
    final today = normalizeDate(DateTime.now());
    final completionIndex = <String, Set<String>>{};

    for (final completion in completions) {
      if (!completion.isCompleted) continue;
      final key = dateKey(completion.date);
      final set = completionIndex.putIfAbsent(key, () => <String>{});
      set.add(completion.habitId);
    }

    int countDue(DateTime date) {
      return habits.where((habit) => habit.isScheduledOn(date)).length;
    }

    int countDone(DateTime date) {
      final key = dateKey(date);
      final set = completionIndex[key] ?? <String>{};
      return habits
          .where((habit) => habit.isScheduledOn(date) && set.contains(habit.id))
          .length;
    }

    ({int due, int done}) rangeTotals(int startOffsetDays, int days) {
      var totalDue = 0;
      var totalDone = 0;
      for (var i = startOffsetDays; i < startOffsetDays + days; i++) {
        final day = today.subtract(Duration(days: i));
        totalDue += countDue(day);
        totalDone += countDone(day);
      }
      return (due: totalDue, done: totalDone);
    }

    double rateFromTotals(({int due, int done}) totals) {
      if (totals.due == 0) {
        return 0;
      }
      return totals.done / totals.due;
    }

    int currentStreakForHabit(Habit habit) {
      var streak = 0;
      for (var i = 0; i < 365; i++) {
        final day = today.subtract(Duration(days: i));
        if (!habit.isScheduledOn(day)) {
          continue;
        }

        final done = completionIndex[dateKey(day)]?.contains(habit.id) ?? false;
        if (!done) {
          break;
        }
        streak++;
      }
      return streak;
    }

    var best = 0;
    for (final habit in habits) {
      best = max(best, currentStreakForHabit(habit));
    }

    final weekTotals = rangeTotals(0, 7);
    final previousWeekTotals = rangeTotals(7, 7);
    final monthTotals = rangeTotals(0, 30);

    final weekdayDue = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
    final weekdayDone = <int, int>{for (var i = 1; i <= 7; i++) i: 0};

    for (var i = 0; i < 56; i++) {
      final day = today.subtract(Duration(days: i));
      final weekday = day.weekday;
      weekdayDue[weekday] = (weekdayDue[weekday] ?? 0) + countDue(day);
      weekdayDone[weekday] = (weekdayDone[weekday] ?? 0) + countDone(day);
    }

    var bestWeekday = today.weekday;
    var bestWeekdayRate = 0.0;
    for (var weekday = 1; weekday <= 7; weekday++) {
      final due = weekdayDue[weekday] ?? 0;
      final done = weekdayDone[weekday] ?? 0;
      if (due == 0) {
        continue;
      }
      final rate = done / due;
      if (rate > bestWeekdayRate) {
        bestWeekdayRate = rate;
        bestWeekday = weekday;
      }
    }

    final weekRate = rateFromTotals(weekTotals);
    final previousWeekRate = rateFromTotals(previousWeekTotals);
    final monthRate = rateFromTotals(monthTotals);
    final consistencyScore = ((weekRate * 0.6) + (monthRate * 0.4))
        .clamp(0, 1)
        .toDouble();

    final rolling7DayRate = <HabitRollingRatePoint>[];
    for (var i = 29; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final totals = rangeTotals(i, 7);
      rolling7DayRate.add(
        HabitRollingRatePoint(date: day, rate: rateFromTotals(totals)),
      );
    }

    final weekdayPerformance = List.generate(
      7,
      (index) => HabitWeekdayPerformancePoint(
        weekday: index + 1,
        due: weekdayDue[index + 1] ?? 0,
        completed: weekdayDone[index + 1] ?? 0,
      ),
    );

    return HabitStats(
      todayTotal: countDue(today),
      todayCompleted: countDone(today),
      activeHabits: habits.length,
      weekRate: weekRate,
      previousWeekRate: previousWeekRate,
      monthRate: monthRate,
      last30Due: monthTotals.due,
      last30Completed: monthTotals.done,
      consistencyScore: consistencyScore,
      bestWeekday: bestWeekday,
      bestWeekdayRate: bestWeekdayRate,
      momentum: weekRate - previousWeekRate,
      bestStreak: best,
      last14Days: buildTrend(14, today, countDue, countDone),
      last7Days: buildTrend(7, today, countDue, countDone),
      rolling7DayRate: rolling7DayRate,
      weekdayPerformance: weekdayPerformance,
    );
  }

  static List<HabitTrendPoint> buildTrend(
    int days,
    DateTime today,
    int Function(DateTime) countDue,
    int Function(DateTime) countDone,
  ) {
    final points = <HabitTrendPoint>[];
    for (var i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      points.add(
        HabitTrendPoint(
          date: day,
          due: countDue(day),
          completed: countDone(day),
        ),
      );
    }
    return points;
  }
}
