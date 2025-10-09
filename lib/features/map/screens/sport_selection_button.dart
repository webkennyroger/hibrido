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
  final bool useDarkMode; // NOVO: para o estilo preto

  const SportSelectionButton({
    super.key,
    required this.iconPath,
    required this.label,
    required this.option,
    required this.selectedSport,
    required this.onTap,
    required this.fallbackIcon,
    this.isLarge = false, // Por padrão, é o botão pequeno
    this.useDarkMode = false, // Por padrão, usa o estilo normal
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = selectedSport == option;

    // Define a cor de fundo
    final Color backgroundColor = isSelected
        ? (isLarge
              ? AppColors
                    .primary // Verde sólido para o botão grande
              : AppColors.primary.withAlpha(
                  (255 * 0.6).round(),
                )) // Verde translúcido para o pequeno
        : (isDarkMode
              ? AppColors.light()
                    .surface // Fundo branco no modo escuro (não selecionado)
              : AppColors.dark()
                    .background); // Fundo preto no modo claro (não selecionado)

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
                  color: backgroundColor,
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
                    // A cor do ícone agora se adapta ao tema e ao estado de seleção.
                    colorFilter: ColorFilter.mode(
                      isSelected
                          ? AppColors.dark()
                                .background // Ícone preto quando selecionado
                          : (isDarkMode
                                ? AppColors.dark()
                                      .background // Ícone preto no modo escuro (não selecionado)
                                : AppColors
                                      .primary), // Ícone verde no modo claro (não selecionado)
                      BlendMode.srcIn,
                    ),
                    width: 35,
                    height: 35,
                    // Fallback para ícone se o SVG não for encontrado
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        fallbackIcon,
                        // A cor do ícone de fallback agora segue a mesma lógica do SVG.
                        color: isSelected
                            ? AppColors.dark()
                                  .background // Ícone preto quando selecionado
                            : (isDarkMode
                                  ? AppColors.dark()
                                        .background // Ícone preto no modo escuro
                                  : AppColors
                                        .primary), // Ícone verde no modo claro
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
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Círculo branco no modo escuro, ou verde/preto no modo claro
                        Icon(
                          Icons.circle,
                          color: isLarge
                              ? (isDarkMode
                                    ? AppColors.light()
                                          .surface // Seletor: Círculo branco
                                    : AppColors.dark()
                                          .background) // Seletor: Círculo preto
                              : AppColors.dark()
                                    .background, // Mapa: Círculo sempre preto
                          size: 20,
                        ),
                        // Ícone de "check" sempre preto
                        Icon(
                          Icons.check,
                          color: isLarge && isDarkMode
                              ? AppColors.dark()
                                    .background // Seletor Dark: Check preto
                              : AppColors
                                    .primary, // Seletor Light e Mapa: Check verde
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (isLarge) ...[
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.lexend(
                color: isSelected ? AppColors.primary : colors.text,
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
