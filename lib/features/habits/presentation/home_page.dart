import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../bootstrap.dart';
import '../../../core/date_helpers.dart';
import '../../auth/application/auth_controller.dart';
import '../application/habits_controller.dart';
import '../domain/habit.dart';
import '../domain/habit_detail_stats.dart';
import '../domain/habit_stats.dart';

class HabitsHomePage extends ConsumerStatefulWidget {
  const HabitsHomePage({super.key});

  @override
  ConsumerState<HabitsHomePage> createState() => _HabitsHomePageState();
}

class _HabitsHomePageState extends ConsumerState<HabitsHomePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final firebaseEnabled = ref.watch(firebaseEnabledProvider);
    final authBootstrap = ref.watch(ensureSignedInProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitz'),
        actions: [
          if (firebaseEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Chip(
                avatar: const Icon(Icons.cloud_done, size: 18),
                label: Text(_authLabel(user)),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Chip(
                avatar: Icon(Icons.cloud_off, size: 18),
                label: Text('Local mode'),
              ),
            ),
          IconButton(
            tooltip: 'Archived habits',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _openArchivedHabits(context),
          ),
          if (firebaseEnabled)
            PopupMenuButton<String>(
              tooltip: 'Account',
              onSelected: (value) async {
                if (value == 'google') {
                  await ref.read(authActionsProvider).signInWithGoogle();
                }
                if (value == 'signOut') {
                  await ref.read(authActionsProvider).signOutToAnonymous();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'google',
                  child: Text('Sign in with Google'),
                ),
                PopupMenuItem(
                  value: 'signOut',
                  child: Text('Sign out to guest'),
                ),
              ],
            ),
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state = normalizeDate(
                DateTime.now(),
              );
            },
          ),
        ],
      ),
      body: authBootstrap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Authentication error: $error')),
        data: (_) => IndexedStack(
          index: _selectedTab,
          children: const [_TrackTab(), _StatsTab()],
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateHabitSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('New Habit'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateHabitSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreateHabitSheet(),
    );
  }

  Future<void> _openArchivedHabits(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ArchivedHabitsPage()));
  }

  String _authLabel(dynamic user) {
    if (user == null) {
      return 'No user';
    }

    if (user.isAnonymous == true) {
      return 'Guest';
    }

    final uid = user.uid as String?;
    if (uid == null || uid.isEmpty) {
      return 'Signed in';
    }

    final short = min(6, uid.length);
    return 'User ${uid.substring(0, short)}';
  }
}

