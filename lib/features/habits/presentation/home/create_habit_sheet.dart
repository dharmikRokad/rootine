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
                isEditing ? 'Edit Habit' : 'Create Habit',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
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
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No category'),
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
                    tooltip: 'Add category',
                    onPressed: () => _createCategory(context),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HabitFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
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
                    labelText: 'Every n days',
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
                    labelText: 'Weekday',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    7,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(_weekdayLong(index + 1)),
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
                Text('Day of month: $_monthDay'),
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
                  child: Text(isEditing ? 'Save Changes' : 'Save Habit'),
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
      await ref.read(habitActionsProvider).createHabit(
            name: _nameController.text.trim(),
            frequency: _frequency,
            categoryId: _categoryId,
            intervalDays: intervalDays,
            anchor: anchor,
          );
    } else {
      await ref.read(habitActionsProvider).editHabit(
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

  String _weekdayLong(int weekday) {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final index = (weekday - 1).clamp(0, 6);
    return labels[index];
  }

  Future<void> _createCategory(BuildContext context) async {
    final result = await showDialog<_CategoryInput>(
      context: context,
      builder: (context) => const _CreateCategoryDialog(),
    );

    if (result == null || result.name.trim().isEmpty) {
      return;
    }

    final category = await ref.read(habitActionsProvider).createCategory(
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

class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog();

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final _nameController = TextEditingController();
  int _selectedColor = 0xFF0A7E8C;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = <int>[
      0xFF0A7E8C,
      0xFF27AE60,
      0xFF2D9CDB,
      0xFFF2994A,
      0xFFE17055,
      0xFF6C5CE7,
    ];

    return AlertDialog(
      title: const Text('Create category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Category name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors
                .map(
                  (colorValue) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorValue;
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == colorValue
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _CategoryInput(
                name: _nameController.text,
                colorValue: _selectedColor,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _CategoryInput {
  const _CategoryInput({required this.name, required this.colorValue});

  final String name;
  final int colorValue;
}
