# Lowkey Frontend

React Native mobile application for the Lowkey WebRTC signaling and communication system.

## Tech Stack

- **Framework**: [React Native](https://reactnative.dev/) (v0.84.1)
- **Runtime**: [Expo](https://expo.dev/) (Managed Workflow with Custom Dev Client)
- **Real-time Communication**: [react-native-webrtc](https://github.com/react-native-webrtc/react-native-webrtc)
- **Signaling**: [gRPC (@grpc/grpc-js)](https://www.npmjs.com/package/@grpc/grpc-js)
- **Local Database**: [WatermelonDB](https://nozbe.github.io/WatermelonDB/) (SQLite)

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (>= 22.11.0)
- [Android Studio](https://developer.android.com/studio) (for Android) or [Xcode](https://developer.apple.com/xcode/) (for iOS)
- [Rust](https://www.rust-lang.org/) (Optional, but often needed for some native modules during prebuild)

### Installation

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   npm install --legacy-peer-deps
   ```

## Running the App

Since this project uses native modules like WebRTC and WatermelonDB, you need to use the **Expo Dev Client**.

### Build & Run (Android)
```bash
npm run android
```
*Note: This will perform an `expo prebuild` and then run the native Android app.*

### Build & Run (iOS)
```bash
npm run ios
```

### Start Development Server
```bash
npm start
```
*Note: Use this after you have already installed the app on your device/emulator.*

## Implementation Details

### Database (WatermelonDB)
Located in `src/model/`:
- `schema.js`: Defines the `peers` and `messages` tables.
- `database.js`: Initializes the SQLite adapter and database instance.

### Native Permissions
The app is pre-configured with the following permissions in `AndroidManifest.xml`:
- Camera
- Microphone (Record Audio)
- Bluetooth
- Internet

### gRPC Signaling
The app uses `@grpc/grpc-js` and `google-protobuf` for communication with the `lowkey` signaling server.

## Troubleshooting

If you encounter issues with native modules after adding new plugins:
```bash
npm run prebuild
```
This will re-generate the `android/` and `ios/` folders based on `app.json`.
