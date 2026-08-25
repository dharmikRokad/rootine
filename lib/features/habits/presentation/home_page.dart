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
import '../domain/entity/habit_category.dart';
import '../domain/entity/habit_completion.dart';
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
part 'home/details/habit_heatmap.dart';
part 'home/details/note_edit_result.dart';
part 'home/manage_categories_page.dart';
part 'home/categories/category_name_dialog.dart';
part 'home/stats_tab.dart';
part 'home/stats/completion_line_chart.dart';
part 'home/stats/completion_bar_chart.dart';
part 'home/track_tab.dart';
part 'home/track/category_filter_bar.dart';
part 'home/track/habit_tile.dart';

class HabitsHomePage extends ConsumerStatefulWidget {
  const HabitsHomePage({super.key});

  @override
  ConsumerState<HabitsHomePage> createState() => _HabitsHomePageState();
}

class _HabitsHomePageState extends ConsumerState<HabitsHomePage>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _drawerController;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_isDrawerOpen) {
      _drawerController.reverse();
    } else {
      _drawerController.forward();
    }
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _closeDrawer() {
    if (_isDrawerOpen) {
      _drawerController.reverse();
      setState(() {
        _isDrawerOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final selectedDate = ref.watch(selectedDateProvider);
    final categoriesBootstrap = ref.watch(categoriesBootstrapProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isDrawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isDrawerOpen) {
          _closeDrawer();
        }
      },
      child: Stack(
        children: [
          // ── Hidden Background Animated Drawer Menu ─────────────────
          Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0F172A)
                : theme.colorScheme.surfaceContainerLowest,
            body: SafeArea(
              child: SizedBox(
                width: 220,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Header Card
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person_outline,
                              size: 24,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.nijDarshan,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _authLabel(user),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Menu Options List
                      _DrawerMenuItem(
                        icon: Icons.category_outlined,
                        label: AppStrings.manageCategories,
                        onTap: () {
                          _closeDrawer();
                          _openManageCategories(context);
                        },
                      ),
                      _DrawerMenuItem(
                        icon: Icons.archive_outlined,
                        label: AppStrings.archivedHabits,
                        onTap: () {
                          _closeDrawer();
                          _openArchivedHabits(context);
                        },
                      ),
                      _DrawerMenuItem(
                        icon: Icons.palette_outlined,
                        label: AppStrings.appearance,
                        onTap: () {
                          _closeDrawer();
                          _showThemeSelector(context, ref);
                        },
                      ),
                      const Spacer(),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _DrawerMenuItem(
                        icon: Icons.logout,
                        label: AppStrings.signOut,
                        onTap: () async {
                          _closeDrawer();
                          await ref.read(authActionsProvider).signOut();
                        },
                      ),
                      _DrawerMenuItem(
                        icon: Icons.delete_forever_outlined,
                        label: AppStrings.deleteAccount,
                        color: theme.colorScheme.error,
                        onTap: () async {
                          _closeDrawer();
                          await _confirmDeleteAccount(context, ref);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main Screen Layer (Slide, Scale & Corner Animation) ──────
          AnimatedBuilder(
            animation: _drawerController,
            builder: (context, child) {
              final value = _drawerController.value;
              final slide = 210.0 * value;
              final scale = 1.0 - (0.12 * value);
              final borderRadius = 24.0 * value;

              return Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: value > 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        child!,
                        if (_isDrawerOpen)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _closeDrawer,
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Menu',
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _drawerController,
                ),
                onPressed: _toggleDrawer,
              ),
              title: const Text(AppStrings.appTitle),
              actions: [
                if (_selectedTab == 0)
                  _DaySwitcher(
                    date: selectedDate,
                    onPrevious: () {
                      ref.read(selectedDateProvider.notifier).state =
                          normalizeDate(
                        selectedDate.subtract(const Duration(days: 1)),
                      );
                    },
                    onNext: () {
                      ref.read(selectedDateProvider.notifier).state =
                          normalizeDate(
                        selectedDate.add(const Duration(days: 1)),
                      );
                    },
                    onToday: () {
                      ref.read(selectedDateProvider.notifier).state =
                          normalizeDate(
                        DateTime.now(),
                      );
                    },
                    onPickDate: (pickedDate) {
                      ref.read(selectedDateProvider.notifier).state =
                          normalizeDate(
                        pickedDate,
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
                if (_isDrawerOpen) _closeDrawer();
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
          ),
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

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAccountTitle),
        content: const Text(AppStrings.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(authActionsProvider).deleteAccount();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.deleteAccountError(e))),
        );
      }
    }
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

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemColor = color ?? theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: itemColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: itemColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
