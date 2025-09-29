import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

class ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final IconData icon;
  final bool isJoined;

  const ChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    this.isJoined = false,
  });

  @override
  Widget build(BuildContext context) {
    // Card é a base do widget, com sombra e bordas arredondadas.
    return Card(
      color: CustomColors.card,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone que representa o desafio.
            Icon(icon, color: CustomColors.primary, size: 30),
            const Spacer(),
            // Título do desafio.
            Text(
              title,
              style: GoogleFonts.lexend(
                color: CustomColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Data relacionada ao desafio.
            Text(
              date,
              style: GoogleFonts.lexend(
                color: CustomColors.textLight.withAlpha((255 * 0.7).round()),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            // Botão para "Ingressar" ou mostrar que já "Ingressou".
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  // Lógica para entrar ou sair do desafio
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined
                      ? Colors.transparent
                      : CustomColors.primary,
                  side: isJoined
                      ? BorderSide(color: CustomColors.primary, width: 1)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  isJoined ? 'Ingressou' : 'Ingressar',
                  style: GoogleFonts.lexend(
                    color: isJoined
                        ? CustomColors.primary
                        : CustomColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
