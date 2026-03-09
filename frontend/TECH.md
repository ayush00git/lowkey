# Technical Architecture and Implementation

This document covers the frontend implementation details for the `lowkey` application.

## 1. Database (WatermelonDB)

We use **WatermelonDB** for local SQLite-based reactivity.

- **Setup**: React Native JSI setup is completed via `MainApplication.kt` and iOS `Podfile` adjustments.
- **Decorators**: Babel decorators (`@babel/plugin-proposal-decorators`) are enabled. We explicitly enabled `experimentalDecorators: true` and `strictPropertyInitialization: false` in `tsconfig.json` to allow decorators in model definitions without type compilation errors. Since WatermelonDB doesn't natively supply TypeScript types, custom declarations are housed in `types/watermelondb.d.ts`.
- **Models**:
  - `Message` model (`model/Message.ts`)
    - Attached to table `messages`.
    - Columns defined: `message_id` (string), `sender_id` (string), `ciphertext` (string), `expires_at` (number/date).

## 2. Signaling Service (gRPC-Web)

The application utilizes **gRPC-Web** to communicate with the signaling backend natively over Envoy or grpc-web proxied sockets.

- **Protobuf Generation**:
  - Stubs are generated locally through `grpc_tools_node_protoc` and `protoc-gen-grpc-web` using the script `generate_protos.sh`. The output resides in `src/proto/`.
- **SignalingService Class**:
  - Located in `src/services/SignalingService.ts`.
  - Encapsulates a `SignalingClient` connection to the backend.
  - Generates a UUID using `react-native-get-random-values/uuidv4`.
  - Automatically sends an `Identity` registration event upon connection.
  - Listens to incoming messages parsing data like `SdpExchange`, `IceCandidate`, identity mapping, and standard gRPC errors.

## 3. WebRTC Manager

The class `src/services/WebRTCManager.ts` is responsible for handling localized peer connections (`RTCPeerConnection`).
- **Initialization**: Automatically sets up public Google STUN servers.
- **Interactions**:
  - `createOffer(targetUuid)`: Instantiates a local SDP offer, assigns it as the local description, and transmits it via the attached `SignalingService`.
  - `createAnswer(offerSdp, targetUuid)`: Assigns the remote SDP offer to the connection, responds with an SDP answer, and forwards the generated answer.
  - `handleAnswer(answerSdp)`: Saves the remote SDP answer to finalize WebRTC negotiation.
  - `handleIceCandidate(iceProtoMsg)`: Takes incoming ICE definitions from the signaling framework and applies them natively.
- **Event Listeners**: Whenever the local connection fires `onicecandidate`, the manager dynamically transmits the candidate coordinates back through the backend via `signaling.sendIceCandidate()`.
