part of '../home_page.dart';

class ManageCategoriesPage extends ConsumerWidget {
  const ManageCategoriesPage({super.key});

  static const List<int> _palette = <int>[
    0xFF2D9CDB,
    0xFF27AE60,
    0xFFF2994A,
    0xFF6C5CE7,
    0xFF00B894,
    0xFFE17055,
    0xFF0984E3,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesValue = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddCategory(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
      body: categoriesValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load categories: $error')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories yet. Create one to get started.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              final theme = Theme.of(context);

              final tile = Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(category.colorValue),
                    child: const Icon(Icons.category, color: Colors.white),
                  ),
                  title: Text(category.name),
                  subtitle: Text(
                    category.isSystem
                        ? 'Default category'
                        : 'Custom category · Slide for actions',
                  ),
                  trailing: Icon(
                    category.isSystem
                        ? Icons.lock_outline
                        : Icons.swipe_left_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );

              if (category.isSystem) {
                return tile;
              }

              return Slidable(
                key: ValueKey(category.id),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.52,
                  children: [
                    SlidableAction(
                      onPressed: (_) =>
                          _onRenameCategory(context, ref, category),
                      icon: Icons.edit_outlined,
                      label: 'Rename',
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      foregroundColor: theme.colorScheme.onTertiaryContainer,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                    SlidableAction(
                      onPressed: (_) =>
                          _onDeleteCategory(context, ref, category),
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16),
                      ),
                    ),
                  ],
                ),
                child: tile,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onAddCategory(BuildContext context, WidgetRef ref) async {
    final name = await _showCategoryNameDialog(
      context,
      title: 'Create category',
    );
    if (name == null) {
      return;
    }

    final categories =
        ref.read(categoriesProvider).value ?? const <HabitCategory>[];
    final colorValue = _palette[categories.length % _palette.length];

    await ref
        .read(habitActionsProvider)
        .createCategory(name: name, colorValue: colorValue);
  }

  Future<void> _onRenameCategory(
    BuildContext context,
    WidgetRef ref,
    HabitCategory category,
  ) async {
    final name = await _showCategoryNameDialog(
      context,
      title: 'Rename category',
      initialName: category.name,
    );
    if (name == null) {
      return;
    }

    await ref
        .read(habitActionsProvider)
        .updateCategory(category: category, name: name);
  }

  Future<void> _onDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    HabitCategory category,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "${category.name}"? Habits in this category will keep working but without a category.',
        ),
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

    if (shouldDelete != true) {
      return;
    }

    await ref.read(habitActionsProvider).deleteCategory(category.id);
  }

  Future<String?> _showCategoryNameDialog(
    BuildContext context, {
    required String title,
    String initialName = '',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          _CategoryNameDialog(title: title, initialName: initialName),
    );
  }
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.title, required this.initialName});

  final String title;
  final String initialName;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Category name',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) {
              return;
            }
            Navigator.of(context).pop(value);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
