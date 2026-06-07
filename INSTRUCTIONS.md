# 🏛️ AI-SCRMS Flutter App

AI-Powered Smart Campus Resource Management System — **Flutter cross-platform app**

---

## 📋 What's Included

| Feature | Status |
|---------|--------|
| Login / Register | ✅ |
| Role-based navigation (Admin, Faculty, Student, Maintenance) | ✅ |
| Browse & filter resources (date, time, type, capacity) | ✅ |
| Book resources with conflict detection | ✅ |
| Auto waitlist with AI priority scoring | ✅ |
| QR code generation for bookings | ✅ |
| QR scanner for check-in | ✅ |
| My Bookings (Upcoming / Past / Cancelled) | ✅ |
| Notifications with unread badge | ✅ |
| Analytics dashboard with charts | ✅ |
| AI demand forecast | ✅ |
| Maintenance request & resolution | ✅ |
| Admin: All Bookings, Manage Resources, Users, Audit Ledger | ✅ |

---

## ⚡ Prerequisites

### 1. Flutter SDK
Install from: https://docs.flutter.dev/get-started/install

```bash
# Verify installation
flutter doctor
```

### 2. Backend (XAMPP)
The app requires the original PHP backend running locally or on a server.

1. Install XAMPP: https://www.apachefriends.org/
2. Start **Apache** and **MySQL**
3. Copy the `backend/` folder (included in this zip) to your XAMPP `htdocs/ai_scrms/`
4. Open `http://localhost/phpmyadmin`
5. Click **Import** → select `backend/database.sql` → **Go**
6. Visit `http://localhost/ai_scrms/` to verify the backend works

---

## 🚀 Running the App

### In VS Code (Recommended)

1. **Open the project folder** in VS Code:
   ```
   File → Open Folder → select `ai_scrms_flutter/`
   ```

2. **Install the Flutter extension** if not already:
   - Extensions panel → search "Flutter" → Install

3. **Get dependencies**:
   ```bash
   flutter pub get
   ```

4. **Select a device** (bottom right of VS Code):
   - Android emulator, iOS simulator, Chrome, or Windows/macOS/Linux desktop

5. **Run the app**:
   ```
   Press F5   OR   Run → Start Debugging
   ```
   
   Or via terminal:
   ```bash
   # Mobile
   flutter run
   
   # Chrome (web)
   flutter run -d chrome
   
   # Windows desktop
   flutter run -d windows
   
   # macOS desktop
   flutter run -d macos
   ```

### Command Line

```bash
cd ai_scrms_flutter

# Install dependencies
flutter pub get

# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Build APK for Android
flutter build apk --release

# Build for iOS (requires macOS + Xcode)
flutter build ios --release

# Build for web
flutter build web --release
```

---

## ⚙️ Configuring the Backend URL

The app defaults to `http://localhost/ai_scrms`.

**To connect to a different server:**

### In the App (easiest)
1. On the login screen, scroll down and tap **⚙️ Server Settings**
2. Enter your backend URL, e.g., `http://192.168.1.100/ai_scrms`
3. Tap **Save URL**

### For Android Emulator
Use `http://10.0.2.2/ai_scrms` (maps to host machine localhost)

### For Physical Device
Use your computer's local IP: `http://192.168.x.x/ai_scrms`
- Windows: run `ipconfig` in CMD
- macOS/Linux: run `ifconfig` in Terminal

---

## 🔑 Demo Login Credentials

All accounts use password: **`password`**

| Email | Role | Access |
|-------|------|--------|
| `admin@campus.edu` | Super Admin | Full access |
| `fm@campus.edu` | Facility Manager | Resources + Analytics |
| `kwame@campus.edu` | Faculty | Bookings + Reports |
| `ama@campus.edu` | Student | Bookings + QR Check-in |
| `tech@campus.edu` | Maintenance | Work orders |

> **Tip:** On the login screen, tap any demo email to auto-fill the credentials.

---

## 🗂️ Project Structure

```
ai_scrms_flutter/
├── lib/
│   ├── main.dart                    # App entry + auth gate
│   ├── theme/
│   │   └── app_theme.dart           # Dark theme, colors
│   ├── models/
│   │   └── models.dart              # User, Resource, Booking, etc.
│   ├── services/
│   │   ├── api_service.dart         # All API calls to PHP backend
│   │   └── auth_provider.dart       # Auth state management
│   ├── widgets/
│   │   └── widgets.dart             # Shared UI components
│   └── screens/
│       ├── auth_screen.dart         # Login + Register
│       ├── home_screen.dart         # Drawer navigation shell
│       ├── dashboard_screen.dart    # Role-based dashboard
│       ├── resources_screen.dart    # Browse + filter resources
│       ├── book_resource_screen.dart # Booking flow
│       ├── my_bookings_screen.dart  # User's bookings + QR
│       ├── waitlist_screen.dart     # Waitlist entries
│       ├── qr_screen.dart           # QR scanner check-in
│       ├── notifications_screen.dart # Notifications
│       ├── analytics_screen.dart   # Charts + demand forecast
│       ├── maintenance_screen.dart  # Fault reporting
│       └── admin_screens.dart       # All Bookings, Manage Resources, Users, Audit
├── android/
│   └── app/src/main/AndroidManifest.xml
├── ios/
│   └── Runner/Info.plist
├── pubspec.yaml                     # Dependencies
└── INSTRUCTIONS.md                  # This file
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `http` | REST API calls to PHP backend |
| `provider` | Auth state management |
| `shared_preferences` | Save server URL |
| `qr_flutter` | Generate QR codes |
| `mobile_scanner` | Scan QR codes (camera) |
| `fl_chart` | Line chart, pie chart |
| `google_fonts` | Inter font |
| `badges` | Notification count badge |

---

## 🐛 Troubleshooting

**"Network error" / can't connect to backend:**
- Check XAMPP Apache & MySQL are running
- Verify URL in ⚙️ Server Settings
- For Android emulator, use `http://10.0.2.2/ai_scrms`

**Camera not working (QR scanner):**
- Android: Check camera permission is granted in device settings
- iOS: Ensure NSCameraUsageDescription is in Info.plist (already included)

**`flutter pub get` fails:**
- Run `flutter doctor` and fix any issues
- Ensure Flutter SDK is in your PATH

**Build errors on iOS:**
- Open `ios/Runner.xcworkspace` in Xcode and check signing
- Run `cd ios && pod install` if CocoaPods are missing

**Charts not rendering:**
- Ensure `fl_chart: ^0.68.0` is in pubspec.yaml
- Run `flutter clean && flutter pub get`

---

## 🌐 Web Limitations

When running as a **web app**:
- QR scanner (camera) requires HTTPS in production
- Use Chrome for best compatibility
- Run: `flutter run -d chrome`

---

## 📱 Building for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS (requires macOS + Xcode)
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
# Output in: build/web/
```

---

Built with Flutter · Powered by the original AI-SCRMS PHP backend
