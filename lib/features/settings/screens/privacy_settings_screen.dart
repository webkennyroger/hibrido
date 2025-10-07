import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Mock data para gerenciar os estados
  bool _isPublicAccount = true;
  String _activityVisibility = 'Todos';
  String _mapVisibility = 'Todos';

  // --- Widgets Auxiliares ---

  /// Constrói um item de configuração de privacidade com um seletor.
  Widget _buildPrivacyItem({
    required String title,
    required IconData icon,
    required String currentValue,
    required Function(String?) onChanged,
  }) {
    final colors = AppColors.of(context);
    return Container(
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
          DropdownButton<String>(
            value: currentValue,
            onChanged: onChanged,
            underline: const SizedBox.shrink(),
            icon: Icon(Icons.arrow_drop_down, color: colors.text),
            style: GoogleFonts.lexend(color: colors.text, fontSize: 16),
            dropdownColor: colors.surface,
            items: <String>['Todos', 'Seguidores', 'Ninguém']
                .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                })
                .toList(),
          ),
        ],
      ),
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
            // NOVO: Item único para conta pública/privada
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
                      setState(() {
                        _isPublicAccount = newValue;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Item de Privacidade das Atividades
            _buildPrivacyItem(
              title: 'Atividades',
              icon: Icons.directions_run,
              currentValue: _activityVisibility,
              onChanged: (String? newValue) {
                setState(() {
                  _activityVisibility = newValue!;
                });
              },
            ),
            // Item de Privacidade dos Mapas
            _buildPrivacyItem(
              title: 'Mapas',
              icon: Icons.map_outlined,
              currentValue: _mapVisibility,
              onChanged: (String? newValue) {
                setState(() {
                  _mapVisibility = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
