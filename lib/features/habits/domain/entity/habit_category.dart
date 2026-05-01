import '../../../../core/app_colors.dart';
import '../../../../core/app_strings.dart';

class HabitCategory {
  const HabitCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    this.iconCodePoint,
    this.isSystem = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final int? iconCodePoint;
  final bool isSystem;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'isSystem': isSystem,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  HabitCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    bool? isSystem,
    DateTime? createdAt,
  }) {
    return HabitCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static HabitCategory fromMap(String id, Map<String, dynamic> map) {
    final createdRaw = map['createdAt'];
    final createdAt = createdRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(createdRaw)
        : DateTime.now();

    return HabitCategory(
      id: id,
      name: (map['name'] as String?) ?? AppStrings.defaultCategory,
      colorValue: (map['colorValue'] as int?) ?? AppColors.seedInt,
      iconCodePoint: map['iconCodePoint'] as int?,
      isSystem: (map['isSystem'] as bool?) ?? false,
      createdAt: createdAt,
    );
  }
}

const defaultHabitCategories = <({String id, String name, int colorValue})>[
  (id: 'health',      name: AppStrings.categoryHealth,      colorValue: AppColors.categoryColorHealthInt),
  (id: 'fitness',     name: AppStrings.categoryFitness,     colorValue: AppColors.categoryColorFitnessInt),
  (id: 'learning',    name: AppStrings.categoryLearning,    colorValue: AppColors.categoryColorLearningInt),
  (id: 'work',        name: AppStrings.categoryWork,        colorValue: AppColors.categoryColorWorkInt),
  (id: 'mindfulness', name: AppStrings.categoryMindfulness, colorValue: AppColors.categoryColorMindfulnessInt),
  (id: 'personal',    name: AppStrings.categoryPersonal,    colorValue: AppColors.categoryColorPersonalInt),
  (id: 'finance',     name: AppStrings.categoryFinance,     colorValue: AppColors.categoryColorFinanceInt),
];
