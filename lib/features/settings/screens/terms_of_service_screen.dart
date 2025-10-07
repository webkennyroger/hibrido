import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Termos de Serviço',
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Página de Termos de Serviço',
          style: TextStyle(color: colors.text),
        ),
      ),
    );
  }
}
