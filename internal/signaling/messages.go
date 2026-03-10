package signaling

import "encoding/json"

// Message types used in the signaling protocol.
const (
	// Session lifecycle
	TypeSessionCreate  = "session:create"
	TypeSessionCreated = "session:created"
	TypeSessionJoin    = "session:join"
	TypeSessionJoined  = "session:joined"
	TypeSessionConnect = "session:connect" // connect by target username

	// Key exchange (client-side X25519)
	TypeKeyExchange = "key:exchange"

	// WebRTC signaling
	TypeSignalOffer  = "signal:offer"
	TypeSignalAnswer = "signal:answer"
	TypeSignalICE    = "signal:ice"

	// Errors
	TypeError = "error"
)

// Message is the envelope for all WebSocket communication.
type Message struct {
	Type      string          `json:"type"`
	SessionID string          `json:"sessionId,omitempty"`
	Target    string          `json:"target,omitempty"`
	Sender    string          `json:"sender,omitempty"`
	Payload   json.RawMessage `json:"payload,omitempty"`
}

// SessionCreatedPayload is sent to the creator after session creation.
type SessionCreatedPayload struct {
	SessionID string `json:"sessionId"`
}

// SessionJoinedPayload is sent to both users when the session is ready.
type SessionJoinedPayload struct {
	SessionID string `json:"sessionId"`
	Peer      string `json:"peer"` // the other user's username
}

// ErrorPayload carries error information.
type ErrorPayload struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}
