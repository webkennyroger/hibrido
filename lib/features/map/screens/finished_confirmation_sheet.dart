import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';

/// Widget de confirmação que aparece após a atividade ser interrompida (Stop).
/// Ele permite ao usuário definir um título e adicionar detalhes antes de salvar.
class FinishedConfirmationSheet extends StatefulWidget {
  final ActivityData activityData;
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
  // Controller para o campo de texto do título da atividade
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    // Inicializa o controller com o título da atividade como valor padrão
    _titleController = TextEditingController(
      text: widget.activityData.activityTitle,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // Função auxiliar para formatar a distância
  String _formatDistance(double distanceInMeters) {
    return (distanceInMeters / 1000).toStringAsFixed(2);
  }

  // Função auxiliar para formatar o tempo
  String _formatDuration(Duration duration) {
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo escuro
      backgroundColor: CustomColors.quaternary.withAlpha((255 * 0.95).round()),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Espaçamento superior para centralizar na tela
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),

              // Botão Fechar (X)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: widget.onDiscard,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Título Principal
              Text(
                'ATIVIDADE CONCLUÍDA',
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Campo de Título da Atividade
              _buildTitleInput(),
              const SizedBox(height: 20),

              // Botão Adicionar Foto (Simulação)
              _buildAddPhotoButton(),
              const SizedBox(height: 40),

              // Cartão de Resumo das Estatísticas
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CustomColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Distância
                    _buildStatItem(
                      'Distância',
                      _formatDistance(widget.activityData.distanceInMeters),
                      'km',
                    ),
                    const Divider(color: Colors.white12, height: 32),
                    // Duração
                    _buildStatItem(
                      'Duração',
                      _formatDuration(widget.activityData.duration),
                      '',
                    ),
                    const Divider(color: Colors.white12, height: 32),
                    // Calorias
                    _buildStatItem(
                      'Calorias',
                      widget.activityData.calories.toStringAsFixed(0),
                      'kcal',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Botão SALVAR ATIVIDADE
              _buildActionButton(
                text: 'SALVAR ATIVIDADE',
                onTap: () {
                  // Chama a função de salvar com o novo título
                  widget.onSaveAndNavigate(_titleController.text);
                },
                isPrimary: true,
              ),
              const SizedBox(height: 20),

              // Botão DESCARTAR
              _buildActionButton(
                text: 'DESCARTAR',
                onTap: widget.onDiscard,
                isPrimary: false,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para o campo de entrada do título
  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      maxLines: 1,
      style: GoogleFonts.lexend(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      cursorColor: CustomColors.primary,
      decoration: InputDecoration(
        hintText: 'Nomeie sua atividade...',
        hintStyle: GoogleFonts.lexend(
          color: Colors.white54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: CustomColors.primary),
        ),
      ),
    );
  }

  // Widget para o botão Adicionar Foto
  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: () {
        // Lógica para adicionar foto
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Funcionalidade de Adicionar Foto (a ser implementada)',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: CustomColors.secondary,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              color: CustomColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Adicionar Foto',
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Constrói uma linha de estatística para o cartão de resumo
  Widget _buildStatItem(String label, String value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            color: Colors.white.withAlpha((255 * 0.7).round()),
            fontSize: 16,
          ),
        ),
        RichText(
          text: TextSpan(
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(color: Colors.white),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.lexend(
                    color: CustomColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Constrói um botão de ação genérico (Salvar ou Descartar)
  Widget _buildActionButton({
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: isPrimary ? CustomColors.primary : Colors.transparent,
          border: isPrimary
              ? null
              : Border.all(color: Colors.white54, width: 1),
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
              color: isPrimary ? CustomColors.tertiary : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
