class HabitAchievement {
  const HabitAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.progress,
    required this.targetLabel,
    this.isNewlyUnlocked = false,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
  final double progress;
  final String targetLabel;
  final bool isNewlyUnlocked;

  HabitAchievement copyWith({bool? isNewlyUnlocked}) {
    return HabitAchievement(
      id: id,
      title: title,
      description: description,
      unlocked: unlocked,
      progress: progress,
      targetLabel: targetLabel,
      isNewlyUnlocked: isNewlyUnlocked ?? this.isNewlyUnlocked,
    );
  }
}
