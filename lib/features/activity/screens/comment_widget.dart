import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/screens/comments_screen.dart'
    show Comment;

class CommentWidget extends StatelessWidget {
  final Comment comment;
  final String timeAgo;
  final Function(Comment) onReply;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.timeAgo,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(comment.userAvatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style:
                            GoogleFonts.lexend(color: colors.text, fontSize: 14),
                        children: [
                          TextSpan(
                            text: '${comment.userName} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: comment.text),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: GoogleFonts.lexend(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => onReply(comment),
                          child: Text(
                            'Responder',
                            style: GoogleFonts.lexend(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Seção para exibir as respostas, agora com o recuo correto.
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: Column(
              children: comment.replies
                  .map((reply) => CommentWidget(
                        comment: reply,
                        // TODO: O cálculo do tempo deve ser feito aqui também.
                        timeAgo: 'agora',
                        onReply: onReply,
                      ))
                  .toList(),
            ),
          ),
        ],
      );
  }
}
