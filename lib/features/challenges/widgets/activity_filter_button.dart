import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

class ActivityFilterButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSelected;

  const ActivityFilterButton(
    this.icon,
    this.text,
    this.isSelected, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Container que define o formato e a cor do botão.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : colors.surface,
        borderRadius: BorderRadius.circular(25),
      ),
      // Row para alinhar o ícone e o texto dentro do botão.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.dark().background : colors.text,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.lexend(
              color: isSelected ? AppColors.dark().background : colors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