class _TrackTab extends ConsumerWidget {
  const _TrackTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final dueHabitsValue = ref.watch(dueHabitsForSelectedDateProvider);
    final completedValue = ref.watch(completionSetForSelectedDateProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          _DateHeader(date: date),
          const SizedBox(height: 12),
          Expanded(
            child: dueHabitsValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Could not load habits: $error')),
              data: (habits) => completedValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Could not load completions: $error')),
                data: (completedIds) {
                  if (habits.isEmpty) {
                    return const Center(
                      child: Text(
                        'No habits for this date yet.\nTap New Habit to add one.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: habits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final isDone = completedIds.contains(habit.id);
                      return _HabitTile(
                        habit: habit,
                        isDone: isDone,
                        onChanged: (value) {
                          ref
                              .read(habitActionsProvider)
                              .setCompleted(
                                habitId: habit.id,
                                date: date,
                                isDone: value,
                              );
                        },
                        onDetails: () => _openDetails(context, habit),
                        onEdit: () => _openEditHabitSheet(context, habit),
                        onArchive: () async {
                          await ref
                              .read(habitActionsProvider)
                              .archiveHabit(habit.id);
                        },
                        onDelete: () async {
                          final shouldDelete =
                              await _confirmDeleteHabit(context, habit.name) ??
                              false;
                          if (!shouldDelete) {
                            return;
                          }
                          await ref
                              .read(habitActionsProvider)
                              .deleteHabit(habit.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditHabitSheet(BuildContext context, Habit habit) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateHabitSheet(initialHabit: habit),
    );
  }

  Future<void> _openDetails(BuildContext context, Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitDetailsPage(habitId: habit.id, title: habit.name),
      ),
    );
  }

  Future<bool?> _confirmDeleteHabit(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Delete "$name" and all of its completion history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ArchivedHabitsPage extends ConsumerWidget {
  const ArchivedHabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedValue = ref.watch(archivedHabitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Archived Habits')),
      body: archivedValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load archived: $error')),
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text('No archived habits yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Card(
                child: ListTile(
                  title: Text(habit.name),
                  subtitle: Text(_frequencySubtitle(habit)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => HabitDetailsPage(
                          habitId: habit.id,
                          title: habit.name,
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'restore') {
                        ref.read(habitActionsProvider).unarchiveHabit(habit.id);
                      }
                      if (value == 'delete') {
                        _confirmDeleteHabit(context, habit.name).then((result) {
                          if (result != true) {
                            return;
                          }
                          ref.read(habitActionsProvider).deleteHabit(habit.id);
                        });
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'restore', child: Text('Restore')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _frequencySubtitle(Habit habit) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.interval:
        return 'Every ${habit.intervalDays ?? 1} days';
    }
  }

  Future<bool?> _confirmDeleteHabit(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Delete "$name" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class HabitDetailsPage extends ConsumerWidget {
  const HabitDetailsPage({
    super.key,
    required this.habitId,
    required this.title,
  });

  final String habitId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailValue = ref.watch(habitDetailStatsProvider(habitId));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: detailValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load details: $error')),
          data: (stats) => ListView(
            children: [
              _StatCard(
                title: 'Current Streak',
                value: '${stats.currentStreak} check-ins',
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Best Streak (30-day window)',
                value: '${stats.bestStreak} check-ins',
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Last 30 Days Adherence',
                value:
                    '${stats.last30Completed}/${stats.last30Due} (${(stats.last30Rate * 100).toStringAsFixed(1)}%)',
              ),
              const SizedBox(height: 18),
              Text(
                'Streak History (30 days)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _HabitStreakChart(points: stats.streakHistory),
              const SizedBox(height: 18),
              Text(
                'Missed-day Heatmap (12 weeks)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _HabitHeatmap(cells: stats.heatmap),
              const SizedBox(height: 18),
              Text(
                'Frequency Adherence (Weekly)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _WeeklyAdherenceChart(points: stats.weeklyAdherence),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitStreakChart extends StatelessWidget {
  const _HabitStreakChart({required this.points});

  final List<HabitStreakPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points.fold<int>(0, (prev, item) => max(prev, item.streak));
    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: max(1, maxY).toDouble(),
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
                    reservedSize: 28,
                    interval: 1,
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
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  spots: List.generate(
                    points.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      points[index].streak.toDouble(),
                    ),
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

class _HabitHeatmap extends StatelessWidget {
  const _HabitHeatmap({required this.cells});

  final List<HabitHeatmapCell> cells;

  @override
  Widget build(BuildContext context) {
    Color colorFor(HabitHeatmapStatus status) {
      switch (status) {
        case HabitHeatmapStatus.completed:
          return const Color(0xFF2FA36B);
        case HabitHeatmapStatus.missed:
          return const Color(0xFFDB5A42);
        case HabitHeatmapStatus.notScheduled:
          return const Color(0xFFD7DFE7);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: cells
                  .map(
                    (cell) => Tooltip(
                      message:
                          '${DateFormat('EEE, d MMM').format(cell.date)}: ${cell.status.name}',
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorFor(cell.status),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                _LegendDot(color: Color(0xFF2FA36B), label: 'Completed'),
                SizedBox(width: 10),
                _LegendDot(color: Color(0xFFDB5A42), label: 'Missed'),
                SizedBox(width: 10),
                _LegendDot(color: Color(0xFFD7DFE7), label: 'Not scheduled'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _WeeklyAdherenceChart extends StatelessWidget {
  const _WeeklyAdherenceChart({required this.points});

  final List<HabitWeeklyAdherencePoint> points;

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
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        DateFormat('MMM d').format(points[idx].weekStart),
                        style: const TextStyle(fontSize: 10),
                      );
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
                      width: 16,
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: points[index].due.toDouble(),
                        color: Theme.of(context).colorScheme.primaryContainer,
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

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsValue = ref.watch(habitStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: statsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load stats: $error')),
        data: (stats) {
          final theme = Theme.of(context);
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
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Last 30 Days',
                value:
                    '${(stats.monthRate * 100).toStringAsFixed(1)}% completion rate',
              ),
              const SizedBox(height: 10),
              _StatCard(
                title: 'Best Active Streak',
                value: '${stats.bestStreak} check-ins in a row',
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
              const SizedBox(height: 20),
              const Text('Rates count only days where a habit was scheduled.'),
            ],
          );
        },
      ),
    );
  }
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

class _DateHeader extends ConsumerWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = DateFormat('EEE, d MMM yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                ref.read(selectedDateProvider.notifier).state = normalizeDate(
                  date.subtract(const Duration(days: 1)),
                );
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  format.format(date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(selectedDateProvider.notifier).state = normalizeDate(
                  date.add(const Duration(days: 1)),
                );
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.isDone,
    required this.onChanged,
    required this.onDetails,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final Habit habit;
  final bool isDone;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: isDone,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(habit.name),
        subtitle: Text(_frequencySubtitle(habit)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        secondary: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'details':
                onDetails();
                break;
              case 'edit':
                onEdit();
                break;
              case 'archive':
                onArchive();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'details', child: Text('Details')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'archive', child: Text('Archive')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  String _frequencySubtitle(Habit habit) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly on ${_weekdayLabel(habit.anchor ?? 1)}';
      case HabitFrequency.monthly:
        return 'Monthly on day ${habit.anchor ?? 1}';
      case HabitFrequency.interval:
        return 'Every ${habit.intervalDays ?? 1} days';
    }
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final index = (weekday - 1).clamp(0, 6);
    return labels[index];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(value)),
    );
  }
}

class _CreateHabitSheet extends ConsumerStatefulWidget {
  const _CreateHabitSheet({this.initialHabit});

  final Habit? initialHabit;

  @override
  ConsumerState<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<_CreateHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  HabitFrequency _frequency = HabitFrequency.daily;
  int _intervalDays = 2;
  int _weekday = DateTime.now().weekday;
  int _monthDay = DateTime.now().day;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHabit;
    if (initial == null) {
      return;
    }

    _nameController.text = initial.name;
    _frequency = initial.frequency;
    _intervalDays = initial.intervalDays ?? _intervalDays;
    if (initial.frequency == HabitFrequency.weekly) {
      _weekday = initial.anchor ?? _weekday;
    }
    if (initial.frequency == HabitFrequency.monthly) {
      _monthDay = initial.anchor ?? _monthDay;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isEditing = widget.initialHabit != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: media.viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Habit' : 'Create Habit',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HabitFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: HabitFrequency.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _frequency = value;
                    });
                  }
                },
              ),
              if (_frequency == HabitFrequency.interval) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '$_intervalDays',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Every n days',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      _intervalDays = parsed;
                    }
                  },
                ),
              ],
              if (_frequency == HabitFrequency.weekly) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _weekday,
                  decoration: const InputDecoration(
                    labelText: 'Weekday',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    7,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(_weekdayLong(index + 1)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _weekday = value;
                      });
                    }
                  },
                ),
              ],
              if (_frequency == HabitFrequency.monthly) ...[
                const SizedBox(height: 12),
                Text('Day of month: $_monthDay'),
                Slider(
                  min: 1,
                  max: 31,
                  divisions: 30,
                  label: '$_monthDay',
                  value: _monthDay.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _monthDay = value.round();
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'Save Changes' : 'Save Habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    int? anchor;
    int? intervalDays;

    switch (_frequency) {
      case HabitFrequency.daily:
        break;
      case HabitFrequency.weekly:
        anchor = _weekday;
        break;
      case HabitFrequency.monthly:
        anchor = _monthDay;
        break;
      case HabitFrequency.interval:
        intervalDays = _intervalDays;
        break;
    }

    final initial = widget.initialHabit;
    if (initial == null) {
      await ref
          .read(habitActionsProvider)
          .createHabit(
            name: _nameController.text.trim(),
            frequency: _frequency,
            intervalDays: intervalDays,
            anchor: anchor,
          );
    } else {
      await ref
          .read(habitActionsProvider)
          .editHabit(
            habit: initial,
            name: _nameController.text.trim(),
            frequency: _frequency,
            intervalDays: intervalDays,
            anchor: anchor,
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _weekdayLong(int weekday) {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final index = (weekday - 1).clamp(0, 6);
    return labels[index];
  }
}
