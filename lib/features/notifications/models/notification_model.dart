enum NotificationType { tweet, mention, follow, like }

class Notification {
  final String userAvatar;
  final String userName;
  final String userHandle;
  final String content;
  final NotificationType type;
  final String? tweetContent; // Apenas para curtidas e menções

  const Notification({
    required this.userAvatar,
    required this.userName,
    required this.userHandle,
    required this.content,
    required this.type,
    this.tweetContent,
  });
}
