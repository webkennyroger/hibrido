// finished_confirmation_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';

/// Widget de confirmação que aparece após a atividade ser interrompida (Stop).
/// Ele permite ao usuário definir um título e adicionar detalhes antes de salvar.
class FinishedConfirmationSheet extends StatefulWidget {
  final ActivityData activityData;
  // O callback agora recebe o título editado
  final Function(String title) onSaveAndNavigate;
  final VoidCallback onDiscard;

  const FinishedConfirmationSheet({
    super.key,
    required this.activityData,
    required this.onSaveAndNavigate,
    required this.onDiscard,
  });

  @override
  State<FinishedConfirmationSheet> createState() =>
      _FinishedConfirmationSheetState();
}

class _FinishedConfirmationSheetState extends State<FinishedConfirmationSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  String _defaultTitle = '';
  // Mock data para campos novos:
  String _selectedMood = 'Neutro';
  String _selectedPrivacy = 'Público';
  int _partnersCount = 0;

  @override
  void initState() {
    super.initState();
    _defaultTitle = _generateDefaultTitle(widget.activityData);

    // O título inicial é o título da atividade, ou o título padrão se for nulo
    _titleController = TextEditingController(
      text: widget.activityData.activityTitle.isEmpty
          ? _defaultTitle
          : widget.activityData.activityTitle,
    );
    // Inicializa o controller de anotações (assumindo que o ActivityData não tem campo de notas)
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Funções Auxiliares ---

  // Função auxiliar para gerar um título padrão
  String _generateDefaultTitle(ActivityData data) {
    final activityType = data.activityTitle.isNotEmpty
        ? data.activityTitle
        : 'Sua Atividade';
    final formatter = DateFormat('dd/MM HH:mm');
    return '$activityType em ${formatter.format(DateTime.now())}';
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

  // --- Componentes da UI ---

  /// Constrói um card individual para exibir uma métrica (ex: distância, tempo).
  Widget _buildMetricsCard({
    required Color color,
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
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
              color: CustomColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Texto secundário, exibindo a unidade da métrica (ex: "KM").
          Text(
            value,
            style: GoogleFonts.lexend(
              color: CustomColors.textDark.withAlpha((255 * 0.7).round()),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60, // Altura fixa para os botões
          margin: EdgeInsets.symmetric(horizontal: isPrimary ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: isPrimary
                ? CustomColors.primary
                : CustomColors.quaternary.withOpacity(
                    0.95,
                  ), // Fundo escuro do sheet
            border: isPrimary
                ? null
                : Border.all(
                    color: CustomColors.quinary, // Cor vermelha
                    width: 1.5,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: CustomColors.primary.withAlpha(100),
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
                    ? CustomColors
                          .tertiary // Texto preto/escuro
                    : CustomColors.quinary, // Texto vermelho
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Constrói o modal para adicionar anotações (apenas a lógica de UI)
  void _showNotesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        // Usar o `Padding` com `viewInsets` para evitar o teclado
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: CustomColors.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                Text(
                  'Anotações da Atividade',
                  style: GoogleFonts.lexend(
                    color: CustomColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: GoogleFonts.lexend(color: CustomColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Digite suas anotações aqui...',
                      hintStyle: GoogleFonts.lexend(
                        color: CustomColors.textDark.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(
                      () {},
                    ); // Força a reconstrução do botão de anotação
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.primary,
                  ),
                  child: Text(
                    'CONCLUÍDO',
                    style: GoogleFonts.lexend(color: CustomColors.tertiary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Widget Principal ---

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: CustomColors.quaternary, // Cor de fundo clara
      appBar: AppBar(
        backgroundColor: CustomColors.quaternary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CustomColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detalhes da atividade',
          style: GoogleFonts.lexend(
            color: CustomColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: CustomColors.quinary),
            onPressed: widget.onDiscard,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: Colors.black12, height: 1.0),
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
                    color: CustomColors.card,
                    icon: Icons.directions_run,
                    iconColor: CustomColors.primary,
                    title: distance,
                    value: 'KM',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricsCard(
                    color: CustomColors.card,
                    icon: Icons.schedule,
                    iconColor: CustomColors.primary,
                    title: duration,
                    value: 'TEMPO',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricsCard(
                    color: CustomColors.card,
                    icon: Icons.speed,
                    iconColor: CustomColors.primary,
                    title: speed,
                    value: 'KM/H',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricsCard(
                    color: CustomColors.card,
                    icon: Icons.local_fire_department,
                    iconColor: CustomColors.primary,
                    title: calories,
                    value: 'CALORIAS',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. INFORMAÇÕES ADICIONAIS
            const Divider(color: Colors.black12, thickness: 1),
            const SizedBox(height: 24),

            // Linha Mood e Privacidade
            _buildInfoRow(
              Icons.emoji_emotions_outlined,
              'Humor',
              _selectedMood,
              () {
                // TODO: Implementar seleção de Mood
              },
            ),
            _buildInfoRow(Icons.lock_open, 'Privacidade', _selectedPrivacy, () {
              // TODO: Implementar seleção de Privacidade
            }),

            // Linha Parceiros
            _buildInfoRow(
              Icons.group,
              'Parceiros de Atividade',
              '$_partnersCount',
              () {
                // TODO: Implementar seleção de Parceiros
              },
            ),

            // Linha Anotações
            _buildInfoRow(
              Icons.note_alt,
              'Anotações',
              _notesController.text.isNotEmpty
                  ? 'Adicionada'
                  : 'Adicionar anotação',
              () => _showNotesModal(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        color: CustomColors.quaternary, // Mesma cor do fundo para integração
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
                widget.onSaveAndNavigate(_titleController.text);
              },
              isPrimary: true,
            ),
          ],
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
        child: Row(
          children: [
            Icon(icon, color: CustomColors.textDark, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lexend(
                  color: CustomColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.lexend(
                    color: value == 'Adicionada' || value == _selectedPrivacy
                        ? CustomColors.primary
                        : CustomColors.textDark.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black26,
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
