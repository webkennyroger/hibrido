
enum MessageType { text, image, video, audio, document }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final String? mediaUrl;
  final Duration? audioDuration;
  final bool isSentByMe;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    this.mediaUrl,
    this.audioDuration,
    required this.isSentByMe,
    required this.timestamp,
  });
}
