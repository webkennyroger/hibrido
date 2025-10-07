import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

// Enum para as opções de privacidade, para manter a consistência.
enum PrivacyOption { public, followers, private }

// Enum para as opções de visibilidade do mapa.
enum MapVisibilityOption { public, followers, private }

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Mock data para gerenciar os estados
  bool _isPublicAccount = true;
  PrivacyOption _selectedPrivacy = PrivacyOption.public;
  MapVisibilityOption _selectedMapVisibility = MapVisibilityOption.public;

  // --- Widgets Auxiliares ---

  /// Constrói um item de configuração de privacidade com um seletor.
  Widget _buildPrivacyItem({
    required String title,
    required IconData icon,
    required String currentValue,
    required Function(String?) onChanged,
  }) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: title == 'Mapas'
          ? () => _showMapVisibilitySelectorModal(context)
          : title == 'Atividades'
          ? () => _showPrivacySelectorModal(context)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.text, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lexend(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Lógica para exibir o seletor correto
            if (title == 'Atividades' || title == 'Mapas')
              Row(
                children: [
                  Text(
                    title == 'Atividades'
                        ? _getPrivacyLabel(_selectedPrivacy)
                        : _getMapVisibilityLabel(_selectedMapVisibility),
                    style: GoogleFonts.lexend(
                      color: title == 'Atividades'
                          ? _getPrivacyColor(context, _selectedPrivacy)
                          : _getMapVisibilityColor(
                              context,
                              _selectedMapVisibility,
                            ),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: colors.text.withOpacity(0.26),
                    size: 16,
                  ),
                ],
              )
            else
              // Este `else` agora está vazio, pois ambos os itens usam o modal.
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  // Mapeia o enum de privacidade para um rótulo de texto.
  String _getPrivacyLabel(PrivacyOption option) {
    switch (option) {
      case PrivacyOption.public:
        return 'Público';
      case PrivacyOption.followers:
        return 'Seguidores';
      case PrivacyOption.private:
        return 'Privado';
    }
  }

  // Mapeia o enum de privacidade para um ícone.
  IconData _getPrivacyIcon(PrivacyOption option) {
    switch (option) {
      case PrivacyOption.public:
        return Icons.public;
      case PrivacyOption.followers:
        return Icons.group;
      case PrivacyOption.private:
        return Icons.lock;
    }
  }

  // Retorna a cor correta para o rótulo de privacidade.
  Color _getPrivacyColor(BuildContext context, PrivacyOption option) {
    switch (option) {
      case PrivacyOption.public:
        return AppColors.primary; // Verde
      case PrivacyOption.private:
        return AppColors.error; // Vermelho
      case PrivacyOption.followers:
        return AppColors.warning; // Laranja
    }
  }

  /// Mostra um modal para o usuário selecionar a privacidade.
  void _showPrivacySelectorModal(BuildContext context) {
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Visibilidade da Atividade',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 20),
              for (var option in PrivacyOption.values)
                ListTile(
                  leading: Icon(
                    _getPrivacyIcon(option),
                    color: _getPrivacyColor(context, option),
                  ),
                  title: Text(
                    _getPrivacyLabel(option),
                    style: GoogleFonts.lexend(color: colors.text),
                  ),
                  onTap: () {
                    setState(() => _selectedPrivacy = option);
                    Navigator.pop(context);
                  },
                  trailing: _selectedPrivacy == option
                      ? Icon(
                          Icons.check,
                          color: _getPrivacyColor(context, option),
                        )
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }

  // --- Funções para Visibilidade do Mapa ---

  String _getMapVisibilityLabel(MapVisibilityOption option) {
    switch (option) {
      case MapVisibilityOption.public:
        return 'Público';
      case MapVisibilityOption.followers:
        return 'Seguidores';
      case MapVisibilityOption.private:
        return 'Privado';
    }
  }

  IconData _getMapVisibilityIcon(MapVisibilityOption option) {
    switch (option) {
      case MapVisibilityOption.public:
        return Icons.public;
      case MapVisibilityOption.followers:
        return Icons.group;
      case MapVisibilityOption.private:
        return Icons.lock;
    }
  }

  Color _getMapVisibilityColor(
    BuildContext context,
    MapVisibilityOption option,
  ) {
    switch (option) {
      case MapVisibilityOption.public:
        return AppColors.primary;
      case MapVisibilityOption.private:
        return AppColors.error;
      case MapVisibilityOption.followers:
        return AppColors.warning;
    }
  }

  void _showMapVisibilitySelectorModal(BuildContext context) {
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Visibilidade dos Mapas',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 20),
              for (var option in MapVisibilityOption.values)
                ListTile(
                  leading: Icon(
                    _getMapVisibilityIcon(option),
                    color: _getMapVisibilityColor(context, option),
                  ),
                  title: Text(
                    _getMapVisibilityLabel(option),
                    style: GoogleFonts.lexend(color: colors.text),
                  ),
                  onTap: () {
                    setState(() => _selectedMapVisibility = option);
                    Navigator.pop(context);
                  },
                  trailing: _selectedMapVisibility == option
                      ? Icon(
                          Icons.check,
                          color: _getMapVisibilityColor(context, option),
                        )
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }

  // --- Widget Principal ---
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacidade',
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ícone Grande
            Icon(
              Icons.shield_outlined,
              size: 80,
              color: colors.text.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            // Texto descritivo
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Com uma conta pública, qualquer pessoa pode ver seu perfil e atividades. Com uma conta privada, apenas os seguidores que você aprovar poderão ver o que você compartilha.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  color: colors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Item para conta pública/privada (Restaurado)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.public, color: colors.text, size: 26),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Conta Pública',
                      style: GoogleFonts.lexend(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isPublicAccount,
                    onChanged: (bool newValue) {
                      setState(() => _isPublicAccount = newValue);
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Item de Privacidade Padrão das Atividades
            _buildPrivacyItem(
              title: 'Atividades',
              icon: Icons.directions_run,
              currentValue: _getPrivacyLabel(_selectedPrivacy),
              onChanged: (String? newValue) {
                // A lógica agora está no modal
              },
            ),
            // Item de Privacidade dos Mapas
            _buildPrivacyItem(
              title: 'Mapas',
              icon: Icons.map_outlined,
              currentValue: _getMapVisibilityLabel(_selectedMapVisibility),
              onChanged: (String? newValue) {
                // A lógica agora está no modal
              },
            ),
          ],
        ),
      ),
    );
  }
}
