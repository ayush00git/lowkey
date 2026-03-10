/// Represents a chat message.
class ChatMessage {
  final String id;
  final String content;
  final String sender;
  final bool isMine;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.isMine,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'sender': sender,
    'isMine': isMine,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'] as String,
    content: map['content'] as String,
    sender: map['sender'] as String,
    isMine: map['isMine'] as bool,
    timestamp: DateTime.parse(map['timestamp'] as String),
  );
}
