import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementIcon extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;

  const AchievementIcon(this.title, this.subtitle, this.imageUrl, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Container que define a moldura do ícone (quadrado com bordas arredondadas).
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          // Padding para a imagem dentro da moldura.
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            // Image.asset carrega a imagem do ícone a partir dos assets locais.
            child: Image.asset(
              imageUrl,
              fit: BoxFit.contain,
              // errorBuilder exibe um ícone padrão caso a imagem não seja encontrada.
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.sports_soccer,
                  size: 40,
                  color: Colors.grey,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Título da conquista.
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        // Subtítulo (geralmente a data) da conquista.
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
