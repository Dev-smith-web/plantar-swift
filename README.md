# PlantAR

An augmented reality plant education app for iOS. Students scan physical plant reference cards with their iPhone camera to trigger interactive 3D AR models. Each model supports part-level tapping (Stem, Root, Leaves, Flowers) to display educational information. A teacher dashboard tracks student engagement and scan analytics across the class.

Built as a University of North Texas CSSE 4901 Capstone project by Team Tier1X.

---

## Features

- AR image tracking — point camera at a reference card to load a 3D plant model
- Part-tap anatomy labels — tap any plant part to see its biological function
- 6 plants with full AR support: Rose, Orchid, Lilium, African Daisy, Sunflower, Mustard
- Plant library with search, bloom season bars, and hardiness zone maps
- Quiz system per plant
- Garden (life list) with cross-device sync via Firebase
- Teacher dashboard — live student scan counts, quiz scores, class analytics
- Daily Plant of the Day notification (9 AM)
- Location-aware plant suggestions

---

## Requirements

- iPhone running **iOS 26.2 or later**
- Mac with **Xcode 16+**
- Free Apple ID (no paid developer account needed)
- USB cable to connect iPhone to Mac
- **Developer Mode** enabled on iPhone: Settings → Privacy & Security → Developer Mode → ON
- Internet connection on first launch (Firebase Auth + Firestore sync)
- Printed plant reference cards (10 cm × 14 cm) for AR scanning

---

## Dependencies

| Dependency | Version | Source |
|---|---|---|
| Swift | 5.0 | Built-in |
| RealityKit | iOS 26.2+ | Built-in |
| ARKit | iOS 26.2+ | Built-in |
| SwiftUI | iOS 26.2+ | Built-in |
| firebase-ios-sdk (FirebaseAuth + FirebaseFirestore) | 11.6.0 | Swift Package Manager — resolved automatically by Xcode |
| Perenual Plant API | v2 | External — API key in `Info.plist` |

---

## Getting Started

### 1. Clone and open

```bash
git clone https://github.com/Dev-smith-web/plantar-swift.git
```

Open `PlantAR/PlantAR.xcodeproj` in Xcode. Wait for Xcode to finish downloading the Firebase Swift Package dependencies (1–2 minutes — watch the status bar).

### 2. Connect your iPhone

Connect your iPhone via USB. When the iPhone prompts **"Trust This Computer?"**, tap **Trust** and enter your passcode. Select your iPhone as the target device in the Xcode toolbar.

### 3. Sign with your Apple ID

In Xcode: select the **PlantAR** project → **Signing & Capabilities** → set **Team** to your personal Apple ID.

### 4. Run

Press **▶ Run**. Xcode compiles and installs the app on your iPhone. If prompted on the iPhone, go to **Settings → General → VPN & Device Management** and trust the developer certificate.

### 5. Re-signing (every 7 days)

Free Apple ID provisioning profiles expire every 7 days. Reconnect the iPhone and press **▶ Run** again — app data is fully preserved.

---

## First-Time Setup

### Teacher
1. Open PlantAR → **I'm a Teacher**
2. Register with email and password
3. A unique class code is automatically generated — share it with students

### Student
1. Open PlantAR → **I'm a Student**
2. Register with email, password, and the class code from your teacher

---

## Using AR

1. Open the **AR tab**
2. Point the camera at a printed reference card (10 cm × 14 cm)
3. The 3D plant model appears anchored to the card
4. Tap individual parts (Stem, Root, Leaves, Flowers) to view educational info
5. Scan records sync automatically to Firebase

---

## Project Structure

```
plantar-swift/
└── PlantAR/
    ├── PlantAR.xcodeproj/
    └── PlantAR/
        ├── PlantARApp.swift              # App entry point
        ├── Plant_Universal.swift         # Plant database and data models
        ├── OptimizedARManager.swift      # AR session, image tracking, model loading
        ├── PersistenceService.swift      # Firebase Firestore read/write
        ├── AuthService.swift             # Student Firebase Auth
        ├── TeacherAuthService.swift      # Teacher Firebase Auth
        ├── MainTabView.swift             # Root tab navigation
        ├── TeacherDashboardView.swift    # Teacher analytics dashboard
        ├── MerlinStylePlantInfoSheet.swift # Plant info overlay (5 tabs)
        ├── QuizView.swift / QuizQuestionCard.swift / QuizResultsView.swift
        ├── PlantAPIService.swift         # Perenual API integration
        ├── Info.plist                    # App config and API key
        ├── GoogleService-Info.plist      # Firebase project config
        ├── *.usdz                        # 6 plant 3D models
        └── Assets.xcassets/
            └── PlantCards.arresourcegroup/  # 6 AR reference card images
```

---

## Firebase

The Firebase project is pre-configured — `GoogleService-Info.plist` is bundled in the app. No manual Firebase setup is needed. Firestore collections are created automatically on first sign-up.

```
users/{uid}         → email, classCode, scannedPlants
teachers/{uid}      → email, classCode, students[]
```

---

## Notes

- The Perenual API key is stored in `Info.plist` (`PerenualAPIKey`). Rotate before any public distribution.
- AR reference card images are sourced from Wikipedia Commons — replace with final card artwork before launch.
- 15 plants in the library do not have USDZ models — AR is silently skipped for those.
