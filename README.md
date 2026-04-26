<h1 align="center">
  <br>
  LastHope 🚨
</h1>

<h4 align="center">An Automated Emergency Response Application built with Flutter.</h4>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## 🌟 Overview

**LastHope** is a life-saving application designed to provide immediate assistance during critical emergencies. When activated, it ensures rapid response by automatically sending distress SMS, triggering priority phone calls, tracking live location, and emitting high-visibility alerts (strobe light and max-volume siren) without the need for manual input and minimizing errors.

## ✨ Key Features

- **🆘 One-Tap SOS**: Trigger emergency protocol instantly when you're in danger.
- **📍 Live Map Tracking**: Shares current real-time GPS coordinates with trusted contacts.
- **📞 Priority Calling**: Bypasses traditional steps to directly connect with emergency contacts seamlessly.
- **✉️ Automated SMS Dispatch**: Safely dispatches pre-configured distress texts to your contacts.
- **🚶‍♂️ Fall Detection**: Automatically senses sudden impacts or falls and initiates the SOS sequence.
- **🔦 Hardware Alerts**: Emits a strobe flashlight and a max-volume siren for immediate physical rescue visibility.
- **💬 Real-time Chat**: Connects to the backend server to facilitate communication during an emergency.

## 🛠️ Technology Stack

- **Framework**: Flutter
- **Language**: Dart
- **Backend/Chat**: Node.js & Socket.IO (Configured separately in the `backend` folder)
- **Maps**: Google Maps SDK

## 🚀 Installation & Setup

### Prerequisites

Ensure you have the following installed on your local machine:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- Android Studio / VS Code
- Git
- Node.js (for backend)

### Cloning the Repository

```bash
git clone https://github.com/yourusername/LastHope.git
cd LastHope/last_hope
```

### Install Dependencies

```bash
flutter pub get
```

If you are setting up the backend as well:
```bash
cd backend
npm install
```

### Environment Configuration

Create a `.env` file in the root directory (`last_hope/`) and add your necessary API keys (like Google Maps API Key, Backend URLs, etc.):

```env
API_KEY=your_api_key_here
```
> **Note**: Your `.env` files contain sensitive information and are ignored by version control. Never push your `.env` file to github!

### Run the App

```bash
flutter run
```

## 📂 Project Structure

```text
last_hope/
├── android/          # Android native configuration
├── ios/              # iOS native configuration
├── lib/              # Main Flutter Dart source code
│   ├── screens/      # Application UI screens
│   ├── widgets/      # Reusable UI components
│   ├── services/     # Background services (Location, SOS, SMS)
│   └── main.dart     # Application entry point
├── backend/          # Node.js chat server
└── assets/           # Images, icons, fonts
```

## 🔐 What to push and what NOT to push to GitHub

You should be careful not to upload sensitive secrets or unnecessarily large cache folders to GitHub.

### 🚫 **DO NOT PUSH (Ignored by `.gitignore`)**
- `.env` files (Both in your root Flutter project and your Node backend)
- `.dart_tool/`
- `.flutter-plugins-dependencies` 
- `build/` (This contains intermediate compiled files)
- `node_modules/` (Located under `backend/`)
- Any generated `.keys` or IDE `.idea`, `.vscode/` settings

**(I've updated your `.gitignore` to ensure `.env` and `backend/node_modules/` are ignored!)**

### ✅ **DO PUSH**
- `lib/` (Your source code)
- `pubspec.yaml` and `pubspec.lock`
- Configurations like `android/app/build.gradle` and `ios/Runner/Info.plist`
- `assets/`
- `backend/` source files (like `package.json`, `index.js`, etc.)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
   
<h3>Contributors</h3>
<p>Edited by Rushi - Initial contribution</p>
<p>Rushi - Added README contribution</p>
