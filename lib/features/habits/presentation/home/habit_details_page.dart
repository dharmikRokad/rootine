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
    final habitsValue = ref.watch(habitsProvider);
    final categoryById = ref.watch(categoryByIdProvider);

    final dateFormat = DateFormat('EEE, d MMM yyyy');
    final selectedDate = normalizeDate(
      focusDate ?? ref.watch(selectedDateProvider),
    );
    final today = normalizeDate(DateTime.now());

    final habit = habitsValue.value?.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(
        id: habitId,
        name: title,
        frequency: HabitFrequency.daily,
        createdAt: DateTime.now(),
        startDate: dateKey(DateTime.now()),
        scheduleUpdatedAt: dateKey(DateTime.now()),
      ),
    );

    final categoryName = habit != null && habit.categoryId != null
        ? categoryById[habit.categoryId]?.name
        : null;

    final theme = Theme.of(context);

    return detailValue.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Text(
            AppStrings.couldNotLoadMessage(AppStrings.details, error),
          ),
        ),
      ),
      data: (stats) {
        HabitCompletionNoteItem? selectedDayNote;
        for (final item in stats.recentNotes) {
          if (normalizeDate(item.date) == selectedDate) {
            selectedDayNote = item;
            break;
          }
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${stats.habit.frequency.name.capitalize()} • ${categoryName ?? "General"}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    if (habit != null) {
                      _openEditHabitSheet(context, habit);
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) async {
                    if (value == 'archive') {
                      await ref
                          .read(habitActionsProvider)
                          .archiveHabit(habitId);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } else if (value == 'delete') {
                      final confirmed = await _confirmDelete(context, title);
                      if (confirmed == true) {
                        await ref
                            .read(habitActionsProvider)
                            .deleteHabit(habitId);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Archive'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // Selected Day Note Banner Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedDayNote == null
                                    ? 'No note for this day yet.'
                                    : selectedDayNote.note,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedDayNote == null
                                    ? 'Tap the note icon to add one.'
                                    : (selectedDate == today
                                          ? "Today's Note"
                                          : dateFormat.format(selectedDate)),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.note_add_outlined, size: 20),
                            onPressed: () => _openNoteEditor(
                              context,
                              ref,
                              initialDate: selectedDate,
                              initialNote: selectedDayNote?.note,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 3 Stat Cards Row (Equal Height)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatBoxItem(
                          icon: Icons.whatshot,
                          title: AppStrings.currentStreak,
                          value: '${stats.currentStreak}',
                          unit: 'check-in',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBoxItem(
                          icon: Icons.workspace_premium,
                          title: AppStrings.bestStreak,
                          value: '${stats.bestStreak}',
                          unit: 'check-in',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBoxItem(
                          icon: Icons.track_changes,
                          title: 'Last 30 Days\nAdherence',
                          value:
                              '${(stats.last30Rate * 100).toStringAsFixed(0)}%',
                          subtitle:
                              '${stats.last30Completed} / ${stats.last30Due} days',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Contribution Graph
                _HabitHeatmap(cells: stats.heatmap),
                const SizedBox(height: 14),

                // Reflection Notes History Section Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Reflection Notes History',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (stats.recentNotes.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.edit_note_outlined,
                                    size: 54,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No reflection notes yet.',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Capture your thoughts and progress.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.note_add_outlined),
                                      label: const Text('Add Reflection Note'),
                                      onPressed: () => _openNoteEditor(
                                        context,
                                        ref,
                                        initialDate: selectedDate,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: stats.recentNotes
                                .map(
                                  (noteItem) => Card(
                                    elevation: 0,
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.rate_review_outlined,
                                      ),
                                      title: Text(noteItem.note),
                                      subtitle: Text(
                                        dateFormat.format(noteItem.date),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        onPressed: () => _openNoteEditor(
                                          context,
                                          ref,
                                          initialDate: noteItem.date,
                                          initialNote: noteItem.note,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditHabitSheet(BuildContext context, Habit habit) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateHabitSheet(initialHabit: habit),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String habitName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Point'),
        content: Text('Are you sure you want to delete "$habitName"?'),
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

class _StatBoxItem extends StatelessWidget {
  const _StatBoxItem({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.unit,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomText = unit ?? subtitle;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 16.5,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (bottomText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    bottomText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
