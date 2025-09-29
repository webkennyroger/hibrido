import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/activity/screens/comments_screen.dart';
import 'package:hibrido/features/activity/screens/share_activity_screen.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

class ActivityCard extends StatefulWidget {
  final ActivityData activityData;

  const ActivityCard({super.key, required this.activityData});

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

  // Calcula os limites do mapa para centralizar a rota.
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) {
      // Retorna um limite padrão se a lista estiver vazia
      return LatLngBounds(
        northeast: const LatLng(0, 0),
        southwest: const LatLng(0, 0),
      );
    }
    double x0 = list.first.latitude,
        x1 = list.first.latitude,
        y0 = list.first.longitude,
        y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: CustomColors.quaternary,
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
                color: CustomColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            // Mapa com a rota
            _buildMap(),
            const SizedBox(height: 12),
            // Estatísticas
            _buildStats(),
            const SizedBox(height: 16),
            // Botões de Ação
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage('https://i.ibb.co/L8Gj18j/avatar.png'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.activityData.userName,
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  color: CustomColors.textDark,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.directions_run,
                    color: CustomColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.activityData.runTime} - ${widget.activityData.location}',
                    style: GoogleFonts.lexend(
                      color: Colors.grey.shade600,
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
              // Aqui você pode adicionar a lógica para excluir a atividade,
              // como mostrar um diálogo de confirmação.
              // print('Excluir atividade selecionado');
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
          child: const Icon(Icons.more_vert, color: CustomColors.textDark),
        ),
      ],
    );
  }

  Widget _buildMap() {
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
              color: CustomColors.primary,
              width: 4,
            ),
          },
          onMapCreated: (controller) {
            if (widget.activityData.routePoints.isNotEmpty) {
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(
                  _boundsFromLatLngList(widget.activityData.routePoints),
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
            color: CustomColors.textDark,
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
          child: _actionButton(Icons.comment_outlined, _commentsCount, () async {
            // Navega para a tela de comentários e aguarda um resultado
            final result = await Navigator.push<List<String>>(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CommentsScreen(activityData: widget.activityData),
              ),
            );

            // Se a tela de comentários retornou uma nova lista, atualiza o estado
            if (result != null) {
              setState(() {
                _commentsCount = result.length;
              });
            }
          }),
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLiked ? CustomColors.primary : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isLiked ? CustomColors.primary : Colors.grey.shade700,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: GoogleFonts.lexend(
                color: isLiked ? CustomColors.primary : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
