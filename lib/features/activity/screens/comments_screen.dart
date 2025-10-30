import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/screens/share_activity_screen.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/core/utils/map_utils.dart';
import 'package:hibrido/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/map/screens/finished_confirmation_sheet.dart'
    as ConfirmationSheet;
import 'package:hibrido/widgets/full_screen_media_viewer.dart';
import 'comment_widget.dart';
import 'package:hibrido/services/activity_service.dart';

// Modelo mock para parceiros (reutilizado da tela de confirmação)
class Partner {
  final String id, name, avatarUrl;
  Partner({required this.id, required this.name, required this.avatarUrl});
}

// Modelo mock para quem curtiu
class Liker {
  final String name;
  final String avatarUrl;
  Liker({required this.name, required this.avatarUrl});
}

// NOVO: Modelo para um comentário, para incluir mais detalhes.
class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String text;
  final DateTime timestamp;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.text,
    required this.timestamp,
    this.replies = const [],
  });
}

class CommentsScreen extends StatefulWidget {
  final ActivityData activityData;

  const CommentsScreen({super.key, required this.activityData});
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  GoogleMapController? _mapController;
  final ActivityRepository _repository = ActivityRepository();
  late ActivityData _activityData; // NOVO: Estado local da atividade
  final FocusNode _commentFocusNode = FocusNode();

  // NOVO: Rastreia o comentário que está sendo respondido.
  Comment? _replyingToComment;

  // NOVO: Lista de comentários com mais detalhes (simulada por enquanto)
  final List<Comment> _comments = [];

  // Lista de parceiros mock para demonstração.
  final List<Partner> _mockPartners = [
    Partner(
      id: '1',
      name: 'João Silva',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
    ),
    Partner(
      id: '2',
      name: 'Maria Oliveira',
      avatarUrl: 'https://i.pravatar.cc/150?img=2',
    ),
    Partner(
      id: '3',
      name: 'Carlos Souza',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // A lista de comentários (_comments) agora começará vazia.
    _activityData = widget.activityData; // Inicializa o estado local
  }

  @override
  void dispose() {
    _commentController.dispose();
    _mapController?.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // Adiciona um novo comentário e salva
  void _postComment() {
    if (_commentController.text.trim().isEmpty) return;

    final user = context.read<UserProvider>().user;
    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.id,
      userName: user.name,
      userAvatarUrl: user.avatarUrl,
      text: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      if (_replyingToComment != null) {
        // Adiciona como uma resposta
        final parentCommentIndex = _comments.indexWhere(
          (c) => c.id == _replyingToComment!.id,
        );
        if (parentCommentIndex != -1) {
          _comments[parentCommentIndex].replies.add(newComment);
        }
        _replyingToComment = null; // Reseta o estado de resposta
      } else {
        // Adiciona como um comentário principal
        _comments.add(newComment);
      }
    });

    // TODO: A lógica de persistência precisa ser atualizada para lidar com respostas aninhadas.
    // A estrutura atual de `commentsList` (uma lista de strings) não suporta isso.
    // Por enquanto, a UI será atualizada, mas as respostas não serão salvas permanentemente.
    /*
    final updatedActivity = _activityData.copyWith(
      commentsList: _comments.map((c) => c.text).toList(),
    );
    _repository.updateActivity(updatedActivity);
    _activityData = updatedActivity; // Atualiza o estado local
    */

    _commentController.clear();
    FocusScope.of(context).unfocus(); // Esconde o teclado
  }

