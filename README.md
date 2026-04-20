# Habitz

Habitz is a simple but powerful habit builder and tracker app built with Flutter,
Firebase, and Riverpod. It helps users build consistency with recurring habits
and gives clear statistics on daily, weekly, and monthly performance.

## Implemented Features

- Create habits with these frequencies:
	- Daily
	- Weekly (specific weekday)
	- Monthly (specific day of month)
	- Recurring every n days
- Track completion by date
- Browse and update completion state per day
- View statistics:
	- Today completion rate
	- Last 7 days completion rate
	- Last 30 days completion rate
	- Best active streak

## Tech Stack

- Flutter (Material 3)
- Riverpod for state management
- Firebase Core + Cloud Firestore for persistence
- In-memory repository fallback when Firebase is not configured

## Run Locally

1. Install dependencies:
	 flutter pub get
2. Run the app:
	 flutter run

If Firebase is not configured yet, the app will still run using local in-memory
data for development.

## Firebase Setup

1. Create a Firebase project.
2. Add your Flutter apps (Android/iOS/web as needed).
3. Configure Firestore in the Firebase console.
4. Run FlutterFire CLI to generate platform-specific config:
	 flutterfire configure
5. Update app initialization to use generated options (if needed for your setup).

## Firestore Data Model

- habits/{habitId}
	- name: string
	- frequency: daily|weekly|monthly|interval
	- createdAt: int (millisecondsSinceEpoch)
	- intervalDays: int?
	- anchor: int?
	- archived: bool

- completions/{habitId_yyyy-MM-dd}
	- habitId: string
	- date: yyyy-MM-dd
	- completedAt: int (millisecondsSinceEpoch)
