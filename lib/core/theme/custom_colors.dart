import 'package:flutter/material.dart';

/// Classe para gerenciar as cores do aplicativo, com suporte para temas claro e escuro.
class AppColors {
  // Cores primárias e de destaque que geralmente não mudam com o tema.
  static const Color primary = Color(0xFFbef202); // Verde-limão
  static const Color error = Color(0xFFFF0000); // Vermelho para erros
  static const Color warning = Color(0xFFFFA600); // Laranja para avisos

  // Cores que se adaptam ao tema (claro/escuro).
  final Color background; // Cor de fundo principal da tela
  final Color surface; // Cor de fundo para componentes como cards, barras
  final Color text; // Cor principal do texto
  final Color textSecondary; // Cor secundária para textos (legendas, etc.)

  // Construtor privado para criar uma instância do conjunto de cores.
  const AppColors._({
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
  });

  /// Retorna o conjunto de cores apropriado com base no brilho do contexto.
  factory AppColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? AppColors.dark() : AppColors.light();
  }

  /// Define as cores para o tema CLARO.
  factory AppColors.light() => const AppColors._(
    background: Color(0xFFeaeaea), // Cinza claro
    surface: Color(0xFFFFFFFF), // Branco
    text: Color(0xFF1E1E1E), // Preto
    textSecondary: Color(0xFF6c6c6c), // Cinza escuro
  );

  /// Define as cores para o tema ESCURO.
  factory AppColors.dark() => const AppColors._(
    background: Color(0xFF1E1E1E), // Preto
    surface: Color(0xFF2a2a2a), // Cinza escuro
    text: Color(0xFFFFFFFF), // Branco
    textSecondary: Color(0xFFa0a0a0), // Cinza claro
  );
}
