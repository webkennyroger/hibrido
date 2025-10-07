import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/core/utils/map_utils.dart';
import 'package:hibrido/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';

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
      _comments.insert(0, _commentController.text.trim());
    });

    final updatedActivity = widget.activityData.copyWith(
      commentsList: _comments,
    );
    _repository.updateActivity(updatedActivity);

    _commentController.clear();
    FocusScope.of(context).unfocus(); // Esconde o teclado
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
          'Comentários',
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
                    _postComment(); // Adiciona o novo comentário
                    Navigator.of(
                      context,
                    ).pop(_comments); // Retorna a lista atualizada
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
                                  widget.activityData.runTime,
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
                        const SizedBox(height: 4),
                        Text(
                          '${(widget.activityData.distanceInMeters / 1000).toStringAsFixed(2)} km',
                          style: GoogleFonts.lexend(
                            color: colors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Você e 12 outros', // Exemplo de contagem de curtidas
                              style: GoogleFonts.lexend(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.text.withOpacity(0.1)),
                  // Lista de comentários (placeholder)
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
                    autofocus: true,
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
}
