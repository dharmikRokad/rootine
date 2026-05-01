import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../core/date_helpers.dart';
import '../../auth/application/auth_controller.dart';
import '../application/habits_controller.dart';
import '../domain/habit.dart';
import '../domain/habit_achievement.dart';
import '../domain/habit_category.dart';
import '../domain/habit_detail_stats.dart';
import '../domain/habit_stats.dart';

part 'home/archived_habits_page.dart';
part 'home/create_habit_sheet.dart';
part 'home/habit_details_page.dart';
part 'home/manage_categories_page.dart';
part 'home/stats_tab.dart';
part 'home/track_tab.dart';

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
                      'Habitz',
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
                title: const Text('Manage categories'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openManageCategories(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archived habits'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openArchivedHabits(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
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
        title: const Text('Habitz'),
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
        error: (error, _) =>
            Center(child: Text('Could not load categories: $error')),
        data: (_) => IndexedStack(
          index: _selectedTab,
          children: const [_TrackTab(), _StatsTab()],
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateHabitSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('New Habit'),
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
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Stats',
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

  String _authLabel(dynamic user) {
    if (user == null) {
      return 'Signed out';
    }

    if (user.isAnonymous == true) {
      return 'Sign-in required';
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
      return 'Signed in';
    }

    final short = min(6, uid.length);
    return 'User ${uid.substring(0, short)}';
  }
}

class _DaySwitcher extends StatelessWidget {
  const _DaySwitcher({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('EEE, d MMM');

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous day',
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onToday,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  format.format(date),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next day',
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
