part of '../../home_page.dart';

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.isDone,
    this.hasNote = false,
    this.categoryName,
    required this.onChanged,
    required this.onReflection,
    required this.onDetails,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final Habit habit;
  final bool isDone;
  final bool hasNote;
  final String? categoryName;
  final ValueChanged<bool> onChanged;
  final VoidCallback onReflection;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(habit.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.78,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            icon: Icons.edit_outlined,
            label: AppStrings.edit,
            backgroundColor: theme.colorScheme.tertiaryContainer,
            foregroundColor: theme.colorScheme.onTertiaryContainer,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
          ),
          SlidableAction(
            onPressed: (_) => onArchive(),
            icon: Icons.archive_outlined,
            label: AppStrings.archive,
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
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
        child: InkWell(
          onTap: onDetails,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Checkbox(
                  value: isDone,
                  onChanged: (value) => onChanged(value ?? false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        habit.fullDisplaySubtitle(categoryName),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reflection Note',
                  icon: Icon(
                    hasNote ? Icons.rate_review : Icons.rate_review_outlined,
                    color: hasNote
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onReflection,
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
