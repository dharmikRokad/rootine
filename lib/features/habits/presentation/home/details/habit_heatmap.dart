part of '../../home_page.dart';

class _HabitHeatmap extends StatelessWidget {
  const _HabitHeatmap({required this.cells});

  final List<HabitHeatmapCell> cells;

  @override
  Widget build(BuildContext context) {
    Color colorFor(HabitHeatmapStatus status) {
      switch (status) {
        case HabitHeatmapStatus.completed:
          return AppColors.heatmapCompleted;
        case HabitHeatmapStatus.missed:
          return AppColors.heatmapMissed;
        case HabitHeatmapStatus.notScheduled:
          return AppColors.heatmapNotScheduled;
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
            Row(
              children: [
                const _LegendDot(
                  color: AppColors.heatmapCompleted,
                  label: AppStrings.completed,
                ),
                const SizedBox(width: 10),
                const _LegendDot(
                  color: AppColors.heatmapMissed,
                  label: AppStrings.missed,
                ),
                const SizedBox(width: 10),
                const _LegendDot(
                  color: AppColors.heatmapNotScheduled,
                  label: AppStrings.notScheduled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
