import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_strings.dart';
import '../../../core/date_helpers.dart';
import '../../../core/theme_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../application/habits_controller.dart';
import '../domain/entity/habit.dart';
import '../domain/entity/habit_achievement.dart';
import '../domain/entity/habit_category.dart';
import '../domain/entity/habit_detail_stats.dart';
import '../domain/habit_extensions.dart';
import '../domain/entity/habit_stats.dart';
import '../domain/stats_extensions.dart';

part 'home/archived_habits_page.dart';
part 'home/create_habit_sheet.dart';
part 'home/sheet/create_category_dialog.dart';
part 'home/sheet/category_input.dart';
part 'home/day_switcher.dart';
part 'home/habit_details_page.dart';
part 'home/details/habit_streak_chart.dart';
part 'home/details/habit_heatmap.dart';
part 'home/details/legend_dot.dart';
part 'home/details/weekly_adherence_chart.dart';
part 'home/details/note_edit_result.dart';
part 'home/manage_categories_page.dart';
part 'home/categories/category_name_dialog.dart';
part 'home/stats_tab.dart';
part 'home/stats/stat_card.dart';
part 'home/stats/achievements_section.dart';
part 'home/stats/celebration_banner.dart';
part 'home/stats/completion_line_chart.dart';
part 'home/stats/completion_bar_chart.dart';
part 'home/stats/rolling_rate_chart.dart';
part 'home/stats/weekday_performance_chart.dart';
part 'home/track_tab.dart';
part 'home/track/category_filter_bar.dart';
part 'home/track/habit_tile.dart';

class HabitsHomePage extends ConsumerStatefulWidget {
  const HabitsHomePage({super.key});

  @override
  ConsumerState<HabitsHomePage> createState() => _HabitsHomePageState();
}

class _HabitsHomePageState extends ConsumerState<HabitsHomePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final selectedDate = ref.watch(selectedDateProvider);
    final categoriesBootstrap = ref.watch(categoriesBootstrapProvider);

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppStrings.appTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _authLabel(user),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text(AppStrings.manageCategories),
                onTap: () {
                  Navigator.of(context).pop();
                  _openManageCategories(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text(AppStrings.archivedHabits),
                onTap: () {
                  Navigator.of(context).pop();
                  _openArchivedHabits(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text(AppStrings.appearance),
                onTap: () {
                  Navigator.of(context).pop();
                  _showThemeSelector(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text(AppStrings.signOut),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authActionsProvider).signOut();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          _DaySwitcher(
            date: selectedDate,
            onPrevious: () {
              ref.read(selectedDateProvider.notifier).state = normalizeDate(
                selectedDate.subtract(const Duration(days: 1)),
              );
            },
            onNext: () {
              ref.read(selectedDateProvider.notifier).state = normalizeDate(
                selectedDate.add(const Duration(days: 1)),
              );
            },
            onToday: () {
              ref.read(selectedDateProvider.notifier).state = normalizeDate(
                DateTime.now(),
              );
            },
          ),
        ],
      ),
      body: categoriesBootstrap.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            AppStrings.couldNotLoadMessage(AppStrings.categories, error),
          ),
        ),
        data: (_) => IndexedStack(
          index: _selectedTab,
          children: const [_TrackTab(), _StatsTab()],
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateHabitSheet(context),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.newHabit),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: AppStrings.track,
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: AppStrings.stats,
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateHabitSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreateHabitSheet(),
    );
  }

  Future<void> _openArchivedHabits(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ArchivedHabitsPage()));
  }

  Future<void> _openManageCategories(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ManageCategoriesPage()),
    );
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final currentMode = ref.watch(themeModeProvider);
        return AlertDialog(
          title: const Text(AppStrings.appearance),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text(AppStrings.themeSystem),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text(AppStrings.themeLight),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text(AppStrings.themeDark),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _authLabel(dynamic user) {
    if (user == null) {
      return AppStrings.signedOut;
    }

    if (user.isAnonymous == true) {
      return AppStrings.signInRequired;
    }

    final displayName = (user.displayName as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = (user.email as String?)?.trim();
    if (email != null && email.isNotEmpty) {
      final namePart = email.split('@').first.trim();
      if (namePart.isNotEmpty) {
        return namePart;
      }
      return email;
    }

    final uid = user.uid as String?;
    if (uid == null || uid.isEmpty) {
      return AppStrings.signedIn;
    }

    final short = min(6, uid.length);
    return '${AppStrings.userPrefix}${uid.substring(0, short)}';
  }
}
