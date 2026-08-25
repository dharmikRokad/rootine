part of '../home_page.dart';

class _DaySwitcher extends StatelessWidget {
  const _DaySwitcher({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onPickDate,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onPickDate;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('EEE, d MMM');

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: AppStrings.previousDay,
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: onPrevious,
            ),
            Tooltip(
              message: 'Tap for calendar • Double-tap for Today',
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    onPickDate(picked);
                  }
                },
                onDoubleTap: onToday,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    format.format(date),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: AppStrings.nextDay,
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
