// finished_confirmation_sheet.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:image_picker/image_picker.dart';

/// Enum para as opções de esporte.
/// O ideal seria mover isso para um arquivo compartilhado, mas por enquanto ficará aqui.
enum SportOption { corrida, pedalada, caminhada }

/// Enum para as opções de privacidade.
enum PrivacyOption { public, followers, private }

/// Enum para as opções de tipo de mapa.
enum MapTypeOption { normal, satellite, hybrid }

/// Modelo simples para um parceiro de atividade (mock).
class Partner {
  final String id;
  final String name;
  final String avatarUrl;
  Partner({required this.id, required this.name, required this.avatarUrl});
}

/// Widget de confirmação que aparece após a atividade ser interrompida (Stop).
/// Ele permite ao usuário definir um título e adicionar detalhes antes de salvar.
class FinishedConfirmationSheet extends StatefulWidget {
  final ActivityData activityData;
  // O callback agora recebe o título editado
  final Function(ActivityData activityData) onSaveAndNavigate;
  final bool isEditing; // NOVO: Flag para modo de edição
  final VoidCallback onDiscard;

  const FinishedConfirmationSheet({
    super.key,
    required this.activityData,
    required this.onSaveAndNavigate,
    this.isEditing = false, // Valor padrão é false
    required this.onDiscard,
  });

  @override
  State<FinishedConfirmationSheet> createState() =>
      _FinishedConfirmationSheetState();
}

