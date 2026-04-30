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
      name: (map['name'] as String?) ?? 'Category',
      colorValue: (map['colorValue'] as int?) ?? 0xFF0A7E8C,
      iconCodePoint: map['iconCodePoint'] as int?,
      isSystem: (map['isSystem'] as bool?) ?? false,
      createdAt: createdAt,
    );
  }
}

const defaultHabitCategories = <({String id, String name, int colorValue})>[
  (id: 'health', name: 'Health', colorValue: 0xFF2D9CDB),
  (id: 'fitness', name: 'Fitness', colorValue: 0xFF27AE60),
  (id: 'learning', name: 'Learning', colorValue: 0xFFF2994A),
  (id: 'work', name: 'Work', colorValue: 0xFF6C5CE7),
  (id: 'mindfulness', name: 'Mindfulness', colorValue: 0xFF00B894),
  (id: 'personal', name: 'Personal', colorValue: 0xFFE17055),
  (id: 'finance', name: 'Finance', colorValue: 0xFF0984E3),
];
