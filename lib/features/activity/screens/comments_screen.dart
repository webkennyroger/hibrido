import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/core/utils/map_utils.dart';
import 'package:hibrido/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/map/screens/finished_confirmation_sheet.dart'
    as ConfirmationSheet;
import 'package:hibrido/widgets/full_screen_media_viewer.dart';

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

class CommentsScreen extends StatefulWidget {
  final ActivityData activityData;

  const CommentsScreen({super.key, required this.activityData});
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  GoogleMapController? _mapController;
  bool _isPostButtonEnabled = false;
  late List<String> _comments;
  final ActivityRepository _repository = ActivityRepository();
  // Mock data para a lista de quem curtiu
  final List<Liker> _likers = [
    Liker(name: 'Você', avatarUrl: 'https://i.ibb.co/L8Gj18j/avatar.png'),
    Liker(name: 'Maria Oliveira', avatarUrl: 'https://i.pravatar.cc/150?img=2'),
    Liker(name: 'Carlos Souza', avatarUrl: 'https://i.pravatar.cc/150?img=3'),
    // Adicione mais pessoas aqui
  ];

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
    // Ouve as mudanças no campo de texto para habilitar/desabilitar o botão "Postar".
    _commentController.addListener(() {
      setState(() {
        _isPostButtonEnabled = _commentController.text.trim().isNotEmpty;
      });
    });
    _comments = List<String>.from(widget.activityData.commentsList);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Adiciona um novo comentário e salva
  void _postComment() {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _comments.add(
        _commentController.text.trim(),
      ); // Adiciona no final da lista
    });

    final updatedActivity = widget.activityData.copyWith(
      commentsList: _comments,
    );
    _repository.updateActivity(updatedActivity);

    _commentController.clear();
    FocusScope.of(context).unfocus(); // Esconde o teclado
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
          icon: Icon(Icons.close, color: colors.text),
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
        actions: [
          TextButton(
            onPressed: _isPostButtonEnabled
                ? () {
                    _postComment();
                  }
                : null,
            child: Text(
              'Postar',
              style: GoogleFonts.lexend(
                color: _isPostButtonEnabled
                    ? AppColors.primary
                    : Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
                                  widget.activityData.userName,
                                  style: GoogleFonts.lexend(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colors.text,
                                  ),
                                ),
                                Text(
                                  _formatActivityDate(
                                    widget.activityData.createdAt,
                                  ),
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
                          widget.activityData.activityTitle,
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: colors.text,
                          ),
                        ),
                        // NOVO: Anotações/Descrição da atividade
                        if (widget.activityData.notes != null &&
                            widget.activityData.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            widget.activityData.notes!,
                            style: GoogleFonts.lexend(
                              color: colors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                        // Seção de Humor (Emoji)
                        if (widget.activityData.mood != null) ...[
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
                              onMapCreated: (controller) {
                                _mapController = controller;
                                if (widget
                                    .activityData
                                    .routePoints
                                    .isNotEmpty) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngBounds(
                                      LatLngBoundsUtils.fromLatLngList(
                                        widget.activityData.routePoints,
                                      ),
                                      50.0,
                                    ),
                                  );
                                }
                              },
                              initialCameraPosition: CameraPosition(
                                target:
                                    widget.activityData.routePoints.isNotEmpty
                                    ? widget.activityData.routePoints.first
                                    : const LatLng(0, 0),
                                zoom: 15,
                              ),
                              polylines: {
                                Polyline(
                                  polylineId: const PolylineId('route'),
                                  points: widget.activityData.routePoints,
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
                        if (widget.activityData.mediaPaths.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildMediaSection(),
                        ],
                        // NOVO: Seção de Parceiros
                        _buildPartnersSection(colors),
                        const SizedBox(height: 24),
                        _buildLikesSection(colors),
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
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundImage: NetworkImage(
                                  'https://i.ibb.co/L8Gj18j/avatar.png',
                                ),
                              ),
                              title: Text(
                                _comments[index],
                                style: TextStyle(color: colors.text),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          // Área de digitação do comentário na parte inferior.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(color: colors.text.withOpacity(0.12)),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 18, backgroundImage: user.profileImage),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: colors.text),
                    decoration: InputDecoration(
                      hintText: 'Adicione um comentário...',
                      hintStyle: TextStyle(color: colors.textSecondary),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o display do humor selecionado.
  Widget _buildMoodDisplay(AppColors colors) {
    final List<IconData> moodIcons = [
      Icons.sentiment_very_dissatisfied,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_satisfied,
      Icons.sentiment_very_satisfied,
    ];

    return Row(
      children: [
        Icon(
          moodIcons[widget.activityData.mood!],
          color: AppColors.primary,
          size: 20,
        ),
      ],
    );
  }

  /// Constrói a linha de estatísticas da atividade.
  Widget _buildStatsRow(AppColors colors) {
    final distance = (widget.activityData.distanceInMeters / 1000)
        .toStringAsFixed(2);
    final duration = _formatDuration(widget.activityData.duration);
    final speed = _formatSpeed(
      widget.activityData.distanceInMeters,
      widget.activityData.duration,
    );
    final calories = widget.activityData.calories.toStringAsFixed(0);

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
        children: widget.activityData.mediaPaths.map((path) {
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

  /// Constrói a seção que mostra os parceiros marcados.
  Widget _buildPartnersSection(AppColors colors) {
    // Filtra a lista de parceiros mock para encontrar os que foram marcados.
    final taggedPartners = _mockPartners
        .where((p) => widget.activityData.taggedPartnerIds.contains(p.id))
        .toList();

    if (taggedPartners.isEmpty) {
      return const SizedBox.shrink(); // Não mostra nada se não houver parceiros
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Com ',
                style: GoogleFonts.lexend(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
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
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Constrói a seção que mostra quem curtiu a atividade.
  Widget _buildLikesSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Curtidas',
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        // Lista de pessoas que curtiram
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _likers.length,
          itemBuilder: (context, index) {
            final liker = _likers[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: NetworkImage(liker.avatarUrl),
              ),
              title: Text(
                liker.name,
                style: GoogleFonts.lexend(
                  color: colors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Você pode adicionar um botão de "Seguir" aqui se quiser
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        ),
      ],
    );
  }
}

/// Widget para exibir a mídia (imagem ou vídeo) em tela cheia.
class FullScreenMediaViewer extends StatelessWidget {
  final File mediaFile;

  const FullScreenMediaViewer({super.key, required this.mediaFile});

  @override
  Widget build(BuildContext context) {
    final isVideo = [
      '.mp4',
      '.mov',
      '.avi',
    ].any((ext) => mediaFile.path.toLowerCase().endsWith(ext));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: isVideo
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, color: Colors.white, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'Player de vídeo ainda não implementado.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : InteractiveViewer(child: Image.file(mediaFile)),
      ),
    );
  }
}