class _FinishedConfirmationSheetState extends State<FinishedConfirmationSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  // Mock data para campos novos:
  PrivacyOption _selectedPrivacy = PrivacyOption.public;
  int _partnersCount = 0;
  int? _selectedMoodIndex;
  late SportOption _selectedSport;

  // NOVO: Estado para gerenciar o tipo de mapa.
  MapType _currentMapType = MapType.normal;
  MapTypeOption _selectedMapTypeOption = MapTypeOption.normal;

  // NOVO: Estado para armazenar as imagens selecionadas.
  final List<File> _selectedMedia = [];
  final ImagePicker _picker = ImagePicker();

  // Lista de parceiros selecionados (usando IDs).
  final Set<String> _selectedPartnerIds = {};

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
    // Se estiver editando, preenche os campos com os dados existentes.
    _titleController = TextEditingController(
      text: widget.activityData.activityTitle,
    );
    _notesController = TextEditingController(
      text: widget.activityData.notes ?? '',
    );
    _selectedSport = _sportFromString(widget.activityData.sport);
    _selectedMoodIndex = widget.activityData.mood;

    // Preenche os parceiros marcados
    _selectedPartnerIds.addAll(widget.activityData.taggedPartnerIds);
    _partnersCount = _selectedPartnerIds.length;

    // Preenche as imagens existentes se estiver editando
    if (widget.isEditing) {
      _selectedMedia.addAll(
        widget.activityData.mediaPaths.map((path) => File(path)),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Funções Auxiliares ---

  // Converte uma string de título para o enum SportOption
  SportOption _sportFromString(String title) {
    switch (title.toLowerCase()) {
      case 'pedalada':
        return SportOption.pedalada;
      case 'caminhada':
        return SportOption.caminhada;
      case 'corrida':
      default:
        return SportOption.corrida;
    }
  }

  // Mapeia o enum do esporte para uma string de rótulo.
  String _getSportLabel(SportOption option) {
    switch (option) {
      case SportOption.corrida:
        return 'Corrida';
      case SportOption.pedalada:
        return 'Pedalada';
      case SportOption.caminhada:
        return 'Caminhada';
    }
  }

  // Mapeia o enum do esporte para o ícone de marcação
  IconData _getSportIcon(SportOption option) {
    switch (option) {
      case SportOption.corrida:
        return Icons.directions_run;
      case SportOption.pedalada:
        return Icons.directions_bike;
      case SportOption.caminhada:
        return Icons.directions_walk;
    }
  }

  // Função para gerar um título padrão com base no período do dia.
  String _generateDefaultTitle() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'MANHÃ DO DIA';
    } else if (hour >= 12 && hour < 18) {
      return 'TARDE DO DIA';
    } else {
      return 'NOITE DO DIA';
    }
  }

  // Converte o enum de privacidade para uma string para salvar.
  String _privacyOptionToString(PrivacyOption option) {
    switch (option) {
      case PrivacyOption.public:
        return 'public';
      case PrivacyOption.followers:
        return 'followers';
      case PrivacyOption.private:
        return 'private';
    }
  }

  // Função auxiliar para formatar a distância (para KM)
  String _formatDistance(double distanceInMeters) {
    return (distanceInMeters / 1000).toStringAsFixed(2);
  }

  // Função auxiliar para formatar a duração (MM:SS)
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Função auxiliar para formatar a velocidade
  String _formatSpeed(double distanceInMeters, Duration duration) {
    if (duration.inSeconds == 0) return '0.00';
    // Velocidade em km/h
    final speedKmH = (distanceInMeters / 1000) / (duration.inSeconds / 3600);
    return speedKmH.toStringAsFixed(2);
  }

  // NOVO: Mostra um menu para escolher entre Câmera e Galeria.
  void _showMediaSourceActionSheet(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.image, color: colors.text),
                title: Text(
                  'Foto da Galeria',
                  style: TextStyle(color: colors.text),
                ),
                onTap: () {
                  _pickMedia(ImageSource.gallery, isVideo: false);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam, color: colors.text),
                title: Text(
                  'Vídeo da Galeria',
                  style: TextStyle(color: colors.text),
                ),
                onTap: () {
                  _pickMedia(ImageSource.gallery, isVideo: true);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: colors.text),
                title: Text('Câmera', style: TextStyle(color: colors.text)),
                onTap: () {
                  _pickMedia(ImageSource.camera, isVideo: false);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // NOVO: Lógica para capturar a imagem.
  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    final XFile? pickedFile;
    if (isVideo) {
      pickedFile = await _picker.pickVideo(source: source);
    } else {
      pickedFile = await _picker.pickImage(source: source);
    }

    if (pickedFile != null) {
      final file = pickedFile; // Create a local, non-nullable variable.
      setState(() {
        _selectedMedia.add(File(file.path));
      });
    }
  }

  // NOVO: Mostra o modal para selecionar o tipo de mapa.
  void _showMapTypeSelectorModal(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tipos de mapa',
                style: GoogleFonts.lexend(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMapOptionItem(
                    context: context,
                    icon: 'assets/images/maps/map_standard.png',
                    label: 'Padrão',
                    option: MapTypeOption.normal,
                  ),
                  _buildMapOptionItem(
                    context: context,
                    icon: 'assets/images/maps/map_satellite.png',
                    label: 'Satélite',
                    option: MapTypeOption.satellite,
                  ),
                  _buildMapOptionItem(
                    context: context,
                    icon: 'assets/images/maps/map_hybrid.png',
                    label: 'Híbrido',
                    option: MapTypeOption.hybrid,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // NOVO: Constrói um item de opção de mapa.
  Widget _buildMapOptionItem({
    required BuildContext context,
    required String icon,
    required String label,
    required MapTypeOption option,
  }) {
    final colors = AppColors.of(context);
    final isSelected = _selectedMapTypeOption == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMapTypeOption = option;
          _currentMapType = switch (option) {
            MapTypeOption.normal => MapType.normal,
            MapTypeOption.satellite => MapType.satellite,
            MapTypeOption.hybrid => MapType.hybrid,
          };
        });
        Navigator.pop(context); // Fecha o modal após a seleção.
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(icon, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.lexend(color: colors.text, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- Componentes da UI ---

  /// Constrói um card individual para exibir uma métrica (ex: distância, tempo).
  Widget _buildMetricsCard({
    required Color color,
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
    final colors = AppColors.of(context);

    // Container é o corpo do card.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      // Column organiza o ícone, o valor e o rótulo verticalmente.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone que representa a métrica.
          Icon(icon, color: iconColor ?? Colors.white, size: 24),
          const SizedBox(height: 8),
          // Texto principal, exibindo o valor da métrica (ex: "6,28").
          Text(
            title,
            style: GoogleFonts.lexend(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Texto secundário, exibindo a unidade da métrica (ex: "KM").
          Text(
            value,
            style: GoogleFonts.lexend(
              color: colors.text.withOpacity(0.7),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a linha para seleção do tipo de atividade.
  Widget _buildSportSelectorRow() {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: GestureDetector(
        onTap: () => _showSportSelectorModal(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: colors.text.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Icon(
                _getSportIcon(_selectedSport),
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _getSportLabel(_selectedSport),
                  style: GoogleFonts.lexend(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostra um modal para o usuário selecionar o esporte.
  void _showSportSelectorModal(BuildContext context) {
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Escolha um esporte',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 20),
              // Itera sobre as opções de esporte e cria um botão para cada
              for (var sport in SportOption.values)
                ListTile(
                  leading: Icon(_getSportIcon(sport), color: AppColors.primary),
                  title: Text(
                    _getSportLabel(sport),
                    style: GoogleFonts.lexend(color: colors.text),
                  ),
                  onTap: () {
                    setState(() => _selectedSport = sport);
                    Navigator.pop(context);
                  },
                  trailing: _selectedSport == sport
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Mostra um modal para selecionar parceiros de atividade.
  void _showPartnerSelectorModal(BuildContext context) {
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Usa um StatefulWidget para gerenciar a seleção dentro do modal.
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Marcar Amigos',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Lista de parceiros com checkboxes.
                  ..._mockPartners.map((partner) {
                    return CheckboxListTile(
                      title: Text(
                        partner.name,
                        style: GoogleFonts.lexend(color: colors.text),
                      ),
                      secondary: CircleAvatar(
                        backgroundImage: NetworkImage(partner.avatarUrl),
                      ),
                      value: _selectedPartnerIds.contains(partner.id),
                      onChanged: (bool? selected) {
                        modalSetState(() {
                          if (selected == true) {
                            _selectedPartnerIds.add(partner.id);
                          } else {
                            _selectedPartnerIds.remove(partner.id);
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  // Botão para confirmar a seleção.
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _partnersCount = _selectedPartnerIds.length;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      'CONCLUÍDO',
                      style: GoogleFonts.lexend(
                        color: AppColors.dark().background,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// NOVO: Constrói a seção de mídia (mapa, fotos, adicionar).
  Widget _buildMediaSection() {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          Text(
            'Atividade',
            style: GoogleFonts.lexend(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Lista horizontal de mídias
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMapCard(),
                const SizedBox(width: 12),
                ..._selectedMedia.map(
                  (mediaFile) => Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: _buildMediaThumbnail(mediaFile),
                  ),
                ),
                _buildAddMediaCard(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Botão para alterar tipo de mapa
          Center(
            child: OutlinedButton(
              onPressed: () => _showMapTypeSelectorModal(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Alterar tipo de mapa',
                style: GoogleFonts.lexend(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// NOVO: Card de miniatura do mapa.
  Widget _buildMapCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        height: 120,
        color: Colors.grey.shade300,
        child: Stack(
          children: [
            GoogleMap(
              mapType: _currentMapType,
              initialCameraPosition: CameraPosition(
                target: widget.activityData.routePoints.isNotEmpty
                    ? widget.activityData.routePoints.first
                    : const LatLng(0, 0), // Evita erro se a lista estiver vazia
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
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              myLocationButtonEnabled: false,
            ),
            const Positioned(
              bottom: 8,
              left: 8,
              child: Text(
                'Mapa da Rota',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NOVO: Card de miniatura da foto selecionada.
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

  /// NOVO: Card para adicionar nova foto.
  Widget _buildAddMediaCard() {
    return GestureDetector(
      onTap: () => _showMediaSourceActionSheet(context),
      child: DottedBorder(
        color: AppColors.primary,
        strokeWidth: 2,
        radius: const Radius.circular(12),
        borderType: BorderType.RRect,
        dashPattern: const [8, 4],
        child: SizedBox(
          width: 120,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Adicionar mídia',
                style: GoogleFonts.lexend(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o campo de texto para o título da atividade.
  Widget _buildTitleField() {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nome',
            style: GoogleFonts.lexend(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: GoogleFonts.lexend(color: colors.text, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surface,
              hintText: _generateDefaultTitle(),
              hintStyle: GoogleFonts.lexend(color: colors.textSecondary),
              // Borda padrão, quando o campo não está focado
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: colors.text.withOpacity(0.12)),
              ),
              // Borda que aparece quando o campo está focado
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o campo de texto para as anotações da atividade.
  Widget _buildNotesField() {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anotações',
            style: GoogleFonts.lexend(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4, // Define uma altura inicial para o campo
            style: GoogleFonts.lexend(color: colors.text, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surface,
              hintText: 'Como foi, ${widget.activityData.userName}?',
              hintStyle: GoogleFonts.lexend(color: colors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: colors.text.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o título para a seção de Visibilidade.
  Widget _buildVisibilityHeader() {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        'Visibilidade',
        style: GoogleFonts.lexend(
          color: colors.text,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    final colors = AppColors.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60, // Altura fixa para os botões
          margin: EdgeInsets.symmetric(horizontal: isPrimary ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: isPrimary ? AppColors.primary : colors.surface,
            border: isPrimary
                ? null
                : Border.all(
                    color: AppColors.error, // Cor vermelha
                    width: 1.5,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(100),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.lexend(
                color: isPrimary
                    ? AppColors.dark().background
                    : AppColors.error,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Principal ---

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Calcula as estatísticas
    final distance = _formatDistance(widget.activityData.distanceInMeters);
    final duration = _formatDuration(widget.activityData.duration);
    final speed = _formatSpeed(
      widget.activityData.distanceInMeters,
      widget.activityData.duration,
    );
    final calories = widget.activityData.calories.toStringAsFixed(0);

    // Usaremos um `Stack` para colocar os botões acima do fundo escuro, na parte inferior.
    return Scaffold(
      backgroundColor: colors.surface, // Cor de fundo clara
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isEditing ? 'Editar Atividade' : 'Detalhes da atividade',
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              widget.isEditing ? Icons.close : Icons.delete_outline,
              color: AppColors.error,
            ),
            onPressed: widget.onDiscard,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0), // Borda inferior do AppBar
          child: Divider(height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. LINHA DE ESTATÍSTICAS (igual à home)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildMetricsCard(
                    color: colors.surface,
                    icon: Icons.directions_run,
                    iconColor: AppColors.primary,
                    title: distance,
                    value: 'KM',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricsCard(
                    color: colors.surface,
                    icon: Icons.schedule,
                    iconColor: AppColors.primary,
                    title: duration,
                    value: 'TEMPO',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricsCard(
                    color: colors.surface,
                    icon: Icons.speed,
                    iconColor: AppColors.primary,
                    title: speed,
                    value: 'KM/H',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricsCard(
                    color: colors.surface,
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.primary,
                    title: calories,
                    value: 'CALORIAS',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. INFORMAÇÕES ADICIONAIS
            const Divider(thickness: 1),
            const SizedBox(height: 24),

            _buildMoodSelector(), // Seletor de humor com ícones
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 24),
            _buildTitleField(), // Campo para o nome da atividade
            const SizedBox(height: 24),
            _buildNotesField(), // Campo de texto para anotações
            const SizedBox(height: 24),
            _buildSportSelectorRow(), // Seletor de tipo de atividade
            const SizedBox(height: 32),
            _buildInfoRow(
              Icons.group,
              'Parceiros de Atividade',
              '$_partnersCount',
              () => _showPartnerSelectorModal(context),
            ),
            const SizedBox(height: 24),
            _buildMediaSection(), // NOVA seção de mídia
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        color: colors.surface, // Mesma cor do fundo para integração
        child: Row(
          children: [
            // Botão Descartar (secundário, vermelho)
            _buildActionButton(
              text: 'DESCARTAR',
              onTap: widget.onDiscard,
              isPrimary: false,
            ),
            const SizedBox(width: 8),
            // Botão Salvar (principal, verde)
            _buildActionButton(
              text: 'SALVAR',
              onTap: () {
                // Se o campo estiver vazio, usa o título padrão.
                String finalTitle = _titleController.text.trim();
                if (finalTitle.isEmpty) {
                  // Se o título estiver vazio, usa o nome do esporte como título.
                  finalTitle = _getSportLabel(_selectedSport);
                }

                final finalActivityData = widget.activityData.copyWith(
                  distanceInMeters: widget.activityData.distanceInMeters,
                  duration: widget.activityData.duration,
                  calories: widget.activityData.calories,
                  routePoints: widget.activityData.routePoints,
                  activityTitle: finalTitle,
                  sport: _getSportLabel(_selectedSport),
                  mood: _selectedMoodIndex,
                  privacy: _privacyOptionToString(_selectedPrivacy),
                  notes: _notesController.text.trim(),
                  taggedPartnerIds: _selectedPartnerIds.toList(),
                  mediaPaths: _selectedMedia.map((file) => file.path).toList(),
                );
                widget.onSaveAndNavigate(finalActivityData);
              },
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói a seção para o usuário avaliar o humor da corrida.
  Widget _buildMoodSelector() {
    final colors = AppColors.of(context);

    final List<IconData> moodIcons = [
      Icons.sentiment_very_dissatisfied,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_satisfied,
      Icons.sentiment_very_satisfied,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como foi essa corrida?',
            style: GoogleFonts.lexend(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(moodIcons.length, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMoodIndex = index;
                  });
                },
                child: Icon(
                  moodIcons[index],
                  color: _selectedMoodIndex == index
                      ? AppColors.primary
                      : colors.textSecondary,
                  size: 36,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Constrói uma linha de informação adicional com ícone, label e valor/ação
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
        child: Row(
          children: [
            Icon(icon, color: colors.text, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lexend(
                  color: colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Row(
              children: [
                if (label == 'Parceiros de Atividade' &&
                    int.tryParse(value) != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: int.parse(value) > 0
                          ? AppColors.primary
                          : colors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.lexend(
                        color: AppColors.dark().background,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: GoogleFonts.lexend(
                      color: (value == 'Adicionada'
                          ? AppColors.primary
                          : colors.text.withOpacity(0.5)),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: colors.text.withOpacity(0.26),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
