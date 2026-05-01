part of '../../home_page.dart';

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
