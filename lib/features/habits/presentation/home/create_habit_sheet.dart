part of '../home_page.dart';

class _CreateHabitSheet extends ConsumerStatefulWidget {
  const _CreateHabitSheet({this.initialHabit});

  final Habit? initialHabit;

  @override
  ConsumerState<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<_CreateHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _categoryId;
  HabitFrequency _frequency = HabitFrequency.daily;
  int _intervalDays = 2;
  int _weekday = DateTime.now().weekday;
  int _monthDay = DateTime.now().day;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHabit;
    if (initial == null) {
      return;
    }

    _nameController.text = initial.name;
    _categoryId = initial.categoryId;
    _frequency = initial.frequency;
    _intervalDays = initial.intervalDays ?? _intervalDays;
    if (initial.frequency == HabitFrequency.weekly) {
      _weekday = initial.anchor ?? _weekday;
    }
    if (initial.frequency == HabitFrequency.monthly) {
      _monthDay = initial.anchor ?? _monthDay;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isEditing = widget.initialHabit != null;
    final categoriesValue = ref.watch(categoriesProvider);
    final categories = categoriesValue.value ?? const <HabitCategory>[];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: media.viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? AppStrings.editHabit : AppStrings.createHabit,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.habitName,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.pleaseEnterHabitName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: AppStrings.category,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(AppStrings.noCategory),
                        ),
                        ...categories.map(
                          (category) => DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _categoryId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: AppStrings.addCategory,
                    onPressed: () => _createCategory(context),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HabitFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: AppStrings.frequency,
                  border: OutlineInputBorder(),
                ),
                items: HabitFrequency.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _frequency = value;
                    });
                  }
                },
              ),
              if (_frequency == HabitFrequency.interval) ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '$_intervalDays',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.everyNDays,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      _intervalDays = parsed;
                    }
                  },
                ),
              ],
              if (_frequency == HabitFrequency.weekly) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _weekday,
                  decoration: const InputDecoration(
                    labelText: AppStrings.weekday,
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    7,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(AppStrings.weekdayNames[index]),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _weekday = value;
                      });
                    }
                  },
                ),
              ],
              if (_frequency == HabitFrequency.monthly) ...[
                const SizedBox(height: 12),
                Text('${AppStrings.dayOfMonth} $_monthDay'),
                Slider(
                  min: 1,
                  max: 31,
                  divisions: 30,
                  label: '$_monthDay',
                  value: _monthDay.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _monthDay = value.round();
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    isEditing ? AppStrings.saveChanges : AppStrings.saveHabit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    int? anchor;
    int? intervalDays;

    switch (_frequency) {
      case HabitFrequency.daily:
        break;
      case HabitFrequency.weekly:
        anchor = _weekday;
        break;
      case HabitFrequency.monthly:
        anchor = _monthDay;
        break;
      case HabitFrequency.interval:
        intervalDays = _intervalDays;
        break;
    }

    final initial = widget.initialHabit;
    if (initial == null) {
      await ref
          .read(habitActionsProvider)
          .createHabit(
            name: _nameController.text.trim(),
            frequency: _frequency,
            categoryId: _categoryId,
            intervalDays: intervalDays,
            anchor: anchor,
          );
    } else {
      await ref
          .read(habitActionsProvider)
          .editHabit(
            habit: initial,
            name: _nameController.text.trim(),
            frequency: _frequency,
            categoryId: _categoryId,
            intervalDays: intervalDays,
            anchor: anchor,
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _createCategory(BuildContext context) async {
    final result = await showDialog<_CategoryInput>(
      context: context,
      builder: (context) => const _CreateCategoryDialog(),
    );

    if (result == null || result.name.trim().isEmpty) {
      return;
    }

    final category = await ref
        .read(habitActionsProvider)
        .createCategory(
          name: result.name.trim(),
          colorValue: result.colorValue,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _categoryId = category.id;
    });
  }
}
