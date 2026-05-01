part of '../home_page.dart';

class ArchivedHabitsPage extends ConsumerWidget {
  const ArchivedHabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedValue = ref.watch(archivedHabitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.archivedHabitsTitle)),
      body: archivedValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
            child: Text(
              AppStrings.couldNotLoadMessage(AppStrings.archived, error),
            ),
          ),
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text(AppStrings.noArchivedHabitsYet));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final habit = habits[index];
              final theme = Theme.of(context);

              return Slidable(
                key: ValueKey(habit.id),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.52,
                  children: [
                    SlidableAction(
                      onPressed: (_) =>
                          ref.read(habitActionsProvider).unarchiveHabit(habit.id),
                      icon: Icons.unarchive_outlined,
                      label: AppStrings.restore,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                    SlidableAction(
                      onPressed: (_) {
                        _confirmDeleteHabit(context, habit.name).then((result) {
                          if (result == true) {
                            ref.read(habitActionsProvider).deleteHabit(habit.id);
                          }
                        });
                      },
                      icon: Icons.delete_outline,
                      label: AppStrings.delete,
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16),
                      ),
                    ),
                  ],
                ),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    title: Text(habit.name),
                    subtitle: Text(habit.archivedSubtitle),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HabitDetailsPage(
                            habitId: habit.id,
                            title: habit.name,
                          ),
                        ),
                      );
                    },
                    trailing: Icon(
                      Icons.swipe_left_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDeleteHabit(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteHabitTitle),
        content: Text(AppStrings.deleteHabitPermanentlyMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
