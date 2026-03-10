# Lowkey Flutter Frontend

Two-screen P2P chat app that connects to the Go signaling backend, establishes WebRTC DataChannels, and encrypts messages E2E.

## Screens

### 1. Username Screen (first launch)
- Dark themed, centered card with a text field + "Get Started" button
- Validates: non-empty, alphanumeric, 3-20 chars
- Saves username to `SharedPreferences`
- On subsequent launches, skips straight to Chat screen

### 2. Chat Screen
- **Header**: username display + connection status indicator (dot: green/red)
- **Session controls**: Create session (generates UUID to share) or Join session (paste UUID)
- **Message list**: bubbles — left for incoming, right for outgoing, with timestamps
- **Input bar**: text field + send button
- Messages encrypted with the session key (AES-256-GCM) before sending over DataChannel
- Messages stored locally in SQLite via Drift

## Architecture

```
app/lib/
├── main.dart                    # App entry, routing, theme
├── screens/
│   ├── username_screen.dart     # Screen 1: set username
│   └── chat_screen.dart         # Screen 2: chat UI
├── services/
│   ├── signaling_service.dart   # WebSocket connection to Go backend
│   ├── webrtc_service.dart      # RTCPeerConnection + DataChannel management
│   └── crypto_service.dart      # AES-256-GCM encrypt/decrypt
├── models/
│   └── message.dart             # Message model
├── db/
│   ├── database.dart            # Drift database definition
│   └── messages_dao.dart        # Message queries
└── widgets/
    ├── message_bubble.dart      # Chat bubble widget
    └── connection_indicator.dart # Status dot widget
```

## Proposed Changes

### 1. Project Creation

#### [NEW] Flutter project at `app/`
```bash
flutter create --org com.lowkey --project-name lowkey_app app
```

---

### 2. Dependencies (`pubspec.yaml`)

| Package | Purpose |
|---------|---------|
| `web_socket_channel` | WebSocket to Go signaling server |
| `flutter_webrtc` | WebRTC (RTCPeerConnection, DataChannel) |
| `shared_preferences` | Persist username locally |
| `drift` + `sqlite3_flutter_libs` | Local SQLite message storage |
| `drift_dev` + `build_runner` (dev) | Drift code generation |
| `encrypt` | AES-256-GCM encryption |
| `google_fonts` | Premium typography (Inter) |
| `provider` | Lightweight state management |

---

### 3. Signaling Service

#### [NEW] [signaling_service.dart](file:///home/ayush/Documents/projects/lowkey/app/lib/services/signaling_service.dart)
- Connects to `ws://<host>:8080/ws?username=<name>`
- Sends/receives JSON messages matching the backend protocol
- Exposes streams: `onSessionCreated`, `onSessionJoined`, `onSignal`
- Auto-reconnect with exponential backoff

---

### 4. WebRTC Service

#### [NEW] [webrtc_service.dart](file:///home/ayush/Documents/projects/lowkey/app/lib/services/webrtc_service.dart)
- Creates `RTCPeerConnection` with STUN servers
- Creates/accepts DataChannel for chat
- Generates SDP offer/answer and feeds ICE candidates via signaling service
- Exposes `onMessage` stream and `sendMessage()` method

---

### 5. Crypto Service

#### [NEW] [crypto_service.dart](file:///home/ayush/Documents/projects/lowkey/app/lib/services/crypto_service.dart)
- `encrypt(plaintext, key) → base64 ciphertext`
- `decrypt(ciphertext, key) → plaintext`
- Uses AES-256-GCM from the `encrypt` package

---

### 6. Screens

#### [NEW] [username_screen.dart](file:///home/ayush/Documents/projects/lowkey/app/lib/screens/username_screen.dart)
- Dark gradient background
- Glassmorphic card with frosted effect
- Animated text field with validation
- "Get Started" button with subtle press animation
- Saves to SharedPreferences, navigates to ChatScreen

#### [NEW] [chat_screen.dart](file:///home/ayush/Documents/projects/lowkey/app/lib/screens/chat_screen.dart)
- **App bar**: peer username + connection indicator dot
- **Session panel** (before connected): create/join session UI with UUID sharing
- **Message list**: `ListView.builder` with `MessageBubble` widgets
- **Input bar**: rounded text field + gradient send button
- Integrates signaling → WebRTC → crypto pipeline

---

### 7. Local Storage (Drift)

#### [NEW] [database.dart](file:///home/ayush/Documents/projects/lowkey/app/lib/db/database.dart)
- `Messages` table: id, sessionId, sender, content, timestamp, isMine
- Auto-generated with `build_runner`

---

## Verification Plan

### Automated
- `flutter analyze` — zero warnings
- `flutter test` — widget tests for both screens

### Manual
- Run on Android emulator or physical device
- Set username → lands on chat screen
- Start Go backend → create session → share UUID → join from second device
- Exchange messages → verify E2E encryption in server logs (server sees nothing)
