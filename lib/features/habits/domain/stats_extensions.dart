import '../../../core/app_strings.dart';

extension DoubleStatsX on double {
  String get rateDeltaLabel {
    final absDelta = (abs() * 100).toStringAsFixed(1);
    if (this > 0.001) {
      return '+$absDelta ${AppStrings.pts}';
    }
    if (this < -0.001) {
      return '-$absDelta ${AppStrings.pts}';
    }
    return '0.0 ${AppStrings.pts}';
  }

  String get consistencyLabel {
    if (this >= 0.85) {
      return AppStrings.excellent;
    }
    if (this >= 0.7) {
      return AppStrings.strong;
    }
    if (this >= 0.5) {
      return AppStrings.improving;
    }
    return AppStrings.buildingMomentum;
  }

  String get momentumMessage {
    if (this > 0.08) {
      return AppStrings.strongUpwardTrend;
    }
    if (this > 0.02) {
      return AppStrings.improvingSteadily;
    }
    if (this < -0.08) {
      return AppStrings.recentDipAdjust;
    }
    if (this < -0.02) {
      return AppStrings.slightlyDownWeek;
    }
    return AppStrings.stableComparedLastWeek;
  }
}

extension IntStatsX on int {
  String get weekdayName {
    final index = (this - 1).clamp(0, 6);
    return AppStrings.weekdayNamesShort[index];
  }
}
