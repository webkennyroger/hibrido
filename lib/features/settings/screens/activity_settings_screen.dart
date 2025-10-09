import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

// Enums movidos para este arquivo para evitar erros de importação.
// Enum para definir as opções de unidade
enum DistanceUnit { km, miles }

// Enum para definir as opções de exibição
enum PaceOrSpeed { pace, speed }

class ActivitySettingsScreen extends StatefulWidget {
  const ActivitySettingsScreen({super.key});

  @override
  State<ActivitySettingsScreen> createState() => _ActivitySettingsScreenState();
}

class _ActivitySettingsScreenState extends State<ActivitySettingsScreen> {
  // Mock data para gerenciar os estados dos switches
  bool _autoPause = true;
  bool _voiceFeedback = true;
  bool _spotifyIntegration = false;
  bool _youtubeMusicIntegration = false; // Novo estado
  bool _countdownTimer = true; // Novo estado
  bool _mapTypeHybrid = false;
  bool _mapTypeSatellite = false; // Novo estado
  bool _nightMode = true; // Novo estado
  bool _showCalories = true; // Novo estado
  bool _autoPost = true;
  DistanceUnit _selectedUnit = DistanceUnit.km;
  PaceOrSpeed _selectedPaceOrSpeed = PaceOrSpeed.pace;

