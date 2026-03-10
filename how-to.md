# Testing Lowkey P2P Chat

Follow these steps to test the end-to-end encrypted connection between two peers.

## 1. Start the Signaling Server
Open a terminal in the project root and run:
```bash
cd /home/ayush/Documents/projects/lowkey
go run cmd/server/main.go
```
The server will start at `http://localhost:8080`.

## 2. Configure the Frontend
Depending on where you are running the app, you may need to update the `_serverUrl` in [app/lib/screens/chat_screen.dart](file:///home/ayush/Documents/projects/lowkey/app/lib/screens/chat_screen.dart) (Line 40):

| Platform | URL |
| :--- | :--- |
| **Linux Desktop** | `ws://localhost:8080` |
| **Android Emulator** | `ws://10.0.2.2:8080` (Default) |
| **Physical Phone** | `ws://<YOUR_COMPUTER_IP>:8080` |

> [!TIP]
> To find your computer's IP on Linux, run `hostname -I`.

## 3. Run the App (Phone A)
Open a new terminal and run:
```bash
cd /home/ayush/Documents/projects/lowkey/app
flutter run -d <device_id_1>
```
*   Pick a username (e.g., **"Alice"**).
*   Wait for the connection dot to turn green.

## 4. Run the App (Phone B)
Open another terminal (or use another device) and run:
```bash
flutter run -d <device_id_2>
```
*   Pick a username (e.g., **"Bob"**).
*   Wait for the connection dot to turn green.

## 5. Connect and Chat
1.  On **Alice's** phone, type **"Bob"** in the "Connect to Peer" box.
2.  Press **Connect**.
3.  The server will link them, and the status should change to **"🔒 E2E Encryption Active"**.
4.  Start typing!

> [!NOTE]
> All messages sent through the P2P DataChannel are encrypted with a session-specific AES-256-GCM key that the server distributes but cannot read.
