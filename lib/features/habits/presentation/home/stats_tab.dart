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
        error: (error, _) =>
            Center(child: Text('Could not load stats: $error')),
        data: (stats) {
          final theme = Theme.of(context);
          final weeklyDelta = stats.weekRate - stats.previousWeekRate;
          return ListView(
            children: [
              _StatCard(
                title: 'Today',
                value:
                    '${stats.todayCompleted}/${stats.todayTotal} completed (${(stats.todayRate * 100).toStringAsFixed(0)}%)',
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Last 7 Days',
                value:
                    '${(stats.weekRate * 100).toStringAsFixed(1)}% completion rate',
                subtitle:
                    '${_rateDeltaLabel(weeklyDelta)} vs previous week (${(stats.previousWeekRate * 100).toStringAsFixed(1)}%)',
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Last 30 Days',
                value:
                    '${(stats.monthRate * 100).toStringAsFixed(1)}% completion rate',
                subtitle:
                    '${stats.last30Completed}/${stats.last30Due} scheduled check-ins completed',
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Consistency Score',
                value:
                    '${(stats.consistencyScore * 100).toStringAsFixed(0)}% (${_consistencyLabel(stats.consistencyScore)})',
                subtitle: '${stats.activeHabits} active habits tracked',
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Best Day of Week',
                value:
                    '${_weekdayName(stats.bestWeekday)} at ${(stats.bestWeekdayRate * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Momentum',
                value: '${_rateDeltaLabel(stats.momentum)} vs last week',
                subtitle: _momentumMessage(stats.momentum),
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Best Active Streak',
                value: '${stats.bestStreak} check-ins in a row',
              ),
              const SizedBox(height: 18),
              _AchievementsSection(
                scope: 'overall',
                title: 'Milestones',
                value: achievementsValue,
              ),
              const SizedBox(height: 18),
              Text(
                '14-Day Completion Trend',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _CompletionLineChart(points: stats.last14Days),
              const SizedBox(height: 18),
              Text('Last 7 Days Output', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              _CompletionBarChart(points: stats.last7Days),
              const SizedBox(height: 18),
              Text(
                'Rolling 7-Day Adherence',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _RollingRateChart(points: stats.rolling7DayRate),
              const SizedBox(height: 18),
              Text('Weekday Win Rate', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              _WeekdayPerformanceChart(points: stats.weekdayPerformance),
              const SizedBox(height: 20),
              const Text('Rates count only days where a habit was scheduled.'),
            ],
          );
        },
      ),
    );
  }
}

String _rateDeltaLabel(double delta) {
  final absDelta = (delta.abs() * 100).toStringAsFixed(1);
  if (delta > 0.001) {
    return '+$absDelta pts';
  }
  if (delta < -0.001) {
    return '-$absDelta pts';
  }
  return '0.0 pts';
}

String _consistencyLabel(double score) {
  if (score >= 0.85) {
    return 'excellent';
  }
  if (score >= 0.7) {
    return 'strong';
  }
  if (score >= 0.5) {
    return 'improving';
  }
  return 'building momentum';
}

String _momentumMessage(double momentum) {
  if (momentum > 0.08) {
    return 'Strong upward trend';
  }
  if (momentum > 0.02) {
    return 'Improving steadily';
  }
  if (momentum < -0.08) {
    return 'Recent dip, adjust schedule';
  }
  if (momentum < -0.02) {
    return 'Slightly down this week';
  }
  return 'Stable compared to last week';
}

String _weekdayName(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final index = (weekday - 1).clamp(0, 6);
  return names[index];
}

class _CompletionLineChart extends StatelessWidget {
  const _CompletionLineChart({required this.points});

