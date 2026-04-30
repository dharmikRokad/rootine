import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final categoriesBootstrap = ref.watch(categoriesBootstrapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitz'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Chip(
              avatar: const Icon(Icons.cloud_done, size: 18),
              label: Text(_authLabel(user)),
            ),
          ),
          IconButton(
            tooltip: 'Archived habits',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _openArchivedHabits(context),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) async {
              if (value == 'signOut') {
                await ref.read(authActionsProvider).signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'signOut', child: Text('Sign out')),
            ],
          ),
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
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

  String _authLabel(dynamic user) {
    if (user == null) {
      return 'Signed out';
    }

    if (user.isAnonymous == true) {
      return 'Sign-in required';
    }

    final uid = user.uid as String?;
    if (uid == null || uid.isEmpty) {
      return 'Signed in';
    }

    final short = min(6, uid.length);
    return 'User ${uid.substring(0, short)}';
  }
}
