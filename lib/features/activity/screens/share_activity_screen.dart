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

  const ShareActivityScreen({super.key, required this.activityData});

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
          // print("Erro ao carregar o estilo do mapa: $error");
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
      // print('Erro ao compartilhar atividade: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível compartilhar a imagem.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Compartilhar Atividade',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.text),
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
            style: isDarkMode ? _darkMapStyle : null,
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
                color: isDarkMode ? Colors.white : AppColors.primary,
                width: 4,
              ),
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
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: colors.surface,
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
              color: colors.text,
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
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Compartilhar',
                style: GoogleFonts.lexend(
                  color: AppColors.dark().background,
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
        color: _currentPage == index ? AppColors.primary : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
