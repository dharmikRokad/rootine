part of '../../home_page.dart';

class _HabitHeatmap extends StatefulWidget {
  const _HabitHeatmap({required this.cells});

  final List<HabitHeatmapCell> cells;

  @override
  State<_HabitHeatmap> createState() => _HabitHeatmapState();
}

class _HabitHeatmapState extends State<_HabitHeatmap> {
  final ScrollController _scrollController = ScrollController();
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _selectedYear = currentYear;
    _scrollToEnd();
  }

  @override
  void didUpdateWidget(covariant _HabitHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cells.length != widget.cells.length) {
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateCellMap = <String, HabitHeatmapCell>{};
    for (final cell in widget.cells) {
      dateCellMap[dateKey(cell.date)] = cell;
    }

    // Collect available years from data + current year
    final currentYear = DateTime.now().year;
    final availableYearsSet = <int>{currentYear};
    for (final cell in widget.cells) {
      availableYearsSet.add(cell.date.year);
    }
    final availableYears = availableYearsSet.toList()
      ..sort((a, b) => b.compareTo(a));

    if (!availableYears.contains(_selectedYear)) {
      _selectedYear = availableYears.first;
    }

    // Generate full 52-53 weeks for the selected year (Jan 1 to Dec 31)
    final yearStart = DateTime(_selectedYear, 1, 1);
    final yearEnd = DateTime(_selectedYear, 12, 31);

    // Align grid to start on Monday of week 1
    final gridStart = yearStart.subtract(Duration(days: yearStart.weekday - 1));
    final gridEnd = yearEnd.add(Duration(days: 7 - yearEnd.weekday));

    final weekColumns = <List<DateTime>>[];
    var currentDay = gridStart;
    var completedCount = 0;

    while (!currentDay.isAfter(gridEnd)) {
      final week = <DateTime>[];
      for (var i = 0; i < 7; i++) {
        week.add(currentDay);
        if (currentDay.year == _selectedYear) {
          final cell = dateCellMap[dateKey(currentDay)];
          if (cell?.status == HabitHeatmapStatus.completed) {
            completedCount++;
          }
        }
        currentDay = currentDay.add(const Duration(days: 1));
      }
      weekColumns.add(week);
    }

    Color colorFor(HabitHeatmapStatus status) {
      switch (status) {
        case HabitHeatmapStatus.completed:
          return isDark ? const Color(0xFF39D353) : const Color(0xFF2E7D32);
        case HabitHeatmapStatus.missed:
          return isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
        case HabitHeatmapStatus.notScheduled:
          return isDark ? const Color(0xFF161B22) : const Color(0xFFEBEDF0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row (Contributions count + Year selector pills)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$completedCount contributions in $_selectedYear',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: availableYears.map((year) {
                final isSelected = year == _selectedYear;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedYear = year;
                      });
                      _scrollToEnd();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$year',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Commit Matrix Container Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1117) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF30363D)
                  : theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed / Sticky Left Day Labels (Mon, Wed, Fri, Sun) - Outside ScrollView!
                  Padding(
                    padding: const EdgeInsets.only(top: 20, right: 8),
                    child: Column(
                      children: [
                        _dayLabel(theme, 'Mon'),
                        _dayLabel(theme, ''),
                        _dayLabel(theme, 'Wed'),
                        _dayLabel(theme, ''),
                        _dayLabel(theme, 'Fri'),
                        _dayLabel(theme, ''),
                        _dayLabel(theme, 'Sun'),
                      ],
                    ),
                  ),

                  // Horizontally Scrollable Matrix Grid & Month Headers
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Header Row
                          SizedBox(
                            height: 18,
                            child: Row(
                              children: weekColumns.map((week) {
                                final firstDayOfWeek = week.first;
                                final isFirstWeekOfMonth =
                                    firstDayOfWeek.day <= 7;
                                final monthName = isFirstWeekOfMonth
                                    ? DateFormat('MMM').format(firstDayOfWeek)
                                    : '';

                                return SizedBox(
                                  width: 14,
                                  child: isFirstWeekOfMonth
                                      ? OverflowBox(
                                          alignment: Alignment.centerLeft,
                                          minWidth: 0,
                                          maxWidth: 40,
                                          child: Text(
                                            monthName,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        )
                                      : null,
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Matrix Grid Columns
                          Row(
                            children: weekColumns.map((week) {
                              return SizedBox(
                                width: 14,
                                child: Column(
                                  children: week.map((day) {
                                    final cell = dateCellMap[dateKey(day)];
                                    final isCurrentYearDay =
                                        day.year == _selectedYear;
                                    final status = isCurrentYearDay
                                        ? (cell?.status ??
                                            HabitHeatmapStatus.notScheduled)
                                        : HabitHeatmapStatus.notScheduled;

                                    return Tooltip(
                                      message:
                                          '${DateFormat('EEE, d MMM yyyy').format(day)}: ${status.name}',
                                      child: Container(
                                        width: 11,
                                        height: 11,
                                        margin: const EdgeInsets.only(
                                          right: 3,
                                          bottom: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorFor(status),
                                          borderRadius: BorderRadius.circular(
                                            2.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Status Indications Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _LegendIndicator(
                    color: colorFor(HabitHeatmapStatus.completed),
                    label: AppStrings.completed,
                  ),
                  const SizedBox(width: 16),
                  _LegendIndicator(
                    color: colorFor(HabitHeatmapStatus.missed),
                    label: AppStrings.missed,
                  ),
                  const SizedBox(width: 16),
                  _LegendIndicator(
                    color: colorFor(HabitHeatmapStatus.notScheduled),
                    label: AppStrings.notScheduled,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayLabel(ThemeData theme, String label) {
    return Container(
      height: 11,
      margin: const EdgeInsets.only(bottom: 3),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  const _LegendIndicator({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
