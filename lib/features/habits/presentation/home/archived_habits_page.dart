part of '../home_page.dart';

class ArchivedHabitsPage extends ConsumerWidget {
  const ArchivedHabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedValue = ref.watch(archivedHabitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Archived Habits')),
      body: archivedValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load archived: $error')),
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text('No archived habits yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Card(
                child: ListTile(
                  title: Text(habit.name),
                  subtitle: Text(_frequencySubtitle(habit)),
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
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'restore') {
                        ref.read(habitActionsProvider).unarchiveHabit(habit.id);
                      }
                      if (value == 'delete') {
                        _confirmDeleteHabit(context, habit.name).then((result) {
                          if (result != true) {
                            return;
                          }
                          ref.read(habitActionsProvider).deleteHabit(habit.id);
                        });
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'restore', child: Text('Restore')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _frequencySubtitle(Habit habit) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.interval:
        return 'Every ${habit.intervalDays ?? 1} days';
    }
  }

  Future<bool?> _confirmDeleteHabit(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Delete "$name" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
