part of '../home_page.dart';

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
    final achievementsValue = ref.watch(habitAchievementsProvider(habitId));
    ref.watch(syncHabitAchievementUnlocksProvider(habitId));
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Add completion note',
            icon: const Icon(Icons.note_add_outlined),
            onPressed: () => _openNoteEditor(context, ref),
          ),
        ],
      ),
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
              const SizedBox(height: 18),
              _AchievementsSection(
                scope: 'habit:$habitId',
                title: 'Habit Achievements',
                value: achievementsValue,
              ),
              const SizedBox(height: 18),
              Text(
                'Completion Notes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (stats.recentNotes.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('No notes yet. Tap the note icon to add one.'),
                  ),
                )
              else
                ...stats.recentNotes.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.note),
                      subtitle: Text(dateFormat.format(item.date)),
                      trailing: IconButton(
                        tooltip: 'Edit note',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openNoteEditor(
                          context,
                          ref,
                          initialDate: item.date,
                          initialNote: item.note,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNoteEditor(
    BuildContext context,
    WidgetRef ref, {
    DateTime? initialDate,
    String? initialNote,
  }) async {
    var selectedDate = normalizeDate(initialDate ?? DateTime.now());
    final controller = TextEditingController(text: initialNote ?? '');

    final result = await showModalBottomSheet<_NoteEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final media = MediaQuery.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: media.viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completion Note',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = normalizeDate(picked);
                        });
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: Text(
                      DateFormat('EEE, d MMM yyyy').format(selectedDate),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          _NoteEditResult(
                            date: selectedDate,
                            note: controller.text.trim(),
                          ),
                        );
                      },
                      child: const Text('Save Note'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result == null || result.note.isEmpty) {
      controller.dispose();
      return;
    }

    await ref.read(habitActionsProvider).setCompletionNote(
          habitId: habitId,
          date: result.date,
          note: result.note,
        );
    controller.dispose();
  }
}

class _NoteEditResult {
  const _NoteEditResult({required this.date, required this.note});

  final DateTime date;
  final String note;
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