  /// Constrói um item de configuração com um título, descrição opcional e um Switch.
  Widget _buildActivityItem({
    required String title,
    String? description,
    required IconData icon,
    required bool switchValue,
    required ValueChanged<bool> onSwitchChanged,
  }) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surface, // Fundo Cinza Claro (Card)
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colors.text, // Ícone escuro
            size: 26,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    color: colors.text, // Texto escuro
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null)
                  Text(
                    description,
                    style: GoogleFonts.lexend(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: switchValue,
            onChanged: onSwitchChanged,
            activeColor: AppColors.primary, // Botão ativo verde
            inactiveThumbColor: colors.text,
            inactiveTrackColor: colors.text.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  /// Constrói um item de configuração que navega para outra tela.
  Widget _buildNavigationItem({
    required String title,
    String? description,
    required IconData icon,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: colors.surface, // Fundo Cinza Claro (Card)
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: colors.text, // Ícone escuro
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lexend(
                      color: colors.text, // Texto escuro
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description,
                      style: GoogleFonts.lexend(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              currentValue,
              style: GoogleFonts.lexend(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: colors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra um modal para o usuário selecionar a unidade de distância.
  void _showUnitSelectionModal(BuildContext context) {
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unidades de Distância',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var unit in DistanceUnit.values)
                    ListTile(
                      title: Text(
                        unit == DistanceUnit.km ? 'Quilômetros' : 'Milhas',
                        style: GoogleFonts.lexend(color: colors.text),
                      ),
                      onTap: () {
                        setState(() => _selectedUnit = unit);
                        Navigator.pop(context);
                      },
                      trailing: _selectedUnit == unit
                          ? Icon(Icons.check, color: AppColors.primary)
                          : null,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Mostra um modal para o usuário selecionar entre Ritmo e Velocidade.
  void _showPaceSpeedSelectionModal(BuildContext context) {
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Exibição de Métrica',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var option in PaceOrSpeed.values)
                    ListTile(
                      title: Text(
                        option == PaceOrSpeed.pace
                            ? 'Ritmo (min/km)'
                            : 'Velocidade (km/h)',
                        style: GoogleFonts.lexend(color: colors.text),
                      ),
                      onTap: () {
                        setState(() => _selectedPaceOrSpeed = option);
                        Navigator.pop(context);
                      },
                      trailing: _selectedPaceOrSpeed == option
                          ? Icon(Icons.check, color: AppColors.primary)
                          : null,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Widget Principal ---

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background, // Fundo escuro
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ajuste de Atividades',
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Texto de cabeçalho
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Defina as opções padrão para o início das suas atividades:',
                style: GoogleFonts.lexend(
                  color: colors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),

            // 1. Pausa Automática
            _buildActivityItem(
              title: 'Pausa Automática',
              description: 'Pausar o rastreamento quando você parar.',
              icon: Icons.pause_circle_outline,
              switchValue: _autoPause,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _autoPause = newValue;
                });
              },
            ),

            // Novo: Cronômetro de Contagem Regressiva
            _buildActivityItem(
              title: 'Contagem Regressiva',
              description:
                  'Inicia um cronômetro de 3 segundos antes de começar.',
              icon: Icons.timer_3_outlined,
              switchValue: _countdownTimer,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _countdownTimer = newValue;
                });
              },
            ),
            // 3. Feedback por Voz
            _buildActivityItem(
              title: 'Feedback por Voz',
              description: 'Alertas de voz sobre progresso e métricas.',
              icon: Icons.record_voice_over_outlined,
              switchValue: _voiceFeedback,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _voiceFeedback = newValue;
                });
              },
            ),

            // 4. Integração Spotify
            _buildActivityItem(
              title: 'Spotify',
              description: 'Controle a música diretamente no mapa.',
              icon: Icons.music_note_outlined,
              switchValue: _spotifyIntegration,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _spotifyIntegration = newValue;
                });
              },
            ),

            // Novo: Integração Youtube Music
            _buildActivityItem(
              title: 'Youtube Music',
              description: 'Controle a música diretamente no mapa.',
              icon: Icons.play_circle_outline,
              switchValue: _youtubeMusicIntegration,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _youtubeMusicIntegration = newValue;
                });
              },
            ),

            const SizedBox(height: 24),

            // Subtítulo
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Opções de Visualização:',
                style: GoogleFonts.lexend(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 4. Tipo de Mapa Híbrido
            _buildActivityItem(
              title: 'Mapa Híbrido',
              description: 'Combina o mapa padrão com imagens de satélite.',
              icon: Icons.map_outlined,
              switchValue: _mapTypeHybrid,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _mapTypeHybrid = newValue;
                });
              },
            ),

            // Novo: Mapa via Satélite
            _buildActivityItem(
              title: 'Mapa via Satélite',
              description: 'Mostra o mapa no modo satélite.',
              icon: Icons.satellite_alt_outlined,
              switchValue: _mapTypeSatellite,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _mapTypeSatellite = newValue;
                });
              },
            ),

            // Novo: Modo Noturno
            _buildActivityItem(
              title: 'Modo Noturno',
              description:
                  'A tela de registro de atividades fica no modo escuro.',
              icon: Icons.dark_mode_outlined,
              switchValue: _nightMode,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _nightMode = newValue;
                });
              },
            ),

            // Novo: Mostrar Calorias
            _buildActivityItem(
              title: 'Mostrar Calorias',
              description: 'Exibe a queima de calorias estimada em tempo real.',
              icon: Icons.local_fire_department_outlined,
              switchValue: _showCalories,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _showCalories = newValue;
                });
              },
            ),

            // Alterado: Unidades de Distância
            _buildNavigationItem(
              title: 'Unidades de Distância',
              description: 'Alternar entre KM (métrico) e Milhas (imperial).',
              icon: Icons.square_foot_outlined,
              currentValue: _selectedUnit == DistanceUnit.km ? 'KM' : 'Milhas',
              onTap: () => _showUnitSelectionModal(context),
            ),

            // Novo: Velocidade ou Ritmo
            _buildNavigationItem(
              title: 'Velocidade ou Ritmo',
              description: 'Alternar entre velocidade ou ritmo.',
              icon: Icons.speed_outlined,
              currentValue: _selectedPaceOrSpeed == PaceOrSpeed.pace
                  ? 'Ritmo'
                  : 'Velocidade',
              onTap: () => _showPaceSpeedSelectionModal(context),
            ),

            const SizedBox(height: 24),

            // Subtítulo
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Compartilhamento:',
                style: GoogleFonts.lexend(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 6. Postagem Automática
            _buildActivityItem(
              title: 'Postagem Automática',
              description:
                  'Compartilhar atividades na sua timeline após salvar.',
              icon: Icons.share_outlined,
              switchValue: _autoPost,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _autoPost = newValue;
                });
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
