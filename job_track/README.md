# JobTrack

JobTrack is a Flutter app for organizing and monitoring your job search. It helps you save applications, track each stage, set reminders for follow-ups, and view progress through a dashboard.

## Screenshots

> Add screenshots here before publishing.

- `assets/screenshots/dashboard.png`
- `assets/screenshots/applications-list.png`
- `assets/screenshots/application-details.png`
- `assets/screenshots/add-application.png`
- `assets/screenshots/settings.png`

## Setup Instructions

### Prerequisites

- Flutter SDK (stable channel)
- Android Studio or Xcode (for platform builds)
- A connected emulator/simulator or physical device

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Run on specific platforms

```bash
flutter run -d android
flutter run -d ios
```

## Features

- Add, edit, and manage job applications
- Dashboard with application progress insights
- Follow-up reminders and notifications
- Onboarding flow for first-time users
- Settings screen with app preferences

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod / Flutter Riverpod
- **Local Storage:** Hive
- **Notifications:** flutter_local_notifications
- **Charts & Analytics:** fl_chart
- **Utilities:** shared_preferences, intl, uuid, share_plus, file_picker, package_info_plus
