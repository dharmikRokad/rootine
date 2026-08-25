part of '../home_page.dart';

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedHabitId = ref.watch(selectedAnalyticsHabitIdProvider);
    final habits = ref.watch(habitsProvider).valueOrNull ?? const <Habit>[];
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Analyze:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedHabitId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All Points (Overall)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...habits.map(
                            (h) => DropdownMenuItem<String?>(
                              value: h.id,
                              child: Text(h.name),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          ref
                              .read(selectedAnalyticsHabitIdProvider.notifier)
                              .state = val;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: selectedHabitId == null
                ? _buildOverallView(context, ref)
                : _buildPointView(context, ref, selectedHabitId),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallView(BuildContext context, WidgetRef ref) {
    final statsValue = ref.watch(habitStatsProvider);
    final completionsValue = ref.watch(completionsProvider);

    return statsValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          AppStrings.couldNotLoadMessage(AppStrings.statsNoun, error),
        ),
      ),
      data: (stats) {
        final theme = Theme.of(context);
        final weeklyDelta = stats.weekRate - stats.previousWeekRate;

        final today = normalizeDate(DateTime.now());
        final completions =
            completionsValue.value ?? const <HabitCompletion>[];
        final completedDateSet = completions
            .where((c) => c.isCompleted)
            .map((c) => dateKey(c.date))
            .toSet();

        final earliestDate = completions.isNotEmpty
            ? completions
                .map((c) => c.date)
                .reduce((a, b) => a.isBefore(b) ? a : b)
            : today.subtract(const Duration(days: 365));

        var daysBack =
            today.difference(normalizeDate(earliestDate)).inDays + 30;
        if (daysBack < 365) {
          daysBack = 365;
        }

        final heatmapCells = <HabitHeatmapCell>[];
        for (var i = daysBack; i >= 0; i--) {
          final day = today.subtract(Duration(days: i));
          final key = dateKey(day);
          final hasCompletion = completedDateSet.contains(key);
          heatmapCells.add(
            HabitHeatmapCell(
              date: day,
              status: hasCompletion
                  ? HabitHeatmapStatus.completed
                  : HabitHeatmapStatus.notScheduled,
            ),
          );
        }

        return ListView(
          children: [
            // 4 Horizontal Stat Cards Row matching reference UI
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: Today
                  Expanded(
                    child: _OverviewStatCard(
                      icon: Icons.track_changes,
                      title: 'Today',
                      value: '${(stats.todayRate * 100).toStringAsFixed(0)}%',
                      subtitle:
                          '${stats.todayCompleted}/${stats.todayTotal} completed',
                      progress: stats.todayRate,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Card 2: This Week
                  Expanded(
                    child: _OverviewStatCard(
                      icon: Icons.trending_up,
                      title: 'This Week',
                      value: '${(stats.weekRate * 100).toStringAsFixed(0)}%',
                      subtitle:
                          '${weeklyDelta.rateDeltaLabel}\nvs last week',
                      isDelta: true,
                      isPositiveDelta: weeklyDelta >= 0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Card 3: Best Streak
                  Expanded(
                    child: _OverviewStatCard(
                      icon: Icons.whatshot,
                      title: 'Best Streak',
                      value: '${stats.bestStreak}',
                      subtitle: 'check-ins\nin a row',
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Card 4: Consistency
                  Expanded(
                    child: _OverviewStatCard(
                      icon: Icons.emoji_events,
                      title: 'Consistency',
                      value:
                          '${(stats.consistencyScore * 100).toStringAsFixed(0)}%',
                      subtitle: stats.consistencyScore.consistencyLabel.capitalize(),
                      isBadge: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _HabitHeatmap(cells: heatmapCells),
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
            Text(
              AppStrings.last7DaysOutput,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.last7DaysOutputDesc,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            _CompletionBarChart(points: stats.last7Days),
          ],
        );
      },
    );
  }

  Widget _buildPointView(BuildContext context, WidgetRef ref, String habitId) {
    final detailValue = ref.watch(habitDetailStatsProvider(habitId));
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    return detailValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(AppStrings.couldNotLoadMessage(AppStrings.details, error)),
      ),
      data: (stats) {
        return ListView(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _OverviewStatCard(
                      icon: Icons.whatshot,
                      title: AppStrings.currentStreak,
                      value: '${stats.currentStreak}',
                      subtitle: 'check-in',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OverviewStatCard(
                      icon: Icons.workspace_premium,
                      title: AppStrings.bestStreak,
                      value: '${stats.bestStreak}',
                      subtitle: 'check-in',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OverviewStatCard(
                      icon: Icons.track_changes,
                      title: 'Last 30 Days\nAdherence',
                      value:
                          '${(stats.last30Rate * 100).toStringAsFixed(0)}%',
                      subtitle:
                          '${stats.last30Completed} / ${stats.last30Due} days',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _HabitHeatmap(cells: stats.heatmap),
            const SizedBox(height: 18),
            Text(
              'Reflection Notes Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (stats.recentNotes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child:
                      Text('No reflection notes recorded for this point yet.'),
                ),
              )
            else
              ...stats.recentNotes.map(
                (noteItem) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.rate_review_outlined),
                    title: Text(noteItem.note),
                    subtitle: Text(
                      dateFormat.format(noteItem.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.progress,
    this.isDelta = false,
    this.isPositiveDelta = true,
    this.isBadge = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final double? progress;
  final bool isDelta;
  final bool isPositiveDelta;
  final bool isBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: isBadge
                      ? Colors.amber.withValues(alpha: 0.15)
                      : isDelta
                          ? Colors.lightBlue.withValues(alpha: 0.15)
                          : theme.colorScheme.primaryContainer,
                  child: Icon(
                    icon,
                    size: 18,
                    color: isBadge
                        ? Colors.amber
                        : isDelta
                            ? Colors.lightBlue
                            : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                if (isBadge)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.verified,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  )
                else
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: isDelta
                          ? (isPositiveDelta
                              ? (isDark
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF2E7D32))
                              : (isDark
                                  ? const Color(0xFFEF5350)
                                  : const Color(0xFFC62828)))
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isDelta ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0, 1),
                      minHeight: 3,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
