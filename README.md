<div align="center">

# AWS HUB

### Attendance, Duty Scheduling & Working Scholar Hub

A cross-platform Flutter application designed to centralize duty schedules, attendance tracking, reminders, announcements, birthday updates, and working-scholar utilities.

<br>

[![Deploy MobileSched Web](https://github.com/Emils18/mobileSched/actions/workflows/web.yml/badge.svg)](https://github.com/Emils18/mobileSched/actions/workflows/web.yml)
[![iOS Simulator Build](https://github.com/Emils18/mobileSched/actions/workflows/ios.yml/badge.svg)](https://github.com/Emils18/mobileSched/actions/workflows/ios.yml)
[![AWS HUB iPhone Push Dispatcher](https://github.com/Emils18/mobileSched/actions/workflows/ios-push-dispatch.yml/badge.svg)](https://github.com/Emils18/mobileSched/actions/workflows/ios-push-dispatch.yml)

![Flutter](https://img.shields.io/badge/Flutter-3.38.1-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Version](https://img.shields.io/badge/version-1.3.2%2B5-103F87)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web%20%7C%20iPhone%20PWA-orange)
![Project Identity](https://img.shields.io/badge/Project%20ID-AWSHUB--CORE--2026-103F87)

### [Open AWS HUB Web App](https://emils18.github.io/mobileSched/)

</div>

---

## Overview

**AWS HUB** is a Flutter-based attendance and duty-management application built for working-scholar workflows.

The project combines local attendance tracking, configurable duty schedules, automated reminders, Google Form utilities, Supabase-powered hub content, and cross-platform notification support.

The application currently supports:

- Android
- Web
- iPhone as an installable Progressive Web App
- iOS Simulator builds for testing

---

## Core Features

### Attendance Management

AWS HUB includes local attendance functionality for:

- Time In
- Time Out
- Daily accomplishment recording
- Attendance status calculation
- Attendance history
- Undoing the latest attendance record
- Clearing today's local attendance records

Attendance status can identify conditions such as:

- `ON TIME`
- `LATE`
- `EARLY OUT`
- `LATE OUT`
- `OUTSIDE SCHEDULE`
- `NO DUTY DAY`

Attendance information is stored locally using `SharedPreferences`.

---

### Duty Schedule Management

Users can configure their duty schedule, including:

- Duty days
- Default Time In
- Default Time Out
- Per-day schedule overrides

The saved schedule is used by the attendance and reminder systems.

---

## Reminder System

AWS HUB includes a native reminder engine for supported mobile platforms.

For each configured duty day, the system can schedule reminders around Time In and Time Out.

### Time In reminders

- 15 minutes before Time In
- At Time In
- 10 minutes after
- 20 minutes after
- 30 minutes after

### Time Out reminders

- 15 minutes before Time Out
- At Time Out
- 10 minutes after
- 20 minutes after
- 30 minutes after

Users can configure notification behavior including:

- Notifications enabled/disabled
- Sound
- Vibration
- Persistent notification behavior

The notification system uses device-local timezone information with an `Asia/Manila` fallback.

---

## Hub Updates

AWS HUB connects to Supabase to provide live hub content.

### Announcements

Announcement records support:

- Title
- Summary
- Full body
- Category/tag
- Optional image
- Pinned announcements
- Publication date
- Creation date

Pinned announcements are prioritized before regular announcements.

### Birthday Celebrants

AWS HUB also reads birthday information including:

- Name
- Month
- Department
- Optional profile image

Celebrants are automatically organized by month.

---

## iPhone PWA

AWS HUB can be installed on iPhone as a Progressive Web App.

Production URL:

**https://emils18.github.io/mobileSched/**

For installation:

1. Open AWS HUB using Safari.
2. Tap **Share**.
3. Select **Add to Home Screen**.
4. Open AWS HUB from the newly installed icon.
5. Enable notifications when requested.

The web implementation detects installed iPhone PWA mode before displaying the custom notification permission control.

---

## Push Notification Architecture

### Android / Native

Native notification scheduling is handled through:

- `flutter_local_notifications`
- `flutter_timezone`
- `timezone`

### iPhone PWA

Web push notifications are handled using **OneSignal Web Push**.

The project includes a dedicated root OneSignal service worker:

```text
web/OneSignalSDKWorker.js
```

Duty schedule information is synchronized to OneSignal through compact duty-slot tags:

```text
duty_slot_1
duty_slot_2
...
duty_slot_6
```

Each slot uses the format:

```text
<weekday>@<HH:mm>
```

Example:

```text
1@08:00
```

---

## Automated iPhone Push Dispatcher

AWS HUB contains a GitHub Actions-driven notification dispatcher.

Workflow:

```text
.github/workflows/ios-push-dispatch.yml
```

Dispatcher:

```text
scripts/onesignal_dispatch.py
```

The dispatcher runs on a scheduled GitHub Actions job and handles:

- Duty reminders
- Recent announcements
- Monthly birthday notifications

The OneSignal REST API credential is not stored directly in the dispatcher source. It is expected through the GitHub Actions secret:

```text
ONESIGNAL_REST_API_KEY
```

The scheduled dispatcher currently runs every five minutes.

---

## Google Forms Integration

AWS HUB contains Google Form integration utilities.

Supported workflows include:

- Clock In
- Clock Out
- Daily accomplishment
- Absence/leave forms
- Overtime forms
- Excuse slips

The project supports both direct form submission logic and prefilled form URLs.

Google Form integration can be enabled or disabled locally.

---

## Pending Form Handling

AWS HUB includes a local pending-submission mechanism.

Pending form information can be stored temporarily and recovered using `SharedPreferences`.

This helps preserve an unfinished or pending external form action.

---

## Themes

AWS HUB includes persistent application themes.

Current theme presets include:

- Midnight Navy
- Azure Blue
- Warm Amber
- Cream Light

The selected theme is stored locally and restored between sessions.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Application | Flutter |
| Language | Dart |
| Cloud data | Supabase |
| Web push | OneSignal |
| Native notifications | flutter_local_notifications |
| Local persistence | SharedPreferences |
| HTTP integration | Dart HTTP |
| Web hosting | GitHub Pages |
| Automation | GitHub Actions |
| Forms | Google Forms |
| Web platform | Flutter Web / PWA |

---

## Repository Structure

```text
mobileSched/
│
├── .github/
│   └── workflows/
│       ├── web.yml
│       ├── ios.yml
│       └── ios-push-dispatch.yml
│
├── android/
├── ios/
├── web/
│   ├── index.html
│   └── OneSignalSDKWorker.js
│
├── lib/
│   ├── core/
│   │   └── project_identity.dart
│   │
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── splash_screen.dart
│   │   └── welcome_screen.dart
│   │
│   ├── services/
│   │   ├── attendance_service.dart
│   │   ├── google_form_service.dart
│   │   ├── hub_content_service.dart
│   │   ├── notification_service.dart
│   │   ├── pending_submission_service.dart
│   │   ├── prefilled_form_service.dart
│   │   ├── theme_service.dart
│   │   ├── web_push_profile_service.dart
│   │   ├── web_push_profile_stub.dart
│   │   └── web_push_profile_web.dart
│   │
│   └── widgets/
│       ├── glass_card.dart
│       ├── hub_updates_section.dart
│       ├── premium_button.dart
│       └── status_chip.dart
│
├── scripts/
│   └── onesignal_dispatch.py
│
├── assets/
├── NOTICE.md
├── pubspec.yaml
└── README.md
```

---

## Development

### Requirements

Install:

- Flutter
- Dart
- Git

Verify Flutter:

```bash
flutter doctor
```

Clone the canonical repository:

```bash
git clone https://github.com/Emils18/mobileSched.git
cd mobileSched
```

Install packages:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Analyze the source:

```bash
flutter analyze
```

---

## Build

### Android APK

```bash
flutter build apk --release
```

Expected output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Flutter Web

```bash
flutter build web --release --base-href /mobileSched/
```

### iOS Simulator

```bash
flutter build ios --simulator
```

---

## Continuous Integration & Deployment

### Web Deployment

Workflow:

```text
.github/workflows/web.yml
```

Every push to `main` can:

1. Check out the repository
2. Install Flutter
3. Run `flutter pub get`
4. Run Flutter analysis
5. Build Flutter Web
6. Upload the GitHub Pages artifact
7. Deploy AWS HUB to GitHub Pages

---

### iOS Simulator

Workflow:

```text
.github/workflows/ios.yml
```

The workflow runs against pushes and pull requests targeting `main`.

It:

1. Checks out the project
2. Installs Flutter
3. Resolves dependencies
4. Runs Flutter analysis
5. Builds an iOS Simulator application
6. Compresses `Runner.app`
7. Uploads the simulator build as a GitHub Actions artifact

---

### iPhone Push Automation

Workflow:

```text
.github/workflows/ios-push-dispatch.yml
```

The workflow runs automatically every five minutes and can also be triggered manually through GitHub Actions.

---

# Project Identity & Origin

AWS HUB maintains a permanent project-origin record.

### Original Project Identity

```text
AWS HUB Core Developer
```

### Project Fingerprint

```text
AWSHUB-CORE-2026
```

### Canonical Repository

```text
https://github.com/Emils18/mobileSched
```

The same identity is recorded inside:

```text
NOTICE.md
```

and:

```text
lib/core/project_identity.dart
```

---

## Origin Record

A dedicated origin commit established the project identity record.

### Origin Commit

```text
20c38ca4940ae543e82dc8e05c6286b49a332b5c
```

Commit message:

```text
Establish AWS HUB project identity
```

Record:

https://github.com/Emils18/mobileSched/commit/20c38ca4940ae543e82dc8e05c6286b49a332b5c

---

### Origin Tag

```text
aws-hub-origin-v1
```

The annotated tag points to the AWS HUB project-identity commit.

Tag:

https://github.com/Emils18/mobileSched/releases/tag/aws-hub-origin-v1

---

### Origin Release

GitHub Release:

**AWS HUB Origin v1**

Project fingerprint recorded by the release:

```text
AWSHUB-CORE-2026
```

Release:

https://github.com/Emils18/mobileSched/releases/tag/aws-hub-origin-v1

---

## Authenticity

The canonical AWS HUB origin is associated with:

```text
Repository:
Emils18/mobileSched

Developer Identity:
AWS HUB Core Developer

Project Fingerprint:
AWSHUB-CORE-2026

Origin Commit:
20c38ca4940ae543e82dc8e05c6286b49a332b5c

Origin Tag:
aws-hub-origin-v1
```

Copies, forks, mirrors, or derivative repositories may modify or remove local files.

Removing an origin notice from another copy does not modify the historical records that already exist in the canonical repository.

The authoritative project history is the history maintained by the canonical repository above.

---

## Source & Security

Sensitive credentials should never be committed to the repository.

Private credentials such as server-side API keys should be stored using protected deployment secrets such as GitHub Actions Secrets.

Client-side publishable configuration may exist where required by the application architecture, but privileged or service-role credentials must remain server-side.

If a credential is accidentally exposed, it should be rotated rather than merely removed from a later commit.

---

## Rights

See:

```text
NOTICE.md
```

This repository currently does not declare an open-source license.

Public visibility of the repository does not by itself transfer project authorship or establish the canonical origin of copied versions.

The canonical AWS HUB project-origin record is:

```text
AWS HUB Core Developer
AWSHUB-CORE-2026
Emils18/mobileSched
```

---

## Current Version

```text
1.3.2+5
```

---

<div align="center">

### AWS HUB

**Attendance • Scheduling • Reminders • Scholar Updates**

`AWSHUB-CORE-2026`

Maintained under the project identity:

**AWS HUB Core Developer**

</div>
