part of '../../home_page.dart';

class _AchievementsSection extends ConsumerStatefulWidget {
  const _AchievementsSection({
    required this.scope,
    required this.title,
    required this.value,
  });

  final String scope;
  final String title;
  final AsyncValue<List<HabitAchievement>> value;

  @override
  ConsumerState<_AchievementsSection> createState() =>
      _AchievementsSectionState();
}

class _AchievementsSectionState extends ConsumerState<_AchievementsSection> {
  String _lastMarkedKey = '';

  @override
  Widget build(BuildContext context) {
    final achievements = widget.value.value ?? const <HabitAchievement>[];
    final newlyUnlockedIds =
        achievements.where((a) => a.isNewlyUnlocked).map((a) => a.id).toList();
    final nextKey = newlyUnlockedIds.join('|');

    if (newlyUnlockedIds.isNotEmpty && nextKey != _lastMarkedKey) {
      _lastMarkedKey = nextKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref
            .read(habitActionsProvider)
            .markAchievementsCelebrated(widget.scope, newlyUnlockedIds);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        widget.value.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(AppStrings.couldNotLoadMessage(AppStrings.achievements, error)),
            ),
          ),
          data: (achievements) {
            final unlocked = achievements.where((a) => a.unlocked).length;
            final newlyUnlocked =
                achievements.where((a) => a.isNewlyUnlocked).length;

            return Column(
              children: [
                if (newlyUnlocked > 0) ...[
                  _CelebrationBanner(
                    text: AppStrings.newAchievementUnlockedLabel(newlyUnlocked),
                  ),
                  const SizedBox(height: 10),
                ],
                if (unlocked > 0 && newlyUnlocked == 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.achievementUnlockedLabel(unlocked),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (unlocked > 0 && newlyUnlocked == 0)
                  const SizedBox(height: 8),
                ...achievements.map(
                  (achievement) => Card(
                    child: ListTile(
                      leading: Icon(
                        achievement.unlocked
                            ? Icons.workspace_premium
                            : Icons.radio_button_unchecked,
                        color: achievement.unlocked
                            ? AppColors.achievementAccent
                            : Theme.of(context).colorScheme.outline,
                      ),
                      title: Text(achievement.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(achievement.description),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: achievement.progress,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.targetLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
