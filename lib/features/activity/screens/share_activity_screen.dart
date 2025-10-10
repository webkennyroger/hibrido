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
import 'package:gal/gal.dart';

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

  // Captura o widget do mapa atual e retorna os bytes da imagem
  Future<Uint8List?> _captureMapImage() async {
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
      return byteData!.buffer.asUint8List();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível capturar a imagem da atividade.'),
        ),
      );
      return null;
    }
  }

  // Salva a imagem na galeria do celular
  Future<void> _saveImage() async {
    final imageBytes = await _captureMapImage();
    if (imageBytes == null) return;

    try {
      await Gal.putImageBytes(imageBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem salva na galeria!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao salvar a imagem.')));
    }
  }

  // Abre a funcionalidade de compartilhar com outros apps
  Future<void> _shareActivity() async {
    final imageBytes = await _captureMapImage();
    if (imageBytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/activity.png').create();
    await file.writeAsBytes(imageBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Confira minha corrida!');
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
            'Opções',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 24),
          // Botão para Salvar Imagem
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Salvar Imagem',
                style: GoogleFonts.lexend(
                  color: AppColors.dark().background,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Botão para Compartilhar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _shareActivity,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: colors.text.withOpacity(0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Compartilhar',
                style: GoogleFonts.lexend(
                  color: colors.text,
                  fontSize: 16,
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
