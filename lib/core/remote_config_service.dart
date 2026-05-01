import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'app_colors.dart';
import 'app_strings.dart';
import '../features/habits/domain/entity/habit_category.dart';

/// Hard-coded fallback list used when Remote Config is unavailable or the
/// key is missing / empty.  Built from [AppStrings] and [AppColors] so there
/// is a single source of truth for names and color values.
List<({String id, String name, int colorValue})> _buildLocalFallback() => [
  (
    id: 'health',
    name: AppStrings.categoryHealth,
    colorValue: AppColors.categoryColorHealthInt,
  ),
  (
    id: 'fitness',
    name: AppStrings.categoryFitness,
    colorValue: AppColors.categoryColorFitnessInt,
  ),
  (
    id: 'learning',
    name: AppStrings.categoryLearning,
    colorValue: AppColors.categoryColorLearningInt,
  ),
  (
    id: 'work',
    name: AppStrings.categoryWork,
    colorValue: AppColors.categoryColorWorkInt,
  ),
  (
    id: 'mindfulness',
    name: AppStrings.categoryMindfulness,
    colorValue: AppColors.categoryColorMindfulnessInt,
  ),
  (
    id: 'personal',
    name: AppStrings.categoryPersonal,
    colorValue: AppColors.categoryColorPersonalInt,
  ),
  (
    id: 'finance',
    name: AppStrings.categoryFinance,
    colorValue: AppColors.categoryColorFinanceInt,
  ),
];

/// Encodes [_buildLocalFallback] as JSON so it can be used as the in-app
/// default for [AppStrings.remoteConfigDefaultCategoriesKey].
String _buildLocalFallbackJson() {
  final list = _buildLocalFallback()
      .map(
        (e) => {
          'id': e.id,
          'name': e.name,
          'colorValue': e.colorValue,
        },
      )
      .toList();
  return jsonEncode(list);
}

class RemoteConfigService {
  RemoteConfigService._(this._rc);

  final FirebaseRemoteConfig _rc;

  /// Initialise Remote Config, set in-app defaults, then fetch & activate.
  static Future<RemoteConfigService> create() async {
    final rc = FirebaseRemoteConfig.instance;

    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // In-app defaults ensure the app works even on the first launch before
    // a successful fetch.
    await rc.setDefaults({
      AppStrings.remoteConfigDefaultCategoriesKey: _buildLocalFallbackJson(),
    });

    try {
      await rc.fetchAndActivate();
    } catch (_) {
      // Network unavailable – the in-app default will be used instead.
    }

    return RemoteConfigService._(rc);
  }

  /// Returns the list of default categories defined in Remote Config.
  /// Falls back to [_buildLocalFallback] if the remote value is empty or invalid.
  List<({String id, String name, int colorValue})> get defaultCategories {
    final raw = _rc.getString(AppStrings.remoteConfigDefaultCategoriesKey);
    return _parse(raw.trim().isEmpty ? _buildLocalFallbackJson() : raw);
  }

  List<({String id, String name, int colorValue})> _parse(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return (
          id: map['id'] as String,
          name: map['name'] as String,
          colorValue: map['colorValue'] as int,
        );
      }).toList();
    } catch (_) {
      // Malformed JSON – fall back to the compile-time constant.
      return defaultHabitCategories.toList();
    }
  }
}