  final List<HabitTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 1,
              gridData: const FlGridData(show: true),
              lineTouchData: LineTouchData(enabled: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 0.25,
                    getTitlesWidget: (value, meta) {
                      return Text('${(value * 100).round()}%');
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 3,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(DateFormat('d MMM').format(points[idx].date));
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  spots: List.generate(
                    points.length,
                    (index) => FlSpot(index.toDouble(), points[index].rate),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionBarChart extends StatelessWidget {
  const _CompletionBarChart({required this.points});

  final List<HabitTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxDue = points.fold<int>(0, (prev, item) => max(prev, item.due));
    final maxY = max(1, maxDue).toDouble();

    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Text(value.toInt().toString());
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(DateFormat('E').format(points[idx].date));
                    },
                  ),
                ),
              ),
              barGroups: List.generate(
                points.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: points[index].completed.toDouble(),
                      width: 18,
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: points[index].due.toDouble(),
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RollingRateChart extends StatelessWidget {
  const _RollingRateChart({required this.points});

  final List<HabitRollingRatePoint> points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 1,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(enabled: true),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 0.25,
                    getTitlesWidget: (value, meta) {
                      return Text('${(value * 100).round()}%');
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 7,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(DateFormat('d MMM').format(points[idx].date));
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  barWidth: 3,
                  color: Theme.of(context).colorScheme.secondary,
                  dotData: const FlDotData(show: false),
                  spots: List.generate(
                    points.length,
                    (index) => FlSpot(index.toDouble(), points[index].rate),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayPerformanceChart extends StatelessWidget {
  const _WeekdayPerformanceChart({required this.points});

  final List<HabitWeekdayPerformancePoint> points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: 1,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 0.25,
                    getTitlesWidget: (value, meta) {
                      return Text('${(value * 100).round()}%');
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(_weekdayName(points[idx].weekday));
                    },
                  ),
                ),
              ),
              barGroups: List.generate(
                points.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: points[index].rate,
                      width: 16,
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, this.subtitle});

  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _AchievementsSection extends ConsumerStatefulWidget {
  const _AchievementsSection({
    required this.scope,
    required this.title,
    required this.value,
  });

  final String scope;
  final String title;
  final AsyncValue<List<HabitAchievement>> value;

  @override
  ConsumerState<_AchievementsSection> createState() =>
      _AchievementsSectionState();
}

class _AchievementsSectionState extends ConsumerState<_AchievementsSection> {
  String _lastMarkedKey = '';

  @override
  Widget build(BuildContext context) {
    final achievements = widget.value.value ?? const <HabitAchievement>[];
    final newlyUnlockedIds =
        achievements.where((a) => a.isNewlyUnlocked).map((a) => a.id).toList();
    final nextKey = newlyUnlockedIds.join('|');

    if (newlyUnlockedIds.isNotEmpty && nextKey != _lastMarkedKey) {
      _lastMarkedKey = nextKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref
            .read(habitActionsProvider)
            .markAchievementsCelebrated(widget.scope, newlyUnlockedIds);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        widget.value.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text('Could not load achievements: $error'),
            ),
          ),
          data: (achievements) {
            final unlocked = achievements.where((a) => a.unlocked).length;
            final newlyUnlocked =
                achievements.where((a) => a.isNewlyUnlocked).length;

            return Column(
              children: [
                if (newlyUnlocked > 0) ...[
                  _CelebrationBanner(
                    text:
                        '$newlyUnlocked new achievement${newlyUnlocked == 1 ? '' : 's'} unlocked',
                  ),
                  const SizedBox(height: 10),
                ],
                if (unlocked > 0 && newlyUnlocked == 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$unlocked achievement${unlocked == 1 ? '' : 's'} unlocked',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (unlocked > 0 && newlyUnlocked == 0)
                  const SizedBox(height: 8),
                ...achievements.map(
                  (achievement) => Card(
                    child: ListTile(
                      leading: Icon(
                        achievement.unlocked
                            ? Icons.workspace_premium
                            : Icons.radio_button_unchecked,
                        color: achievement.unlocked
                            ? const Color(0xFFF2994A)
                            : Theme.of(context).colorScheme.outline,
                      ),
                      title: Text(achievement.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(achievement.description),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: achievement.progress,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.targetLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CelebrationBanner extends StatelessWidget {
  const _CelebrationBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.celebration_outlined,
              color: colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
