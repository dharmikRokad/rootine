import '../../../core/app_strings.dart';
import 'entity/habit.dart';

extension HabitX on Habit {
  String get frequencySubtitle {
    switch (frequency) {
      case HabitFrequency.daily:
        return AppStrings.frequencyLabelDaily;
      case HabitFrequency.weekly:
        final index = (anchor ?? 1) - 1;
        final day = AppStrings.weekdayNamesShort[index.clamp(0, 6)];
        return AppStrings.frequencyLabelWeeklyOn(day);
      case HabitFrequency.monthly:
        return AppStrings.frequencyLabelMonthlyOn(anchor ?? 1);
      case HabitFrequency.interval:
        return AppStrings.frequencyLabelEveryNDays(intervalDays ?? 1);
    }
  }

  String get archivedSubtitle {
    switch (frequency) {
      case HabitFrequency.daily:
        return AppStrings.frequencyLabelDaily;
      case HabitFrequency.weekly:
        return AppStrings.frequencyLabelWeekly;
      case HabitFrequency.monthly:
        return AppStrings.frequencyLabelMonthly;
      case HabitFrequency.interval:
        return AppStrings.frequencyLabelEveryNDays(intervalDays ?? 1);
    }
  }

  String fullDisplaySubtitle(String? categoryName) {
    final frequency = frequencySubtitle;
    if (categoryName == null || categoryName.isEmpty) {
      return frequency;
    }
    return '$frequency - $categoryName';
  }
}
