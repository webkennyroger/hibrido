import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareActivityScreen extends StatefulWidget {
  final ActivityData activityData;

  const ShareActivityScreen({Key? key, required this.activityData})
    : super(key: key);

  @override
  State<ShareActivityScreen> createState() => _ShareActivityScreenState();
}

class _ShareActivityScreenState extends State<ShareActivityScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Chaves para capturar os widgets dos mapas como imagens
  final GlobalKey _lightMapKey = GlobalKey();
  final GlobalKey _darkMapKey = GlobalKey();

  // Estilo JSON para o mapa escuro (simulando fundo transparente)
  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    // Carrega o estilo do mapa escuro a partir dos assets
    DefaultAssetBundle.of(context)
        .loadString('assets/map_style_dark.json')
        .then((string) {
          _darkMapStyle = string;
        })
        .catchError((error) {
          print("Erro ao carregar o estilo do mapa: $error");
        });
  }

  // Captura o widget do mapa atual como uma imagem
  Future<void> _shareActivity() async {
    try {
      // Escolhe a chave correta com base na página atual
      GlobalKey keyToCapture = _currentPage == 0 ? _lightMapKey : _darkMapKey;

      RenderRepaintBoundary boundary =
          keyToCapture.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Salva a imagem em um arquivo temporário
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/activity.png').create();
      await file.writeAsBytes(pngBytes);

      // Compartilha o arquivo usando o share_plus
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Confira minha corrida!');
    } catch (e) {
      print('Erro ao compartilhar atividade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível compartilhar a imagem.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.secondary,
      appBar: AppBar(
        backgroundColor: CustomColors.secondary,
        elevation: 0,
        title: Text(
          'Compartilhar Atividade',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: CustomColors.textDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: CustomColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Slider com os mapas
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Mapa 1: Estilo Claro (Completo)
                _buildMapCard(_lightMapKey, false),
                // Mapa 2: Estilo Escuro (Fundo "transparente")
                _buildMapCard(_darkMapKey, true),
              ],
            ),
          ),
          // Indicador de página
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) => _buildDot(index: index)),
          ),
          const SizedBox(height: 24),
          // Seção de compartilhamento
          _buildShareSection(),
        ],
      ),
    );
  }

  // Constrói o card que contém o mapa
  Widget _buildMapCard(GlobalKey key, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: RepaintBoundary(
        key: key,
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
                color: isDarkMode ? Colors.white : CustomColors.primary,
                width: 4,
              ),
            },
            onMapCreated: (controller) {
              if (isDarkMode) {
                controller.setMapStyle(_darkMapStyle);
              }
              if (widget.activityData.routePoints.isNotEmpty) {
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    _boundsFromLatLngList(widget.activityData.routePoints),
                    60.0, // padding
                  ),
                );
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),
      ),
    );
  }

  // Constrói a seção inferior com os botões de compartilhamento
  Widget _buildShareSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: const BoxDecoration(
        color: CustomColors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Compartilhar em',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CustomColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          // Aqui você pode adicionar ícones de apps específicos,
          // mas um botão genérico é mais flexível.
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _shareActivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Compartilhar',
                style: GoogleFonts.lexend(
                  color: CustomColors.tertiary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Constrói o indicador de página (bolinhas)
  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? CustomColors.primary : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  // Função auxiliar para calcular os limites do mapa
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) {
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
}
