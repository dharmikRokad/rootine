part of '../home_page.dart';

class _TrackTab extends ConsumerWidget {
  const _TrackTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final dueHabitsValue = ref.watch(dueHabitsForSelectedDateProvider);
    final completedValue = ref.watch(completionSetForSelectedDateProvider);
    final categoryById = ref.watch(categoryByIdProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          const _CategoryFilterBar(),
          const SizedBox(height: 12),
          Expanded(
            child: dueHabitsValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Could not load habits: $error')),
              data: (habits) => completedValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Could not load completions: $error')),
                data: (completedIds) {
                  if (habits.isEmpty) {
                    return const Center(
                      child: Text(
                        'No habits for this date yet.\nTap New Habit to add one.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: habits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final isDone = completedIds.contains(habit.id);
                      return _HabitTile(
                        habit: habit,
                        isDone: isDone,
                        categoryName: categoryById[habit.categoryId]?.name,
                        onChanged: (value) {
                          ref
                              .read(habitActionsProvider)
                              .setCompleted(
                                habitId: habit.id,
                                date: date,
                                isDone: value,
                              );
                        },
                        onDetails: () => _openDetails(context, habit),
                        onEdit: () => _openEditHabitSheet(context, habit),
                        onArchive: () async {
                          await ref
                              .read(habitActionsProvider)
                              .archiveHabit(habit.id);
                        },
                        onDelete: () async {
                          final shouldDelete =
                              await _confirmDeleteHabit(context, habit.name) ??
                              false;
                          if (!shouldDelete) {
                            return;
                          }
                          await ref
                              .read(habitActionsProvider)
                              .deleteHabit(habit.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditHabitSheet(BuildContext context, Habit habit) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateHabitSheet(initialHabit: habit),
    );
  }

  Future<void> _openDetails(BuildContext context, Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitDetailsPage(habitId: habit.id, title: habit.name),
      ),
    );
  }

  Future<bool?> _confirmDeleteHabit(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Delete "$name" and all of its completion history?'),
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

class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);
    final categoriesValue = ref.watch(categoriesProvider);

    return categoriesValue.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) => SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('All'),
                selected: selectedCategoryId == null,
                onSelected: (_) {
                  ref.read(selectedCategoryFilterProvider.notifier).state =
                      null;
                },
              ),
            ),
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category.name),
                  selected: selectedCategoryId == category.id,
                  onSelected: (_) {
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        category.id;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.isDone,
    this.categoryName,
    required this.onChanged,
    required this.onDetails,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final Habit habit;
  final bool isDone;
  final String? categoryName;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: isDone,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(habit.name),
        subtitle: Text(_subtitle(habit)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        secondary: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'details':
                onDetails();
                break;
              case 'edit':
                onEdit();
                break;
              case 'archive':
                onArchive();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'details', child: Text('Details')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'archive', child: Text('Archive')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  String _subtitle(Habit habit) {
    final frequency = _frequencySubtitle(habit);
    final category = categoryName;
    if (category == null || category.isEmpty) {
      return frequency;
    }
    return '$frequency - $category';
  }

  String _frequencySubtitle(Habit habit) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly on ${_weekdayLabel(habit.anchor ?? 1)}';
      case HabitFrequency.monthly:
        return 'Monthly on day ${habit.anchor ?? 1}';
      case HabitFrequency.interval:
        return 'Every ${habit.intervalDays ?? 1} days';
    }
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final index = (weekday - 1).clamp(0, 6);
    return labels[index];
  }
}
