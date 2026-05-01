<p align="center">
  <img src="assets/images/app_logo.png" width="120" height="120" alt="Rootine Logo" />
</p>

<h1 align="center">Rootine</h1>

<p align="center">
  <strong>Transform your life, one habit at a time.</strong><br />
  A premium habit-building and tracking application built with Flutter, Firebase, and Riverpod.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=firebase" alt="Firebase" />
  <img src="https://img.shields.io/badge/Material_3-7B1FA2?style=for-the-badge&logo=material-design&logoColor=white" alt="Material 3" />
</p>

---

## ✨ Overview

Rootine is designed to help you build consistency and achieve your long-term goals through a simple yet powerful habit-tracking experience. Whether you want to drink more water, read daily, or hit the gym, Rootine provides the tools to stay on track and visualize your progress.

## 🚀 Features

### 🔐 Authentication
- **Secure Sign-In**: Support for Google Sign-In and Email/Password authentication.
- **Unified Auth Gate**: Seamless transition between login and the main app experience.

### 📅 Habit Management
- **Flexible Frequencies**: 
  - **Daily**: For habits you want to perform every single day.
  - **Weekly**: Choose specific days of the week.
  - **Monthly**: Pick a specific day of the month.
  - **Intervals**: Recurring every `n` days.
- **Categorization**: Organize your habits into categories for better focus.
- **Archiving**: Archive completed or paused habits to keep your dashboard clean.

### 📊 Tracking & Analytics
- **Day Switcher**: Easily navigate through different days to update completion status.
- **Insightful Stats**: 
  - Real-time completion rates (Today, Last 7 Days, Last 30 Days).
  - Streak tracking to keep your momentum high.
  - Visual data representation using `fl_chart`.

### ⚙️ Advanced Features
- **Remote Config**: Dynamic application updates via Firebase Remote Config.
- **Offline Fallback**: In-memory repository support for development without Firebase connectivity.
- **Swipe Actions**: Quickly manage habits with intuitive slide-to-complete or delete actions.

## 🏗️ Architecture

Rootine follows **Clean Architecture** principles to ensure maintainability and scalability:

- **Domain Layer**: Core business logic and entities (Habits, Completions).
- **Data Layer**: Repository implementations, Firestore integration, and local storage.
- **Application Layer**: Business logic for habit tracking and statistics.
- **Presentation Layer**: Material 3 UI components, Riverpod state management, and responsive layouts.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod 2.x](https://riverpod.dev/)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth, Firestore, Remote Config)
- **UI Components**: Material 3, `flutter_slidable`
- **Charts**: `fl_chart`
- **Local Storage**: `shared_preferences`

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (v3.10.3 or higher)
- Dart SDK
- Firebase account

### Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/dharmikRokad/rootine.git
   cd rootine
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**:
   - Create a project in the [Firebase Console](https://console.firebase.google.com/).
   - Add your Android/iOS/Web apps.
   - Run the FlutterFire CLI:
     ```bash
     flutterfire configure
     ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## 📂 Project Structure

```text
lib/
├── core/             # Shared utilities, themes, and services
├── features/
│   ├── auth/         # Authentication logic and pages
│   └── habits/       # Habit core logic, domain, and UI
└── main.dart         # Entry point
```

---

<p align="center">
  Built with ❤️ for better habits
</p>
