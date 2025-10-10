import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/activity/screens/comments_screen.dart';
import 'package:hibrido/features/activity/screens/share_activity_screen.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/map/screens/finished_confirmation_sheet.dart';
import 'package:hibrido/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:hibrido/core/utils/map_utils.dart';
import 'package:hibrido/widgets/full_screen_media_viewer.dart';

// Enum para as opções de privacidade, para manter a consistência.
enum PrivacyOption { public, followers, private }

class ActivityCard extends StatefulWidget {
  final ActivityData activityData;
  final VoidCallback onDelete; // Callback para notificar a exclusão
  final Function(ActivityData)
  onUpdate; // Callback para notificar a atualização

  const ActivityCard({
    super.key,
    required this.activityData,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  final ActivityRepository _repository = ActivityRepository();

  // Formata a duração para o formato MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void initState() {
    super.initState();
    // Inicializa o estado local com os dados do widget
    _isLiked = widget.activityData.isLiked;
    _likesCount = widget.activityData.likes;
    _commentsCount = widget.activityData.commentsList.length;
  }

  @override
  void didUpdateWidget(covariant ActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se os dados da atividade mudaram, atualiza o estado local do card.
    if (widget.activityData != oldWidget.activityData) {
      setState(() {
        _isLiked = widget.activityData.isLiked;
        _likesCount = widget.activityData.likes;
        _commentsCount = widget.activityData.commentsList.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Card(
        color: colors.surface,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do Card
              _buildHeader(context),
              const SizedBox(height: 12),
              // Título da Atividade
              Text(
                widget.activityData.activityTitle,
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: colors.text,
                ),
              ),
              // NOVO: Adiciona a descrição da atividade se ela existir.
              if (widget.activityData.notes != null &&
                  widget.activityData.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.activityData.notes!,
                  style: GoogleFonts.lexend(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 3, // Limita a 3 linhas para não ocupar muito espaço
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // Mapa com a rota
              _buildMediaSection(), // NOVO: Seção de Mídia
              const SizedBox(height: 16),
              // Estatísticas
              _buildStats(),
              const SizedBox(height: 16),
              // Botões de Ação
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // Mapeia o esporte para o ícone correspondente.
  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'pedalada':
        return Icons.directions_bike;
      case 'caminhada':
        return Icons.directions_walk;
      case 'corrida':
      default:
        return Icons.directions_run;
    }
  }

  Widget _buildHeader(BuildContext context) {
    final colors = AppColors.of(context);
    final user = context.watch<UserProvider>().user;

    return Row(
      children: [
        CircleAvatar(radius: 20, backgroundImage: user.profileImage),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.activityData.userName,
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              Row(
                children: [
                  Icon(
                    _getSportIcon(widget.activityData.sport),
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.activityData.runTime} - ${widget.activityData.location}',
                    style: GoogleFonts.lexend(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              // Mostra o diálogo de confirmação antes de excluir.
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Excluir Atividade'),
                    content: const Text(
                      'Tem certeza de que deseja excluir esta atividade? Esta ação não pode ser desfeita.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Fecha o diálogo
                        },
                      ),
                      TextButton(
                        child: const Text(
                          'Excluir',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () async {
                          Navigator.of(dialogContext).pop(); // Fecha o diálogo
                          // Chama o repositório para excluir a atividade
                          await _repository.deleteActivity(
                            widget.activityData.id,
                          );
                          // Chama o callback para notificar a tela pai
                          widget.onDelete();
                        },
                      ),
                    ],
                  );
                },
              );
            } else if (value == 'edit_activity' || value == 'add_media') {
              _editActivity(context);
            } else if (value == 'edit_map_visibility') {
              _showPrivacyDialog(context);
            } else if (value == 'refresh') {
              // Simula uma atualização
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Atividade atualizada!')),
              );
              setState(() {});
            } else if (value == 'crop_activity' || value == 'save_route') {
              // Mostra uma mensagem para funcionalidades não implementadas
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Funcionalidade "${_getMenuLabel(value)}" ainda não implementada.',
                  ),
                ),
              );
            } else {
              // print('$value selecionado');
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'add_media',
              child: Text('Adicionar midia'),
            ),
            const PopupMenuItem<String>(
              value: 'edit_activity',
              child: Text('Editar atividade'),
            ),
            const PopupMenuItem<String>(
              value: 'crop_activity',
              child: Text('Recortar atividade'),
            ),
            const PopupMenuItem<String>(
              value: 'edit_map_visibility',
              child: Text('Editar visibilidade do mapa'),
            ),
            const PopupMenuItem<String>(
              value: 'save_route',
              child: Text('Salvar rota'),
            ),
            const PopupMenuItem<String>(
              value: 'refresh',
              child: Text('Atualizar'),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Excluir atividade'),
            ),
          ],
          child: Icon(Icons.more_vert, color: colors.text),
        ),
      ],
    );
  }

  /// Retorna o rótulo de texto para um valor de menu.
  String _getMenuLabel(String value) {
    switch (value) {
      case 'add_media':
        return 'Adicionar midia';
      case 'edit_activity':
        return 'Editar atividade';
      case 'crop_activity':
        return 'Recortar atividade';
      case 'edit_map_visibility':
        return 'Editar visibilidade do mapa';
      case 'save_route':
        return 'Salvar rota';
      default:
        return '';
    }
  }

  /// Navega para a tela de detalhes da atividade.
  void _navigateToDetails(BuildContext context) async {
    // A navegação para a tela de detalhes é a mesma que a de comentários.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(activityData: widget.activityData),
      ),
    );

    // Se a tela de detalhes retornou uma nova lista de comentários, atualiza o estado.
    if (result is List<String>) {
      setState(() {
        _commentsCount = result.length;
      });
    } else if (result is ActivityData) {
      // Se a atividade foi editada na tela de detalhes (futura funcionalidade)
      widget.onUpdate(result);
    } else if (result == true) {
      // Se a atividade foi deletada na tela de detalhes
      widget.onDelete();
    }
  }

  /// Abre a tela de edição da atividade.
  Future<void> _editActivity(BuildContext context) async {
    final updatedActivity = await Navigator.push<ActivityData>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FinishedConfirmationSheet(
          activityData: widget.activityData,
          isEditing: true, // Indica que estamos em modo de edição
          onSaveAndNavigate: (editedData) {
            Navigator.of(context).pop(editedData);
          },
          onDiscard: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    if (updatedActivity != null) {
      // NOVO: Salva a atividade atualizada no repositório antes de atualizar a UI.
      await _repository.updateActivity(updatedActivity);
      widget.onUpdate(updatedActivity);
    }
  }

  /// Mostra um diálogo para editar a privacidade da atividade.
  void _showPrivacyDialog(BuildContext context) {
    final colors = AppColors.of(context);
    PrivacyOption selectedOption = _privacyFromString(
      widget.activityData.privacy,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              title: Text(
                'Editar Visibilidade',
                style: GoogleFonts.lexend(color: colors.text),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: PrivacyOption.values.map((option) {
                  return RadioListTile<PrivacyOption>(
                    title: Text(
                      _getPrivacyLabel(option),
                      style: GoogleFonts.lexend(color: colors.text),
                    ),
                    value: option,
                    groupValue: selectedOption,
                    onChanged: (PrivacyOption? value) {
                      if (value != null) {
                        setDialogState(() => selectedOption = value);
                      }
                    },
                    activeColor: AppColors.primary,
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  child: Text('Cancelar', style: GoogleFonts.lexend()),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Salvar', style: GoogleFonts.lexend()),
                  onPressed: () async {
                    final updatedActivity = widget.activityData.copyWith(
                      privacy: _privacyToString(selectedOption),
                    );
                    await _repository.updateActivity(updatedActivity);
                    widget.onUpdate(updatedActivity);
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Funções auxiliares de privacidade (poderiam ser movidas para um utilitário)
  String _getPrivacyLabel(PrivacyOption option) {
    switch (option) {
      case PrivacyOption.public:
        return 'Público';
      case PrivacyOption.followers:
        return 'Apenas Seguidores';
      case PrivacyOption.private:
        return 'Privado';
    }
  }

  PrivacyOption _privacyFromString(String privacy) {
    return PrivacyOption.values.firstWhere(
      (e) => e.toString().split('.').last == privacy,
      orElse: () => PrivacyOption.public,
    );
  }

  String _privacyToString(PrivacyOption option) {
    return option.toString().split('.').last;
  }

  /// NOVO: Constrói a seção de mídia com mapa e fotos.
  Widget _buildMediaSection() {
    // Se não houver mídias e houver rota, mostra um mapa grande.
    if (widget.activityData.mediaPaths.isEmpty) {
      return SizedBox(
        height: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.activityData.routePoints.isNotEmpty
                  ? widget.activityData.routePoints.first
                  : const LatLng(0, 0),
              zoom: 14,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: widget.activityData.routePoints,
                color: AppColors.primary,
                width: 4,
              ),
            },
            onMapCreated: (controller) {
              if (widget.activityData.routePoints.isNotEmpty) {
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBoundsUtils.fromLatLngList(
                      widget.activityData.routePoints,
                    ),
                    50.0, // padding
                  ),
                );
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
          ),
        ),
      );
    } else {
      // Se houver mídias, mostra a lista horizontal.
      return SizedBox(
        height: 120, // Altura fixa para a lista de mídia
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildMapThumbnail(), // Miniatura do mapa sempre primeiro
            const SizedBox(width: 12),
            // Mapeia a lista de caminhos de mídia para widgets de miniatura
            ...widget.activityData.mediaPaths.map(
              (path) => Padding(
                padding: const EdgeInsets.only(right: 12.0),
                // NOVO: Adiciona um GestureDetector para abrir a mídia em tela cheia.
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
                  child: _buildMediaThumbnail(File(path)),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// NOVO: Card de miniatura do mapa.
  Widget _buildMapThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        height: 120,
        color: Colors.grey.shade300,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.activityData.routePoints.isNotEmpty
                ? widget.activityData.routePoints.first
                : const LatLng(0, 0),
            zoom: 14,
          ),
          polylines: {
            Polyline(
              polylineId: const PolylineId('route-preview'),
              points: widget.activityData.routePoints,
              color: AppColors.primary,
              width: 3,
            ),
          },
          onMapCreated: (controller) {
            if (widget.activityData.routePoints.isNotEmpty) {
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBoundsUtils.fromLatLngList(
                    widget.activityData.routePoints,
                  ),
                  30.0, // Padding menor para a miniatura
                ),
              );
            }
          },
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  /// NOVO: Card de miniatura da foto.
  Widget _buildMediaThumbnail(File mediaFile) {
    final isVideo = [
      '.mp4',
      '.mov',
      '.avi',
    ].any((ext) => mediaFile.path.toLowerCase().endsWith(ext));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              Container(color: Colors.black) // Fundo preto para vídeos
            else
              Image.file(mediaFile, fit: BoxFit.cover),
            if (isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          'Distância',
          '${(widget.activityData.distanceInMeters / 1000).toStringAsFixed(2)} km',
        ),
        _buildStatItem(
          'Duração',
          _formatDuration(widget.activityData.duration),
        ),
        _buildStatItem(
          'Calorias',
          '${widget.activityData.calories.toStringAsFixed(0)} kcal',
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(color: Colors.grey.shade600, fontSize: 12),
        ),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: colors.text,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // Lógica para curtir/descurtir
  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likesCount++;
      } else {
        _likesCount--;
      }
    });

    // Cria uma cópia atualizada e salva no repositório
    final updatedActivity = widget.activityData.copyWith(
      likes: _likesCount,
      isLiked: _isLiked,
    );
    _repository.updateActivity(updatedActivity);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _actionButton(
            _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            _likesCount,
            _toggleLike,
            isLiked: _isLiked,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            Icons.comment_outlined,
            _commentsCount,
            () => _navigateToDetails(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _actionButton(
            Icons.share_outlined,
            widget.activityData.shares,
            () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: ShareActivityScreen(activityData: widget.activityData),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    IconData icon,
    int count,
    VoidCallback onPressed, {
    bool isLiked = false,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLiked ? AppColors.primary : colors.text.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isLiked ? AppColors.primary : colors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: GoogleFonts.lexend(
                color: isLiked ? AppColors.primary : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// NOVO: Widget para exibir a mídia (imagem ou vídeo) em tela cheia.
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
