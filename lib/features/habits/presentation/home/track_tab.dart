part of '../home_page.dart';

class _TrackTab extends ConsumerWidget {
  const _TrackTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final dueHabitsValue = ref.watch(dueHabitsForSelectedDateProvider);
    final completedValue = ref.watch(completionSetForSelectedDateProvider);
    final completionsValue = ref.watch(completionsProvider);
    final categoryById = ref.watch(categoryByIdProvider);

    final completionMap = <String, HabitCompletion>{};
    for (final c in completionsValue.value ?? const <HabitCompletion>[]) {
      if (dateKey(c.date) == dateKey(date)) {
        completionMap[c.habitId] = c;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          const _CategoryFilterBar(),
          const SizedBox(height: 12),
          Expanded(
            child: dueHabitsValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  AppStrings.couldNotLoadMessage(AppStrings.habits, error),
                ),
              ),
              data: (habits) => completedValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    AppStrings.couldNotLoadMessage(
                      AppStrings.completions,
                      error,
                    ),
                  ),
                ),
                data: (completedIds) {
                  if (habits.isEmpty) {
                    return const Center(
                      child: Text(
                        AppStrings.noHabitsForThisDate,
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
                      final existingCompletion = completionMap[habit.id];
                      final hasNote =
                          (existingCompletion?.note ?? '').trim().isNotEmpty;

                      return _HabitTile(
                        habit: habit,
                        isDone: isDone,
                        hasNote: hasNote,
                        categoryName: categoryById[habit.categoryId]?.name,
                        onChanged: (value) {
                          ref
                              .read(habitActionsProvider)
                              .setCompleted(
                                habitId: habit.id,
                                date: date,
                                isDone: value,
                                note: existingCompletion?.note,
                              );
                        },
                        onReflection: () => _openReflectionSheet(
                          context,
                          ref,
                          habit,
                          date,
                          isDone,
                          existingCompletion?.note,
                        ),
                        onDetails: () => _openDetails(context, habit, date),
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

  Future<void> _openReflectionSheet(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    DateTime date,
    bool initialIsDone,
    String? initialNote,
  ) async {
    var isAccomplished = initialIsDone;
    final controller = TextEditingController(text: initialNote ?? '');
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: media.viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Reflection - ${habit.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      isAccomplished
                          ? 'Accomplished (Checked)'
                          : 'Not Accomplished',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isAccomplished
                          ? 'Marked as completed for today'
                          : 'Not completed yet today',
                    ),
                    value: isAccomplished,
                    onChanged: (val) {
                      setState(() {
                        isAccomplished = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Reflection Notes',
                      hintText:
                          'Write reflections on why it was accomplished or what prevented it...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Save Reflection'),
                      onPressed: () async {
                        final text = controller.text.trim();
                        await ref.read(habitActionsProvider).setCompleted(
                              habitId: habit.id,
                              date: date,
                              isDone: isAccomplished,
                              note: text.isEmpty ? null : text,
                            );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _openEditHabitSheet(BuildContext context, Habit habit) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateHabitSheet(initialHabit: habit),
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    Habit habit,
    DateTime selectedDate,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitDetailsPage(
          habitId: habit.id,
          title: habit.name,
          focusDate: selectedDate,
        ),
      ),
    );
  }

  Future<bool?> _confirmDeleteHabit(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteHabitTitle),
        content: Text(AppStrings.deleteHabitMessage(name)),
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
