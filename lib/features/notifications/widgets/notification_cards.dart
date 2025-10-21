import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

/// Um card genérico para notificações de "Tweet" ou "Follow".
class TweetNotificationCard extends StatelessWidget {
  final IconData leadingIcon;
  final Color iconColor;
  final String userAvatar;
  final String userName;
  final String content;

  const TweetNotificationCard({
    super.key,
    required this.leadingIcon,
    required this.iconColor,
    required this.userAvatar,
    required this.userName,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(leadingIcon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(userAvatar),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.lexend(color: colors.text, fontSize: 16),
                    children: [
                      TextSpan(
                        text: '$userName ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Um card específico para notificações de "Menção" ou "Curtida", que inclui o conteúdo do tweet.
class TweetMentionNotificationCard extends StatelessWidget {
  final IconData leadingIcon;
  final Color iconColor;
  final String userAvatar;
  final String userName;
  final String userHandle;
  final String mentionContent;
  final String tweetContent;

  const TweetMentionNotificationCard({
    super.key,
    required this.leadingIcon,
    required this.iconColor,
    required this.userAvatar,
    required this.userName,
    required this.userHandle,
    required this.mentionContent,
    required this.tweetContent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(leadingIcon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(userAvatar),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userName,
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      userHandle,
                      style: GoogleFonts.lexend(color: colors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mentionContent,
                  style: GoogleFonts.lexend(color: colors.text, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  tweetContent,
                  style: GoogleFonts.lexend(
                    color: colors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
