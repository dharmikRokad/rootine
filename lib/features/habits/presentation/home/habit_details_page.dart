part of '../home_page.dart';

class HabitDetailsPage extends ConsumerWidget {
  const HabitDetailsPage({
    super.key,
    required this.habitId,
    required this.title,
    this.focusDate,
  });

  final String habitId;
  final String title;
  final DateTime? focusDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailValue = ref.watch(habitDetailStatsProvider(habitId));
    final achievementsValue = ref.watch(habitAchievementsProvider(habitId));
    ref.watch(syncHabitAchievementUnlocksProvider(habitId));
    final dateFormat = DateFormat('EEE, d MMM yyyy');
    final selectedDate = normalizeDate(
      focusDate ?? ref.watch(selectedDateProvider),
    );
    final today = normalizeDate(DateTime.now());

    return detailValue.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(AppStrings.couldNotLoadMessage(AppStrings.details, error))),
      ),
      data: (stats) {
        HabitCompletionNoteItem? selectedDayNote;
        for (final item in stats.recentNotes) {
          if (normalizeDate(item.date) == selectedDate) {
            selectedDayNote = item;
            break;
          }
        }

        final noteHeading = selectedDate == today
            ? AppStrings.todaysNote
            : AppStrings.noteForDateLabel(dateFormat.format(selectedDate));

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (selectedDayNote == null)
                IconButton(
                  tooltip: AppStrings.addCompletionNote,
                  icon: const Icon(Icons.note_add_outlined),
                  onPressed: () =>
                      _openNoteEditor(context, ref, initialDate: selectedDate),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  noteHeading,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (selectedDayNote == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        AppStrings.noNoteForDay,
                      ),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      title: Text(selectedDayNote.note),
                      subtitle: Text(dateFormat.format(selectedDayNote.date)),
                      trailing: IconButton(
                        tooltip: AppStrings.editNote,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openNoteEditor(
                          context,
                          ref,
                          initialDate: selectedDayNote!.date,
                          initialNote: selectedDayNote.note,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                _StatCard(
                  title: AppStrings.currentStreak,
                  value: AppStrings.checkInsLabel(stats.currentStreak),
                ),
                const SizedBox(height: 10),
                _StatCard(
                  title: AppStrings.bestStreak,
                  value: AppStrings.checkInsLabel(stats.bestStreak),
                ),
                const SizedBox(height: 10),
                _StatCard(
                  title: AppStrings.last30DaysAdherence,
                  value:
                      '${stats.last30Completed}/${stats.last30Due} (${(stats.last30Rate * 100).toStringAsFixed(1)}%)',
                ),
                const SizedBox(height: 18),
                Text(
                  AppStrings.streakHistory30Days,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _HabitStreakChart(points: stats.streakHistory),
                const SizedBox(height: 18),
                Text(
                  AppStrings.missedDayHeatmap12Weeks,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _HabitHeatmap(cells: stats.heatmap),
                const SizedBox(height: 18),
                Text(
                  AppStrings.frequencyAdherenceWeekly,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                _WeeklyAdherenceChart(points: stats.weeklyAdherence),
                const SizedBox(height: 18),
                _AchievementsSection(
                  scope: 'habit:$habitId',
                  title: AppStrings.habitAchievements,
                  value: achievementsValue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openNoteEditor(
    BuildContext context,
    WidgetRef ref, {
    DateTime? initialDate,
    String? initialNote,
  }) async {
    var selectedDate = normalizeDate(initialDate ?? DateTime.now());
    final controller = TextEditingController(text: initialNote ?? '');

    final result = await showModalBottomSheet<_NoteEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final media = MediaQuery.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: media.viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.completionNote,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = normalizeDate(picked);
                        });
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: Text(
                      DateFormat('EEE, d MMM yyyy').format(selectedDate),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: AppStrings.note,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          _NoteEditResult(
                            date: selectedDate,
                            note: controller.text.trim(),
                          ),
                        );
                      },
                      child: const Text(AppStrings.saveNote),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result == null || result.note.isEmpty) {
      controller.dispose();
      return;
    }

    await ref
        .read(habitActionsProvider)
        .setCompletionNote(
          habitId: habitId,
          date: result.date,
          note: result.note,
        );
    controller.dispose();
  }
}
