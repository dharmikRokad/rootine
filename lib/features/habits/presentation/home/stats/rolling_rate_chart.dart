part of '../../home_page.dart';

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
