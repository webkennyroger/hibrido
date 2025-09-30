import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/map/screens/map_screen.dart'; // Para o enum SportOption

/// Um botão reutilizável para seleção de esporte, com ícone SVG/fallback,
/// rótulo e um indicador de seleção.
class SportSelectionButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final SportOption option; // A opção de esporte que este botão representa
  final SportOption selectedSport; // A opção de esporte atualmente selecionada
  final VoidCallback onTap;
  final IconData fallbackIcon; // Ícone a ser usado se o SVG não carregar
  final bool isLarge; // NOVO: para controlar o tamanho

  const SportSelectionButton({
    super.key,
    required this.iconPath,
    required this.label,
    required this.option,
    required this.selectedSport,
    required this.onTap,
    required this.fallbackIcon,
    this.isLarge = false, // Por padrão, é o botão pequeno
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedSport == option;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: isLarge ? Clip.hardEdge : Clip.none,
            children: [
              Container(
                width: isLarge ? 70 : 60,
                height: isLarge ? 70 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (isLarge
                          ? CustomColors.primary // Verde sólido para o botão grande
                          : CustomColors.primary.withAlpha((255 * 0.6).round())) // Verde translúcido para o pequeno
                      : (isLarge
                            ? CustomColors.secondary
                            : CustomColors.tertiary),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).round()),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: ColorFilter.mode(
                      isSelected
                          ? (isLarge
                              ? CustomColors.tertiary // Ícone preto no botão grande
                              : CustomColors.primary) // Ícone verde no botão pequeno
                          : CustomColors.tertiary,
                      BlendMode.srcIn,
                    ),
                    width: 35,
                    height: 35,
                    // Fallback para ícone se o SVG não for encontrado
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        fallbackIcon,
                        color: isSelected
                            ? CustomColors.primary
                            : CustomColors.tertiary,
                        size: 35,
                      );
                    },
                  ),
                ),
              ),
              // Checkmark de seleção (visível apenas se o esporte estiver selecionado)
              if (isSelected)
                Positioned(
                  top: isLarge ? 0 : -5,
                  right: isLarge ? 0 : -5,
                  child: Icon(
                    Icons.check_circle, // Usa sempre o ícone com círculo
                    color: isLarge
                        ? CustomColors.tertiary // "Check" preto no botão grande
                        : CustomColors.primary, // "Check" verde no botão pequeno
                    size: 20, // Usa sempre o mesmo tamanho
                  ),
                ),
            ],
          ),
          if (isLarge) ...[
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.lexend(
                color: isSelected ? CustomColors.primary : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}