import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

class RunRecordCard extends StatelessWidget {
  final String date;
  final String distance;
  final String time;
  final String pace;
  final String calories;

  const RunRecordCard(
    this.date, {
    super.key,
    required this.distance,
    required this.time,
    required this.pace,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Container principal do card.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.surface, // Alterado para fundo claro
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha superior com o ícone e a data da corrida.
          Row(
            children: [
              Icon(Icons.directions_run, color: colors.text, size: 16),
              const SizedBox(width: 8),
              Text(
                date,
                style: GoogleFonts.lexend(
                  color: colors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Linha com os detalhes da corrida (distância, tempo, etc.).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRecordDetail(context, distance, 'km'),
              _buildRecordDetail(context, time, 'tempo'),
              _buildRecordDetail(context, pace, '/km'),
              _buildRecordDetail(context, calories, 'Calorias'),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar que constrói uma coluna para um detalhe específico do registro (ex: "6,28" e "km").
  Widget _buildRecordDetail(BuildContext context, String value, String label) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        // O valor numérico da métrica.
        Text(
          value,
          style: GoogleFonts.lexend(
            color: colors.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // O rótulo que descreve a métrica.
        Text(
          label,
          style: GoogleFonts.lexend(
            color: colors.text.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
