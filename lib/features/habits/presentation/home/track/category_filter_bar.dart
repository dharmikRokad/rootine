part of '../../home_page.dart';

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
                label: const Text(AppStrings.all),
                selected: selectedCategoryId == null,
                showCheckmark: false,
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
                  showCheckmark: false,
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
