# Sadhana App — Setup Guide

## Step 1: Install Flutter

1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter`
3. Add to PATH: `C:\flutter\bin`
4. Run `flutter doctor` in terminal — fix any issues shown

## Step 2: Install dependencies

```bash
cd d:\IYF\sadhna\sadhana_app
flutter pub get
```

## Step 3: Set up Firebase

1. Go to https://console.firebase.google.com
2. Create a new project (e.g., "sadhana-app")
3. Enable these services:
   - Authentication → Sign-in methods → Enable **Google**
   - Firestore Database → Create database
   - Storage → Get started
   - Cloud Messaging (auto-enabled)

4. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This auto-generates `lib/firebase_options.dart` with your real keys.

5. Download `google-services.json` from Firebase Console → Project Settings → Android app,
   and place it at: `android/app/google-services.json`

## Step 4: Set up Razorpay

1. Create account at https://razorpay.com
2. Get your Key ID from Dashboard → Settings → API Keys
3. Replace `YOUR_RAZORPAY_KEY_ID` in:
   `lib/features/donations/screens/donations_screen.dart` (line with `'key':`)

## Step 5: Set up Firestore Rules

In Firebase Console → Firestore → Rules, paste:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /sadhana/{entryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if false; // admin only via Firebase Console
    }
    match /content/{itemId} {
      allow read: if request.auth != null;
      allow write: if false; // admin only
    }
    match /donations/{donationId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

## Step 6: Add Fonts (optional but recommended)

Download Poppins font from https://fonts.google.com/specimen/Poppins and place in:
```
assets/fonts/
  Poppins-Regular.ttf
  Poppins-Medium.ttf
  Poppins-SemiBold.ttf
  Poppins-Bold.ttf
```

Or remove the `fonts:` section from `pubspec.yaml` to use the system font.

## Step 7: Run the app

```bash
flutter run
```

## Adding Content (Admin)

Use Firebase Console to add content to Firestore:

**Events collection** (`events`):
```json
{
  "title": "Janmashtami Celebration",
  "description": "Grand festival...",
  "startDate": <Timestamp>,
  "endDate": <Timestamp>,
  "location": "ISKCON Temple",
  "liveStreamUrl": "https://youtube.com/...",
  "isLive": false,
  "isFree": true,
  "registeredCount": 0
}
```

**Content collection** (`content`):
```json
{
  "title": "BG Chapter 1 Lecture",
  "subtitle": "HH Radhanath Swami",
  "type": "lecture",
  "contentUrl": "https://...",
  "durationSeconds": 3600,
  "createdAt": <Timestamp>
}
```
Types: `lecture`, `kirtan`, `book`

## App Structure

```
lib/
├── main.dart                    ← App entry point
├── firebase_options.dart        ← Firebase config (auto-generated)
├── core/
│   ├── constants/               ← Colors, strings
│   ├── theme/                   ← App theme
│   └── routes/                  ← Navigation (go_router)
└── features/
    ├── auth/                    ← Google Sign-in, Splash, Login
    ├── home/                    ← Dashboard + bottom navigation
    ├── sadhana/                 ← Daily practice tracker
    ├── content/                 ← Gita, Lectures, Kirtans, Books
    ├── events/                  ← Events + Live streaming
    ├── donations/               ← Razorpay donations
    └── profile/                 ← User profile + settings
```
