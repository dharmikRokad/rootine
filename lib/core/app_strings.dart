class AppStrings {
  static const appTitle = 'Rootine';

  static const manageCategories = 'Manage categories';
  static const archivedHabits = 'Archived habits';
  static const appearance = 'Appearance';
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const themeSystem = 'System';
  static const signOut = 'Sign out';
  static const deleteAccount = 'Delete Account';
  static const deleteAccountTitle = 'Delete account?';
  static const deleteAccountMessage =
      'This will permanently delete your account and all your habit data. This action cannot be undone.';
  static String deleteAccountError(Object error) =>
      'Could not delete account: $error';
  static const signInWithGoogle = 'Sign in with Google';
  static const signingIn = 'Signing in...';
  static const welcomeTo = 'Welcome to';
  static const nijDarshan = 'Rootine';
  static const welcomeSubtitle =
      'Build streaks, track consistency, and sync your progress securely with Firebase.';
  static const authenticationError = 'Authentication error';

  static const track = 'Track';
  static const stats = 'Stats';
  static const newHabit = 'New Habit';
  static const today = 'Today';
  static const previousDay = 'Previous day';
  static const nextDay = 'Next day';

  static const signedOut = 'Signed out';
  static const signInRequired = 'Sign-in required';
  static const signedIn = 'Signed in';
  static const userPrefix = 'User ';

  static const couldNotLoad = 'Could not load';
  static const categories = 'categories';
  static const habits = 'habits';
  static const completions = 'completions';
  static const statsNoun = 'stats';
  static const details = 'details';
  static const archived = 'archived';
  static const achievements = 'achievements';
  static const authentication = 'authentication';

  static String couldNotLoadMessage(String subject, Object error) {
    return '$couldNotLoad $subject: $error';
  }

  static String authenticationErrorMessage(Object error) {
    return '$authenticationError: $error';
  }

  static const createHabit = 'Create Habit';
  static const editHabit = 'Edit Habit';
  static const habitName = 'Habit name';
  static const category = 'Category';
  static const categoryName = 'Category name';
  static const noCategory = 'No category';
  static const addCategory = 'Add category';
  static const frequency = 'Frequency';
  static const everyNDays = 'Every n days';
  static const weekday = 'Weekday';
  static const dayOfMonth = 'Day of month:';
  static const saveHabit = 'Save Habit';
  static const saveChanges = 'Save Changes';
  static const pleaseEnterHabitName = 'Please enter a habit name';

  static const createCategory = 'Create category';
  static const renameCategory = 'Rename category';
  static const manageCategoriesTitle = 'Manage Categories';
  static const newCategory = 'New Category';
  static const defaultCategory = 'Default category';
  static const customCategory = 'Custom category';
  static const slideForActions = 'Slide for actions';
  static const noCategoriesYet =
      'No categories yet. Create one to get started.';

  // Frequency labels
  static const frequencyLabelDaily = 'Daily';
  static const frequencyLabelWeekly = 'Weekly';
  static const frequencyLabelMonthly = 'Monthly';
  static String frequencyLabelEveryNDays(int n) => 'Every $n days';
  static String frequencyLabelWeeklyOn(String day) => 'Weekly on $day';
  static String frequencyLabelMonthlyOn(int day) => 'Monthly on day $day';

  // Weekday names (Monday = 1 … Sunday = 7)
  static const weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const weekdayNamesShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Category subtitles
  static const categorySubtitleDefault = 'Default category';
  static const categorySubtitleCustom = 'Custom category · Slide for actions';

  // Action labels
  static const rename = 'Rename';
  static const edit = 'Edit';
  static const archive = 'Archive';

  static const archivedHabitsTitle = 'Archived Habits';
  static const noArchivedHabitsYet = 'No archived habits yet.';
  static const restore = 'Restore';
  static const delete = 'Delete';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const create = 'Create';
  static const deleteHabitTitle = 'Delete habit?';
  static const deleteCategoryTitle = 'Delete category?';
  static String deleteHabitMessage(String name) {
    return 'Delete "$name" and all of its completion history?';
  }

  static String deleteHabitPermanentlyMessage(String name) {
    return 'Delete "$name" permanently?';
  }

  static String deleteCategoryMessage(String name) {
    return 'Delete "$name"? Habits in this category will keep working but without a category.';
  }

  static const addCompletionNote = 'Add completion note';
  static const editNote = 'Edit note';
  static const completionNote = 'Completion Note';
  static const saveNote = 'Save Note';
  static const todaysNote = "Today's Note";
  static const noNoteForDay =
      'No note for this day yet. Tap the note icon to add one.';
  static const note = 'Note';

  static String noteForDateLabel(String date) => 'Note for $date';
  static String checkInsLabel(int count) => '$count check-ins';

  static const currentStreak = 'Current\nStreak';
  static const bestStreak = 'Best Streak';
  static const last30DaysAdherence = 'Last 30 Days Adherence';
  static const streakHistory30Days = 'Streak History (30 days)';
  static const streakHistory30DaysDesc =
      'Consecutive days you completed this habit, tracked over the last 30 days.';
  static const missedDayHeatmap12Weeks = 'Missed-day Heatmap (12 weeks)';
  static const missedDayHeatmap12WeeksDesc =
      'Visual overview of completed, missed, and unscheduled days over the past 12 weeks.';
  static const frequencyAdherenceWeekly = 'Frequency Adherence (Weekly)';
  static const frequencyAdherenceWeeklyDesc =
      'Completed vs. scheduled check-ins grouped by week.';
  static const habitAchievements = 'Habit Achievements';
  static const completionNotes = 'Completion Notes';
  static const completed = 'Completed';
  static const missed = 'Missed';
  static const notScheduled = 'Not scheduled';
  static const noNotesYet = 'No notes yet. Tap the note icon to add one.';

  static const todayLabel = 'Today';
  static const last7Days = 'Last 7 Days';
  static const last30Days = 'Last 30 Days';
  static const consistencyScore = 'Consistency Score';
  static const bestDayOfWeek = 'Best Day of Week';
  static const momentum = 'Momentum';
  static const bestActiveStreak = 'Best Active Streak';
  static const milestones = 'Milestones';
  static const completionTrend14Days = '14-Day Completion Trend';
  static const completionTrend14DaysDesc =
      'Daily completion rate across all habits over the last 14 days.';
  static const last7DaysOutput = 'Last 7 Days Output';
  static const last7DaysOutputDesc =
      'Number of completed vs. scheduled habit check-ins for each day this week.';
  static const rolling7DayAdherence = 'Rolling 7-Day Adherence';
  static const rolling7DayAdherenceDesc =
      'Your 7-day completion rate rolling through time — shows momentum trends.';
  static const weekdayWinRate = 'Weekday Win Rate';
  static const weekdayWinRateDesc =
      'Your average completion rate for each day of the week.';
  static const ratesCountOnlyScheduledDays =
      'Rates count only days where a habit was scheduled.';

  static const noHabitsForThisDate =
      'No habits for this date yet.\nTap New Habit to add one.';
  static const all = 'All';
  static const deleteHabitQuestion = 'Delete habit?';

  static const pts = 'pts';
  static const at = 'at';

  static const excellent = 'excellent';
  static const strong = 'strong';
  static const improving = 'improving';
  static const buildingMomentum = 'building momentum';

  static const strongUpwardTrend = 'Strong upward trend';
  static const improvingSteadily = 'Improving steadily';
  static const recentDipAdjust = 'Recent dip, adjust schedule';
  static const slightlyDownWeek = 'Slightly down this week';
  static const stableComparedLastWeek = 'Stable compared to last week';
  static const vsPreviousWeek = 'vs previous week';

  static String todayCompletedLabel(int completed, int total, String rate) =>
      '$completed/$total completed ($rate%)';

  static String completionRateLabel(String rate) => '$rate% completion rate';

  static String vsPreviousWeekLabel(String delta, String prevRate) =>
      '$delta vs previous week ($prevRate%)';

  static String scheduledCheckInsLabel(int completed, int total) =>
      '$completed/$total scheduled check-ins completed';

  static String activeHabitsLabel(int count) => '$count active habits tracked';

  static String bestStreakInARowLabel(int count) => '$count check-ins in a row';

  static String achievementUnlockedLabel(int count) =>
      '$count achievement${count == 1 ? '' : 's'} unlocked';

  static String newAchievementUnlockedLabel(int count) =>
      '$count new achievement${count == 1 ? '' : 's'} unlocked';

  static const categoryHealth = 'Health';
  static const categoryFitness = 'Fitness';
  static const categoryLearning = 'Learning';
  static const categoryWork = 'Work';
  static const categoryMindfulness = 'Mindfulness';
  static const categoryPersonal = 'Personal';
  static const categoryFinance = 'Finance';

  // ── Remote Config ───────────────────────────────────────────────
  static const remoteConfigDefaultCategoriesKey = 'default_habit_categories';

  // ── Internal error messages ───────────────────────────────────────
  static const remoteConfigProviderNotOverridden =
      'remoteConfigServiceProvider must be overridden in ProviderScope';
  static const userMustBeAuthenticated =
      'User must be authenticated before loading habits.';
  static const habitNotFound = 'Habit not found';
}
