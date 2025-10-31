// comment_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/screens/comments_screen.dart'
    show Comment;

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final String Function(DateTime) formatTimeAgo;
  final Function(Comment) onReply;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.formatTimeAgo,
    required this.onReply,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  late bool _isLiked;
  late int _likeCount;
  // NOVO: Estado para controlar a visibilidade das respostas.
  bool _showReplies = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.comment.isLiked;
    _likeCount = widget.comment.likes;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
      // Atualiza o objeto original para manter o estado se o widget for reconstruído
      widget.comment.isLiked = _isLiked;
      widget.comment.likes = _likeCount;
    });
    // TODO: Persistir a alteração de "like" em um banco de dados ou serviço.
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar do Usuário
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.comment.userAvatarUrl.startsWith('http')
                  ? NetworkImage(widget.comment.userAvatarUrl)
                  : FileImage(File(widget.comment.userAvatarUrl))
                        as ImageProvider,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Container para o texto do comentário
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: widget.comment.userName,
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: ' ${widget.comment.text}',
                            style: GoogleFonts.lexend(
                              color: colors.text,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rodapé (tempo, curtidas, responder)
                  Row(
                    children: [
                      Text(
                        widget.formatTimeAgo(widget.comment.timestamp),
                        style: GoogleFonts.lexend(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => widget.onReply(widget.comment),
                        child: Text(
                          'Responder',
                          style: GoogleFonts.lexend(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // NOVO: Botão para ver/ocultar respostas
                  if (widget.comment.replies.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showReplies = !_showReplies;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 1,
                            color: colors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showReplies
                                ? 'Ocultar respostas'
                                : 'Ver ${widget.comment.replies.length} ${widget.comment.replies.length > 1 ? 'respostas' : 'resposta'}',
                            style: GoogleFonts.lexend(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Botão de Curtir e Contador
            Column(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? AppColors.error : colors.textSecondary,
                    size: 18,
                  ),
                ),
                if (_likeCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$_likeCount',
                    style: GoogleFonts.lexend(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        // Seção para exibir as respostas
        // As respostas agora são mostradas/ocultadas com base no estado _showReplies
        if (_showReplies && widget.comment.replies.isNotEmpty)
          Container(
            padding: const EdgeInsets.only(left: 40.0, top: 16.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.comment.replies.length,
              itemBuilder: (context, index) {
                final reply = widget.comment.replies[index];
                return CommentWidget(
                  comment: reply,
                  formatTimeAgo: widget.formatTimeAgo,
                  onReply: widget.onReply,
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            ),
          ),
      ],
    );
  }
}
