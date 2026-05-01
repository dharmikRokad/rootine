part of '../home_page.dart';

class ManageCategoriesPage extends ConsumerWidget {
  const ManageCategoriesPage({super.key});

  static const List<int> _palette = AppColors.categoryPalette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesValue = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.manageCategoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddCategory(context, ref),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newCategory),
      ),
      body: categoriesValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(AppStrings.couldNotLoadMessage(AppStrings.categories, error)),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text(AppStrings.noCategoriesYet),
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
                        ? AppStrings.categorySubtitleDefault
                        : AppStrings.categorySubtitleCustom,
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
                      label: AppStrings.rename,
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
                      label: AppStrings.delete,
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
      title: AppStrings.createCategory,
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
      title: AppStrings.renameCategory,
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
        title: const Text(AppStrings.deleteCategoryTitle),
        content: Text(
          AppStrings.deleteCategoryMessage(category.name),
        ),
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
