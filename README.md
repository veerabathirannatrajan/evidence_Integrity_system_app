<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=220&section=header&text=EvidenceChain&fontSize=80&fontColor=fff&animation=twinkling&fontAlignY=38&desc=Blockchain-Powered%20Digital%20Evidence%20Integrity%20System&descAlignY=58&descSize=18" width="100%"/>

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Storage-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Polygon](https://img.shields.io/badge/Polygon-Amoy_Testnet-8247E5?style=for-the-badge&logo=polygon&logoColor=white)](https://polygon.technology)

<br/>

[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue?style=flat-square)](https://flutter.dev/multi-platform)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![Stars](https://img.shields.io/github/stars/veerabathirannatrajan/evidence_Integrity_system_app?style=flat-square&color=yellow)](https://github.com/veerabathirannatrajan/evidence_Integrity_system_app/stargazers)
[![Backend API](https://img.shields.io/badge/Backend_API-Live_on_Render-46E3B7?style=flat-square&logo=render)](https://evidence-integrity-system-backend.onrender.com)

<br/>

> **A cross-platform Flutter application for tamper-proof digital evidence management.**
> **Every uploaded file is SHA-256 hashed and anchored on the Polygon blockchain —**
> **providing court-admissible, immutable proof of evidence integrity.**

<br/>

[🔗 Backend Repository](https://github.com/veerabathirannatrajan/evidence-backend) &nbsp;·&nbsp;
[📜 Smart Contract on Polygonscan](https://amoy.polygonscan.com/address/0xac93065946CeADe04BD0233552177e33ea1dd651) &nbsp;·&nbsp;
[🐛 Report a Bug](../../issues) &nbsp;·&nbsp;
[✨ Request a Feature](../../issues)

</div>

---

## 📋 Table of Contents

- [📸 App Screenshots](#-app-screenshots)
- [🎯 About the Project](#-about-the-project)
- [✨ Features](#-features)
- [🏗️ Architecture](#️-architecture)
- [🛠️ Tech Stack](#️-tech-stack)
- [📁 Project Structure](#-project-structure)
- [🚀 Getting Started](#-getting-started)
- [⚙️ Configuration](#️-configuration)
- [👥 Role-Based Dashboards](#-role-based-dashboards)
- [🔐 Authentication Flow](#-authentication-flow)
- [📡 API Integration](#-api-integration)
- [🎨 UI Design System](#-ui-design-system)
- [🤝 Contributing](#-contributing)

---

## 📸 App Screenshots

### 🔐 Authentication Screens

<div align="center">
<table>
<tr>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/login.png" width="100%" alt="Login Screen"/>
<br/><br/>
<b>Login Screen</b><br/>
<sub>Firebase email/password authentication with role-based routing</sub>
</td>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/register.png" width="100%" alt="Create Account"/>
<br/><br/>
<b>Create Account</b><br/>
<sub>Register with role selection — Police · Forensic · Prosecutor · Defense · Court</sub>
</td>
</tr>
</table>
</div>

---

### 🖥️ Role-Based Dashboards

<div align="center">
<table>
<tr>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/police_dashboard.png" width="100%" alt="Police Dashboard"/>
<br/><br/>
<b>🚔 Police Dashboard</b><br/>
<sub>Create cases · Upload evidence · Transfer custody to forensic</sub>
</td>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/forensic_dashboard.png" width="100%" alt="Forensic Dashboard"/>
<br/><br/>
<b>🔬 Forensic Dashboard</b><br/>
<sub>Analyse evidence · Upload analysis reports · Transfer to prosecutor</sub>
</td>
</tr>
<tr>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/prosecutor_dashboard.png" width="100%" alt="Prosecutor Dashboard"/>
<br/><br/>
<b>⚖️ Prosecutor Dashboard</b><br/>
<sub>Review evidence · Verify blockchain records · Prepare for trial</sub>
</td>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/defense_dashboard.png" width="100%" alt="Defense Dashboard"/>
<br/><br/>
<b>🛡️ Defense Dashboard</b><br/>
<sub>Examine evidence · Verify authenticity · Challenge tampered records</sub>
</td>
</tr>
<tr>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/court_dashboard.png" width="100%" alt="Court Dashboard"/>
<br/><br/>
<b>🏛️ Court Dashboard</b><br/>
<sub>Full read access · Review all evidence · Confirm chain of custody</sub>
</td>
<td align="center" width="50%">
<!-- placeholder cell for symmetry -->
</td>
</tr>
</table>
</div>

---

### 📂 Evidence Management

<div align="center">
<table>
<tr>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/create_case.png" width="100%" alt="Create Case"/>
<br/><br/>
<b>Create Case</b><br/>
<sub>New investigation with priority, type, location & incident date</sub>
</td>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/upload_evidence.png" width="100%" alt="Upload Evidence"/>
<br/><br/>
<b>Upload Evidence</b><br/>
<sub>Files SHA-256 hashed and anchored on Polygon Amoy blockchain</sub>
</td>
</tr>
<tr>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/evidence_list.png" width="100%" alt="Evidence List"/>
<br/><br/>
<b>Evidence List</b><br/>
<sub>Browse all uploaded evidence grouped by case with blockchain status</sub>
</td>
<td align="center" width="50%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/blockchain_viewer.png" width="100%" alt="Blockchain Viewer"/>
<br/><br/>
<b>Blockchain Viewer</b><br/>
<sub>View TX hash · QR code · Polygonscan link for every evidence file</sub>
</td>
</tr>
</table>
</div>

---

### 🔍 Integrity Verification & Chain of Custody

<div align="center">
<table>
<tr>
<td align="center" width="33%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/verify_evidence.png" width="100%" alt="Verify Evidence"/>
<br/><br/>
<b>Verify Integrity</b><br/>
<sub>Re-upload file to check SHA-256 hash against blockchain record</sub>
</td>
<td align="center" width="33%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/tampered.png" width="100%" alt="Tampered Detection"/>
<br/><br/>
<b>⚠️ Tamper Detected</b><br/>
<sub>Real-time alert when hash mismatch is found — n8n alert triggered</sub>
</td>
<td align="center" width="33%">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/custody_chain.png" width="100%" alt="Custody Chain"/>
<br/><br/>
<b>Chain of Custody</b><br/>
<sub>Full custody timeline from upload to court with hash snapshots</sub>
</td>
</tr>
<tr>
<td align="center" colspan="3">
<img src="https://raw.githubusercontent.com/veerabathirannatrajan/evidence_Integrity_system_app/master/screenshots/transfer_custody.png" width="50%" alt="Transfer Custody"/>
<br/><br/>
<b>Transfer Custody</b><br/>
<sub>Transfer evidence to another role with reason, notes & hash snapshot at time of handoff</sub>
</td>
</tr>
</table>
</div>

---

## 🎯 About the Project

**EvidenceChain** brings **blockchain-level integrity** to the entire digital evidence lifecycle — from the moment a police officer uploads a crime scene photo, to the moment a court official reviews it at trial.

### The Problem It Solves

Digital evidence is vulnerable. Files can be modified, deleted, or tampered with at any point in the chain. Without a tamper-proof audit trail, evidence loses its legal credibility. Traditional systems rely purely on trust. **EvidenceChain eliminates that dependency.**

### The Solution

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│  Officer uploads file                                                │
│         ↓                                                            │
│  SHA-256 fingerprint computed from raw file bytes                    │
│         ↓                                                            │
│  File stored in Firebase Storage                                     │
│         ↓                                                            │
│  Hash anchored on Polygon Amoy blockchain  ←  IMMUTABLE FOREVER     │
│         ↓                                                            │
│  TX hash + metadata saved to MongoDB                                 │
│         ↓                                                            │
│  Auto tamper monitor checks every 5 minutes                          │
│         ↓                                                            │
│  Any hash mismatch → instant WhatsApp + Email alert via n8n          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎭 **5 Role-Based Dashboards** | Police · Forensic · Prosecutor · Defense · Court — each uniquely themed and permission-enforced |
| ⛓️ **Blockchain Anchoring** | Every evidence hash anchored on Polygon Amoy with TX hash, timestamp, and Polygonscan QR |
| 🔍 **Integrity Verification** | Re-upload any file to instantly verify tamper status against both MongoDB and blockchain |
| 🔗 **Chain of Custody** | Full visual timeline of every custody transfer with hash snapshots at each handoff |
| 🚨 **Auto Tamper Detection** | Background monitor every 5 minutes + instant alerts via n8n → WhatsApp + Email |
| 🔄 **Retry Anchor** | If anchoring fails on upload, a retry button re-anchors the hash without re-uploading the file |
| 📱 **Truly Cross-Platform** | Android · iOS · Web · Windows · macOS from a single Flutter codebase |
| 🎨 **Glassmorphism UI** | Animated gradient orb backgrounds, BackdropFilter glass cards, role-colour-coded accents |
| 🔐 **Firebase Auth + RBAC** | Email/password login with Firebase custom claims for role enforcement on every API call |
| 📊 **Live Dashboard Stats** | Cases, evidence count, anchor rate, tamper alerts — all pulled live from the backend |

---

## 🏗️ Architecture

```
lib/
│
├── main.dart                      ← App entry, Provider setup, Firebase init
│
├── providers/
│   ├── user_provider.dart         ← uid · email · role · token state
│   └── theme_provider.dart        ← Light/dark theme state
│
├── services/
│   └── api_service.dart           ← All HTTP calls to the Node.js backend
│
└── screens/
    ├── login_screen.dart          ← Firebase sign-in
    ├── register_screen.dart       ← Account creation + role selection
    ├── dashboard_screen.dart      ← Routes to correct dashboard by role
    │
    ├── dashboards/
    │   ├── police_dashboard.dart
    │   ├── forensic_dashboard.dart
    │   ├── prosecutor_dashboard.dart
    │   ├── defense_dashboard.dart
    │   └── court_dashboard.dart
    │
    ├── dashboard_widgets.dart     ← Shared glassmorphism widget library
    ├── dashboard_scaffold.dart    ← Responsive scaffold (GlobalKey drawer fix)
    │
    ├── create_case_screen.dart
    ├── upload_evidence_screen.dart
    ├── evidence_list_screen.dart
    ├── verify_evidence_screen.dart
    ├── blockchain_viewer_screen.dart
    ├── custody_timeline_screen.dart
    └── qr_scanner_screen.dart
```

### State Management

```
Provider
├── UserProvider   →  uid · email · role · isLoggedIn
└── ThemeProvider  →  isDark
```

### Data Flow

```
User Action
    ↓
Screen Widget
    ↓
ApiService.method()  ──  Authorization: Bearer {Firebase ID Token}
    ↓
Node.js REST API  (https://evidence-integrity-system-backend.onrender.com)
    ↓
Response JSON  →  setState()  →  UI Rebuild
```

---

## 🛠️ Tech Stack

| Category | Package / Tool | Purpose |
|---|---|---|
| **Framework** | Flutter 3.x | Cross-platform UI |
| **Language** | Dart 3.x | Business logic |
| **Auth** | `firebase_auth` | Email/password sign-in + ID tokens |
| **State** | `provider` | App-wide reactive state |
| **HTTP** | `http` | REST API calls with Bearer token |
| **File Picker** | `file_picker` | Cross-platform file selection (bytes mode) |
| **QR Generate** | `qr_flutter` | Blockchain TX QR codes per evidence |
| **QR Scan** | `mobile_scanner` | Scan evidence QR codes |
| **Firebase** | `firebase_core` | Firebase SDK initialisation |
| **UI Effects** | `dart:ui` `BackdropFilter` | Glassmorphism blur cards |

---

## 📁 Project Structure

```
evidence_Integrity_system_app/
│
├── 📱 android/                   ← Android native configuration
├── 🍎 ios/                       ← iOS native configuration
├── 🌐 web/                       ← Web configuration + index.html
├── 🖥️  windows/                  ← Windows configuration
│
├── 📁 lib/
│   ├── main.dart
│   ├── providers/
│   ├── services/
│   └── screens/
│
├── 📁 screenshots/               ← 15 app screenshots (used in this README)
│   ├── login.png
│   ├── register.png
│   ├── police_dashboard.png
│   ├── forensic_dashboard.png
│   ├── prosecutor_dashboard.png
│   ├── defense_dashboard.png
│   ├── court_dashboard.png
│   ├── create_case.png
│   ├── upload_evidence.png
│   ├── evidence_list.png
│   ├── blockchain_viewer.png
│   ├── verify_evidence.png
│   ├── tampered.png
│   ├── custody_chain.png
│   └── transfer_custody.png
│
├── 📋 pubspec.yaml
├── 📋 pubspec.lock
├── 📋 analysis_options.yaml
└── 📋 README.md
```

---

## 🚀 Getting Started

### Prerequisites

Before you begin, make sure you have:

- **Flutter SDK 3.x** → [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** or **VS Code** with Flutter + Dart extensions
- A **Firebase project** with **Authentication** (Email/Password) and **Storage** enabled
- The **[EvidenceChain Backend](https://github.com/veerabathirannatrajan/evidence-backend)** running locally or on Render

### Step 1 — Clone the Repository

```bash
git clone https://github.com/veerabathirannatrajan/evidence_Integrity_system_app.git
cd evidence_Integrity_system_app
```

### Step 2 — Install Dependencies

```bash
flutter pub get
```

### Step 3 — Connect Firebase

```bash
# Install the FlutterFire CLI (one-time setup)
dart pub global activate flutterfire_cli

# Auto-generate lib/firebase_options.dart for your project
flutterfire configure
```

Select your Firebase project when prompted. This creates `lib/firebase_options.dart` automatically.

### Step 4 — Set the Backend URL

Open `lib/services/api_service.dart` and update:

```dart
// 🔧 Local development
static const String _baseUrl = 'http://localhost:5000';

// 🚀 Production (Render)
static const String _baseUrl = 'https://evidence-integrity-system-backend.onrender.com';
```

### Step 5 — Run the App

```bash
# Android (with device connected or emulator running)
flutter run

# Web (Chrome)
flutter run -d chrome

# Windows Desktop
flutter run -d windows

# Show all available devices
flutter devices
```

### Step 6 — Build for Production

```bash
# Android APK (direct install)
flutter build apk --release

# Android App Bundle (Play Store upload)
flutter build appbundle --release

# Web (output to build/web/)
flutter build web --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## ⚙️ Configuration

### Android — File & Camera Permissions

Add inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- File access — Android 12 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<!-- File access — Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

<!-- Camera — for QR scanning -->
<uses-permission android:name="android.permission.CAMERA"/>
```

### iOS — Privacy Descriptions

Add inside `<dict>` in `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>EvidenceChain needs access to upload evidence files from your photo library</string>

<key>NSCameraUsageDescription</key>
<string>EvidenceChain needs camera access to scan QR codes</string>

<key>NSDocumentsFolderUsageDescription</key>
<string>EvidenceChain needs access to select evidence documents</string>
```

### Core Dependencies — `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.x
  firebase_auth: ^4.x

  # State Management
  provider: ^6.x

  # Networking
  http: ^1.x

  # File Operations
  file_picker: ^6.x

  # QR Code
  qr_flutter: ^4.x
  mobile_scanner: ^3.x
```

---

## 👥 Role-Based Dashboards

### Transfer Permission Hierarchy

```
  🚔 POLICE ──────────────────────────────────────────► 🔬 FORENSIC
       │                                                      │
       └──────────────────────────────────────────────► ⚖️ PROSECUTOR
                                                              │
                                                    ┌─────────┴────────┐
                                                    ▼                  ▼
                                               🏛️ COURT          🛡️ DEFENSE
                                                                       │
                                                                       ▼
                                                                  🏛️ COURT
```

### Role Permissions Table

| Role | Accent Colour | Upload | Transfer To | Verify |
|---|---|:---:|---|:---:|
| 🚔 **Police** | Indigo `#4F46E5` | ✅ | Forensic, Prosecutor | ✅ |
| 🔬 **Forensic** | Purple `#7C3AED` | ✅ | Prosecutor, Court | ✅ |
| ⚖️ **Prosecutor** | Green `#059669` | ❌ | Court, Defense | ✅ |
| 🛡️ **Defense** | Blue `#0284C7` | ❌ | Court | ✅ |
| 🏛️ **Court** | Amber `#D97706` | ❌ | — | ✅ |

### What Every Dashboard Shows

All 5 dashboards display the same real-time stat cards:

| Stat | Description |
|---|---|
| **Active Cases** | Open investigation cases count |
| **Evidence Uploaded** | Total files on record |
| **Blockchain Anchored** | Anchored vs total ratio |
| **Tamper Alerts** | Compromised evidence count |
| **Recent Activity** | Live upload + transfer feed |
| **Blockchain Status** | Polygon Amoy live network indicator |

---

## 🔐 Authentication Flow

```
Flutter App                   Firebase Auth                Backend API
───────────                   ─────────────                ───────────

1. User taps Sign In
        ↓
2. signInWithEmailAndPassword ────────────►
                              returns idToken
                              ◄────────────
3. Force token refresh ───────────────────►
   (to get role claim)        new token with
                              { role: "police" }
                              ◄────────────
4. Store token in UserProvider

5. Every API call ──── Authorization: Bearer {token} ─────────►
                                                     verifyIdToken()
                                                     extracts role
                                                     ◄─────────────
6. Response JSON → setState() → UI renders correct dashboard
```

**First-time login** — after Firebase sign-up, the app calls `POST /api/user/create` which sets the Firebase custom claim `{ role: "police" }` and forces a token refresh so the role is available immediately.

---

## 📡 API Integration

All backend communication is centralised in `lib/services/api_service.dart`.

### Methods Reference

```dart
// ── Authentication ─────────────────────────────────────────────
createUser(uid, email, role, name)       // POST /api/user/create
getMe()                                  // GET  /api/user/me

// ── Cases ──────────────────────────────────────────────────────
getAllCases()                            // GET  /api/cases
createCase(title, desc, {...})           // POST /api/cases
getDashboardStats()                      // GET  /api/evidence/stats

// ── Evidence ───────────────────────────────────────────────────
uploadEvidenceBytes(bytes, name, caseId) // POST /api/evidence/upload
verifyEvidenceBytes(bytes, name, evId)   // POST /api/evidence/verify
getEvidenceByCase(caseId)               // GET  /api/evidence/case/:id
getRecentEvidence({limit})              // GET  /api/evidence/recent/:limit
retryAnchor(evidenceId)                 // POST /api/evidence/anchor/:id

// ── Dashboard ──────────────────────────────────────────────────
getRecentActivity()                     // GET  /api/evidence/recent-activity

// ── Chain of Custody ───────────────────────────────────────────
getCustodyHistory(evidenceId)           // GET  /api/custody/history/:id
getAllowedRoles()                        // GET  /api/custody/allowed-roles
transferCustody(evId, toUser, reason)   // POST /api/custody/transfer
```

### Cross-Platform File Upload (Bytes Mode)

Files are loaded as `Uint8List` — no file path needed. This is the key to making uploads work on **Web and Windows** as well as mobile:

```dart
// Pick file — withData: true loads bytes into memory
final result = await FilePicker.platform.pickFiles(
  type: FileType.any,
  withData: true,          // ← critical for web/windows
  allowMultiple: false,
);

final bytes    = result.files.first.bytes;   // Uint8List — no path needed
final fileName = result.files.first.name;

// Upload as multipart form
final request = http.MultipartRequest('POST', uri);
request.files.add(http.MultipartFile.fromBytes(
  'file',
  bytes!,
  filename: fileName,
  contentType: MediaType.parse(mimeType),
));
request.headers['Authorization'] = 'Bearer $token';
final response = await request.send();
```

---

## 🎨 UI Design System

### Core: Glassmorphism Cards

Every card across every screen uses the same `BackdropFilter` glass system:

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(color: Color(0xFF4F46E5).withOpacity(0.07),
          blurRadius: 22, offset: Offset(0, 7)),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.white.withOpacity(0.90),
            Colors.white.withOpacity(0.58),
          ]),
          border: Border.all(
            color: Colors.white.withOpacity(0.65),
            width: 1.3,
          ),
        ),
      ),
    ),
  ),
)
```

### Animated Background Orbs

Every screen has 3 radial gradient orbs that shift slowly on a 9-second loop:

```dart
AnimationController _bgCtrl = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 9),
)..repeat(reverse: true);
```

### Responsive Breakpoints

```dart
const double kMobile = 600;    // < 600px  → single column, drawer on hamburger
const double kTablet = 1024;   // 600–1024 → icon-only sidebar (64px)
                                // > 1024px → full expanded sidebar (240px)
```

### Role Colour System

```dart
Color roleColor(String role) => switch (role) {
  'police'     => const Color(0xFF4F46E5),   // 🟣 Indigo
  'forensic'   => const Color(0xFF7C3AED),   // 🟣 Purple
  'prosecutor' => const Color(0xFF059669),   // 🟢 Green
  'defense'    => const Color(0xFF0284C7),   // 🔵 Blue
  'court'      => const Color(0xFFD97706),   // 🟡 Amber
  _            => const Color(0xFF4F46E5),
};
```

### Role-Specific Welcome Banner Gradients

```
🚔 Police:     #3B4EFF → #2563EB → #4F46E5 → #6D28D9
🔬 Forensic:   #5B21B6 → #6D28D9 → #7C3AED → #4338CA
⚖️ Prosecutor: #065F46 → #047857 → #059669 → #0D9488
🛡️ Defense:    #075985 → #0369A1 → #0284C7 → #0EA5E9
🏛️ Court:      #78350F → #92400E → #B45309 → #D97706
```

---

## 🤝 Contributing

Contributions are always welcome!

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make** your changes
4. **Test** on at least one platform
   ```bash
   flutter test
   flutter analyze
   ```
5. **Commit** with a clear message
   ```bash
   git commit -m "feat: add your feature description"
   ```
6. **Push** to your fork
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open** a Pull Request

### Useful Commands

```bash
# Run with hot reload
flutter run

# Run on web (best for UI iteration)
flutter run -d chrome

# Run static analysis
flutter analyze

# Format all Dart files
dart format lib/

# Check for outdated dependencies
flutter pub outdated

# Clean build cache
flutter clean && flutter pub get
```

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=120&section=footer" width="100%"/>

<br/>

**Built with ❤️ by [veerabathirannatrajan](https://github.com/veerabathirannatrajan)**

<br/>

[![GitHub stars](https://img.shields.io/github/stars/veerabathirannatrajan/evidence_Integrity_system_app?style=social)](https://github.com/veerabathirannatrajan/evidence_Integrity_system_app/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/veerabathirannatrajan/evidence_Integrity_system_app?style=social)](https://github.com/veerabathirannatrajan/evidence_Integrity_system_app/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/veerabathirannatrajan/evidence_Integrity_system_app?style=social)](https://github.com/veerabathirannatrajan/evidence_Integrity_system_app/watchers)

<br/>

*EvidenceChain — Where every byte of evidence is accounted for, forever.*

</div>
