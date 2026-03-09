# Protocol Buffers v1

This directory contains the version 1 protocol buffer definitions for the Lowkey signaling service.

## Files

- [signaling.proto](./signaling.proto): Defines the WebRTC signaling service and related messages.

## Signaling Service

The `Signaling` service provides a bidirectional gRPC stream for peer-to-peer negotiation.

### RPCs

- `Connect(stream SignalRequest) returns (stream SignalResponse)`
  - Establishes a persistent connection for exchanging signaling data.

### Messages

#### `Identity`

Used for peer registration.

- `uuid` (string): Unique identifier for the peer.
- `public_key` (bytes): Peer's public key for secure communication.

#### `SdpExchange`

Encapsulates WebRTC Session Description Protocol details.

- `type` (Enum): The type of SDP (OFFER, ANSWER, etc.).
- `sdp` (string): The raw SDP string.
- `target_uuid` (string): The recipient's UUID for routing by the server.

#### `IceCandidate`

Contains WebRTC ICE candidate information.

- `candidate` (string): The ICE candidate string.
- `sdp_mid` (string): The media stream ID.
- `sdp_m_line_index` (int32): The index of the media line.
- `target_uuid` (string): The recipient's UUID for routing by the server.

## Go Signaling Server

The implementation in `./server` provides a robust signaling coordinator.

### Features

- **Bidirectional Streaming**: Uses gRPC streams for real-time negotiation.
- **Redis Routing**: Leverages Redis Pub/Sub to forward messages between peers.
- **UUID-based Delivery**: Messages are routed specifically to the `target_uuid` provided in the payload.

### Running the Server

1. Ensure Redis is running:
   ```bash
   docker run -p 6379:6379 redis
   ```
2. Build and run the server:
   ```bash
   go build -o signaling-server ./server
   ./signaling-server
   ```