  // NOVO: Função para formatar o tempo em 'há X tempo'
  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    } else if (difference.inDays > 0) {
      return 'há ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'há ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'há ${difference.inMinutes}m';
    } else {
      return 'agora';
    }
  }

  // --- Funções Auxiliares de Formatação ---
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatSpeed(double distanceInMeters, Duration duration) {
    if (duration.inSeconds == 0) return '0.00';
    // Velocidade em km/h
    final speedKmH = (distanceInMeters / 1000) / (duration.inSeconds / 3600);
    return speedKmH.toStringAsFixed(2);
  }

  /// Formata a data da atividade de forma inteligente.
  /// Mostra "Hoje" se for no mesmo dia, senão mostra a data completa.
  String _formatActivityDate(DateTime activityDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(
      activityDate.year,
      activityDate.month,
      activityDate.day,
    );

    String datePart;
    if (activityDay == today) {
      datePart = 'Hoje';
    } else {
      datePart = DateFormat('dd/MM/yyyy').format(activityDate);
    }

    final timePart = DateFormat('HH:mm').format(activityDate);

    return '$datePart às $timePart';
  }

  /// Converte a string do tipo de mapa para o enum MapType do Google Maps.
  MapType _mapTypeFromString(String? mapType) {
    switch (mapType?.toLowerCase()) {
      case 'satellite':
        return MapType.satellite;
      case 'hybrid':
        return MapType.hybrid;
      case 'normal':
      default:
        return MapType.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.error),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Atividade',
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: const [], // Botão "Postar" removido do AppBar
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Cabeçalho com informações da atividade
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: user.profileImage,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activityData.userName,
                                  style: GoogleFonts.lexend(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colors.text,
                                  ),
                                ),
                                Text(
                                  _formatActivityDate(_activityData.createdAt),
                                  style: GoogleFonts.lexend(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _activityData.activityTitle,
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: colors.text,
                          ),
                        ),
                        // NOVO: Anotações/Descrição da atividade
                        if (_activityData.notes != null &&
                            _activityData.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _activityData.notes!,
                            style: GoogleFonts.lexend(
                              color: colors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                        // Seção de Humor (Emoji)
                        if (_activityData.mood != null) ...[
                          const SizedBox(height: 16),
                          _buildMoodDisplay(colors),
                        ],
                        const SizedBox(height: 16),
                        _buildStatsRow(colors), // Linha de estatísticas
                        const SizedBox(height: 12),
                        // Mapa com a rota
                        SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: GoogleMap(
                              mapType: _mapTypeFromString(
                                _activityData.mapType,
                              ),
                              onMapCreated: (controller) {
                                _mapController = controller;
                                if (_activityData.routePoints.isNotEmpty) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngBounds(
                                      LatLngBoundsUtils.fromLatLngList(
                                        _activityData.routePoints,
                                      ),
                                      50.0,
                                    ),
                                  );
                                }
                              },
                              initialCameraPosition: CameraPosition(
                                target: _activityData.routePoints.isNotEmpty
                                    ? _activityData.routePoints.first
                                    : const LatLng(0, 0),
                                zoom: 15,
                              ),
                              polylines: {
                                Polyline(
                                  polylineId: const PolylineId('route'),
                                  points: _activityData.routePoints,
                                  color: AppColors.primary,
                                  width: 4,
                                ),
                              },
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                            ),
                          ),
                        ),
                        // NOVO: Seção de Mídia (fotos e vídeos)
                        if (_activityData.mediaPaths.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildMediaSection(),
                        ],
                        // NOVO: Linha com informações sociais (Parceiros e Curtidas)
                        _buildSocialInfoRow(colors),
                        const SizedBox(height: 16),
                        _buildActionButtons(colors), // Botões de Ação
                        const SizedBox(height: 12),
                        Divider(height: 1, color: colors.text.withOpacity(0.1)),
                      ],
                    ),
                  ),
                  _comments.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80.0),
                          child: Center(
                            child: Text(
                              'Seja o primeiro a comentar!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return CommentWidget(
                              comment: comment,
                              timeAgo: _formatTimeAgo(comment.timestamp),
                              onReply: (commentToReply) {
                                setState(() {
                                  _replyingToComment = commentToReply;
                                });
                                // Foca no campo de texto para o usuário digitar a resposta.
                                _commentFocusNode.requestFocus();
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          // Área de digitação do comentário na parte inferior.
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(color: colors.text.withOpacity(0.12)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // NOVO: Indicador de que está respondendo a um comentário
                  if (_replyingToComment != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Respondendo a ${_replyingToComment!.userName}',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _replyingToComment = null),
                            child: Icon(
                              Icons.close,
                              color: colors.textSecondary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: user.profileImage,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          style: TextStyle(color: colors.text),
                          decoration: InputDecoration(
                            hintText: _replyingToComment == null
                                ? 'Adicione um comentário...'
                                : 'Adicione uma resposta...',
                            hintStyle: TextStyle(color: colors.textSecondary),
                            filled: true,
                            fillColor: colors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botão de enviar
                      InkWell(
                        onTap: _postComment,
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o display do humor selecionado.
  Widget _buildMoodDisplay(AppColors colors) {
    final List<String> moodEmojis = ['😖', '😒', '😐', '😊', '😁'];
    final List<String> moodLabels = ['Dolorido', 'Mau', 'Ok', 'Bom', 'Otimo'];

    // Garante que o índice de humor seja válido.
    if (_activityData.mood == null ||
        _activityData.mood! < 0 ||
        _activityData.mood! >= moodEmojis.length) {
      return const SizedBox.shrink(); // Não mostra nada se o humor for inválido.
    }

    final selectedMoodIndex = widget.activityData.mood!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text(
          'Como foi essa corrida?',
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              moodLabels[selectedMoodIndex],
              style: GoogleFonts.lexend(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
            // NOVO: Container para estilizar o emoji com fundo e sombra.
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                moodEmojis[selectedMoodIndex],
                style: TextStyle(fontSize: 24, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
      ],
    );
  }

  /// Constrói a linha de estatísticas da atividade.
  Widget _buildStatsRow(AppColors colors) {
    final distance = (_activityData.distanceInMeters / 1000).toStringAsFixed(2);
    final duration = _formatDuration(_activityData.duration);
    final speed = _formatSpeed(
      _activityData.distanceInMeters,
      _activityData.duration,
    );
    final calories = _activityData.calories.toStringAsFixed(0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildMetricsCard(
            colors: colors,
            icon: Icons.directions_run,
            title: distance,
            value: 'KM',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricsCard(
            colors: colors,
            icon: Icons.schedule,
            title: duration,
            value: 'TEMPO',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricsCard(
            colors: colors,
            icon: Icons.speed,
            title: speed,
            value: 'KM/H',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricsCard(
            colors: colors,
            icon: Icons.local_fire_department,
            title: calories,
            value: 'CALORIAS',
          ),
        ),
      ],
    );
  }

  /// Constrói um card individual para exibir uma métrica.
  Widget _buildMetricsCard({
    required AppColors colors,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.lexend(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lexend(
              color: colors.text.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de mídia com fotos e vídeos.
  Widget _buildMediaSection() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _activityData.mediaPaths.map((path) {
          final isVideo = [
            '.mp4',
            '.mov',
            '.avi',
          ].any((ext) => path.toLowerCase().endsWith(ext));
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FullScreenMediaViewer(mediaFile: File(path)),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isVideo)
                        Container(color: Colors.black)
                      else
                        Image.file(File(path), fit: BoxFit.cover),
                      if (isVideo)
                        const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// NOVO: Constrói a linha que agrupa as informações sociais (parceiros e curtidas).
  Widget _buildSocialInfoRow(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Seção de Parceiros (ocupa o espaço necessário)
          _buildPartnersSection(colors),
          // Seção de Curtidas (alinhada à direita)
          _buildLikesSection(colors),
        ],
      ),
    );
  }

  /// Constrói os botões de ação (Curtir, Comentar, Compartilhar).
  Widget _buildActionButtons(AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botões de Curtir e Comentar (lado esquerdo)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ação de Curtir com contador
            InkWell(
              onTap: () {
                final user = context.read<UserProvider>().user;
                // Lógica para curtir/descurtir a atividade
                final activityService = Provider.of<ActivityService>(
                  context,
                  listen: false,
                );
                activityService.toggleLike(_activityData.id, user.avatarUrl);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up_outlined,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_activityData.likes}',
                      style: GoogleFonts.lexend(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Ação de Comentar com contador
            InkWell(
              onTap: () {
                // Focar no campo de comentário
                FocusScope.of(context).requestFocus(_commentFocusNode);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_activityData.commentsList.length}',
                      style: GoogleFonts.lexend(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Botão de Compartilhar (lado direito)
        IconButton(
          icon: Icon(Icons.share_outlined, color: colors.textSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ShareActivityScreen(activityData: _activityData),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Constrói a seção que mostra os parceiros marcados.
  Widget _buildPartnersSection(AppColors colors) {
    // Filtra a lista de parceiros mock para encontrar os que foram marcados.
    final taggedPartners = _mockPartners
        .where((p) => _activityData.taggedPartnerIds.contains(p.id))
        .toList();

    if (taggedPartners.isEmpty) {
      // NOVO: Mostra uma mensagem quando não há parceiros.
      return Row(
        children: [
          Icon(Icons.group_off_outlined, color: colors.textSecondary, size: 16),
          const SizedBox(width: 8),
          Text(
            'Ninguém marcado',
            style: GoogleFonts.lexend(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    // Mostra os parceiros marcados.
    return Row(
      children: [
        Icon(Icons.group, color: colors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(
          'Com ',
          style: GoogleFonts.lexend(color: colors.textSecondary, fontSize: 14),
        ),
        // Mapeia a lista de parceiros para widgets de texto em negrito
        ...List.generate(taggedPartners.length, (index) {
          final partner = taggedPartners[index];
          return Text(
            // Adiciona vírgula e "e" conforme necessário
            '${partner.name}${index < taggedPartners.length - 2
                ? ', '
                : index == taggedPartners.length - 2
                ? ' e '
                : ''}',
            style: GoogleFonts.lexend(
              color: colors.text,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          );
        }),
      ],
    );
  }

  /// Constrói a seção que mostra quem curtiu a atividade.
  Widget _buildLikesSection(AppColors colors) {
    if (_activityData.likes <= 0) {
      return const SizedBox.shrink(); // Não mostra nada se não houver curtidas
    }

    // Pega no máximo 3 avatares da lista de curtidas da atividade.
    final likersToShow = _activityData.likers.take(3).toList();

    // Stack para empilhar os avatares
    return SizedBox(
      width: 32.0 + (likersToShow.length - 1) * 22.0, // Largura dinâmica
      height: 32,
      child: Stack(
        children: List.generate(likersToShow.length, (index) {
          return Positioned(
            left: index * 22.0, // Deslocamento para empilhar
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(likersToShow[index]),
              // Adiciona uma borda para separar os avatares
              backgroundColor: colors.surface,
            ),
          );
        }),
      ),
    );
  }
}
