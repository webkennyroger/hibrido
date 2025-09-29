import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/custom_colors.dart';

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

  @override
  void initState() {
    super.initState();
    // Ouve as mudanças no campo de texto para habilitar/desabilitar o botão "Postar".
    _commentController.addListener(() {
      setState(() {
        _isPostButtonEnabled = _commentController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Calcula os limites do mapa para centralizar a rota.
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) {
      return LatLngBounds(
        northeast: const LatLng(0, 0),
        southwest: const LatLng(0, 0),
      );
    }
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Comentários',
          style: GoogleFonts.lexend(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isPostButtonEnabled
                ? () {
                    // Lógica para postar o comentário
                    Navigator.of(context).pop();
                  }
                : null,
            child: Text(
              'Postar',
              style: GoogleFonts.lexend(
                color: _isPostButtonEnabled
                    ? CustomColors.primary
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
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                'https://i.ibb.co/L8Gj18j/avatar.png',
                              ),
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
                                  ),
                                ),
                                Text(
                                  widget.activityData.runTime,
                                  style: GoogleFonts.lexend(
                                    color: Colors.grey.shade600,
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(widget.activityData.distanceInMeters / 1000).toStringAsFixed(2)} km',
                          style: GoogleFonts.lexend(
                            color: Colors.grey.shade700,
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
                                      _boundsFromLatLngList(
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
                                  color: CustomColors.primary,
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
                            const Icon(
                              Icons.thumb_up,
                              color: CustomColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Você e 12 outros', // Exemplo de contagem de curtidas
                              style: GoogleFonts.lexend(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Lista de comentários (placeholder)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80.0),
                    child: Center(
                      child: Text(
                        'Seja o primeiro a comentar!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Área de digitação do comentário na parte inferior.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    'https://i.ibb.co/L8Gj18j/avatar.png',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Adicione um comentário...',
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
