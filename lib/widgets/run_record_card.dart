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
    // Container principal do card.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CustomColors.quinary, // Alterado para fundo claro
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha superior com o ícone e a data da corrida.
          Row(
            children: [
              const Icon(
                Icons.directions_run,
                color: CustomColors.textDark,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: GoogleFonts.lexend(
                  color: CustomColors.textDark,
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
              _buildRecordDetail(distance, 'km'),
              _buildRecordDetail(time, 'tempo'),
              _buildRecordDetail(pace, '/km'),
              _buildRecordDetail(calories, 'Calorias'),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar que constrói uma coluna para um detalhe específico do registro (ex: "6,28" e "km").
  Widget _buildRecordDetail(String value, String label) {
    return Column(
      children: [
        // O valor numérico da métrica.
        Text(
          value,
          style: GoogleFonts.lexend(
            color: CustomColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // O rótulo que descreve a métrica.
        Text(
          label,
          style: GoogleFonts.lexend(
            color: CustomColors.textDark.withAlpha(
              (255 * 0.7).round(),
            ), // This was already corrected.
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
