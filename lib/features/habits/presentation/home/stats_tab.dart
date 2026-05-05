part of '../home_page.dart';

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsValue = ref.watch(habitStatsProvider);
    final achievementsValue = ref.watch(overallAchievementsProvider);
    ref.watch(syncOverallAchievementUnlocksProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: statsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(AppStrings.couldNotLoadMessage(AppStrings.statsNoun, error)),
        ),
        data: (stats) {
          final theme = Theme.of(context);
          final weeklyDelta = stats.weekRate - stats.previousWeekRate;
          return ListView(
            children: [
              _StatCard(
                title: AppStrings.today,
                value: AppStrings.todayCompletedLabel(
                  stats.todayCompleted,
                  stats.todayTotal,
                  (stats.todayRate * 100).toStringAsFixed(0),
                ),
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: AppStrings.last7Days,
                value: AppStrings.completionRateLabel(
                  (stats.weekRate * 100).toStringAsFixed(1),
                ),
                subtitle: AppStrings.vsPreviousWeekLabel(
                  weeklyDelta.rateDeltaLabel,
                  (stats.previousWeekRate * 100).toStringAsFixed(1),
                ),
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: AppStrings.last30Days,
                value: AppStrings.completionRateLabel(
                  (stats.monthRate * 100).toStringAsFixed(1),
                ),
                subtitle: AppStrings.scheduledCheckInsLabel(
                  stats.last30Completed,
                  stats.last30Due,
                ),
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: AppStrings.consistencyScore,
                value:
                    '${(stats.consistencyScore * 100).toStringAsFixed(0)}% (${stats.consistencyScore.consistencyLabel})',
                subtitle: AppStrings.activeHabitsLabel(stats.activeHabits),
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: AppStrings.bestDayOfWeek,
                value:
                    '${stats.bestWeekday.weekdayName} ${AppStrings.at} ${(stats.bestWeekdayRate * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: AppStrings.momentum,
                value: '${stats.momentum.rateDeltaLabel} ${AppStrings.vsPreviousWeek}',
                subtitle: stats.momentum.momentumMessage,
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: AppStrings.bestActiveStreak,
                value: AppStrings.bestStreakInARowLabel(stats.bestStreak),
              ),
              const SizedBox(height: 18),
              _AchievementsSection(
                scope: 'overall',
                title: AppStrings.milestones,
                value: achievementsValue,
              ),
              const SizedBox(height: 18),
              Text(
                AppStrings.completionTrend14Days,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.completionTrend14DaysDesc,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              _CompletionLineChart(points: stats.last14Days),
              const SizedBox(height: 18),
              Text(AppStrings.last7DaysOutput, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                AppStrings.last7DaysOutputDesc,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              _CompletionBarChart(points: stats.last7Days),
              const SizedBox(height: 18),
              Text(
                AppStrings.rolling7DayAdherence,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.rolling7DayAdherenceDesc,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              _RollingRateChart(points: stats.rolling7DayRate),
              const SizedBox(height: 18),
              Text(AppStrings.weekdayWinRate, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                AppStrings.weekdayWinRateDesc,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              _WeekdayPerformanceChart(points: stats.weekdayPerformance),
              const SizedBox(height: 20),
              const Text(AppStrings.ratesCountOnlyScheduledDays),
            ],
          );
        },
      ),
    );
  }
}
