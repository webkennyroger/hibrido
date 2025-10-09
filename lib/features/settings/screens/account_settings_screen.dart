import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/settings/screens/device_screen.dart';
import 'package:hibrido/features/settings/screens/activity_settings_screen.dart';
import 'package:hibrido/features/settings/screens/help_faq_screen.dart';
import 'package:hibrido/features/settings/screens/notifications_screen.dart';
import 'package:hibrido/features/settings/screens/privacy_settings_screen.dart';
import 'package:hibrido/features/settings/screens/terms_of_service_screen.dart';
import 'package:provider/provider.dart';
import 'package:hibrido/main.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  // --- Widgets Auxiliares ---

  /// Constrói um item de navegação com ícone, texto e seta de avanço.
  Widget _buildSettingsItem({
    required String title,
    required IconData icon, // Ícone para o item
    VoidCallback? onTap, // Ação ao tocar
    Widget? trailing, // Widget opcional no final (como um Switch)
    required BuildContext context, // Passando o contexto
    Color? backgroundColor,
    Color? contentColor,
  }) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      // Remove o efeito de splash para um visual mais limpo
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: contentColor ?? colors.text, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lexend(
                  color: contentColor ?? colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Se um widget 'trailing' for fornecido, exibe-o.
            // Caso contrário, exibe a seta se houver uma ação 'onTap'.
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: (contentColor ?? colors.text).withOpacity(0.6),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho de uma seção (e.g., "GERAL").
  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.lexend(
          color: colors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // --- Widget Principal ---

  @override
  Widget build(BuildContext context) {
    // Acessa o provedor de tema para ler e modificar o estado do tema.
    final themeProvider = Provider.of<ThemeProvider>(context);
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
          'Configurações', // Título da tela
          style: GoogleFonts.lexend(
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEÇÃO 1: GERAL
            _buildSectionHeader(context, 'Geral'),
            _buildSettingsItem(
              title: 'Notificações',
              icon: Icons.notifications_none_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),
            _buildSettingsItem(
              title: 'Dark Mode',
              icon: Icons.dark_mode_outlined,
              trailing: Switch(
                // O valor do switch agora reflete o estado atual do tema.
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  // Chama o método para alternar o tema.
                  themeProvider.toggleTheme(value);
                },
                activeColor: AppColors.primary,
              ),
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),
            _buildSettingsItem(
              title: 'Device',
              icon: Icons.devices_other_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeviceScreen()),
                );
              },
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),
            _buildSettingsItem(
              title: 'Ajuste de Atividades',
              icon: Icons.directions_run, // Ícone relacionado a atividades
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ActivitySettingsScreen()),
                );
              },
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),

            // SEÇÃO 2: SEGURANÇA E PRIVACIDADE
            _buildSectionHeader(context, 'Segurança e Privacidade'),
            _buildSettingsItem(
              title: 'Privacidade',
              icon: Icons.security_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacySettingsScreen(),
                  ),
                );
              },
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),
            _buildSettingsItem(
              title: 'Autenticação de Dois Fatores',
              icon: Icons.lock_open_outlined,
              trailing: Switch(
                value: false, // O valor deve vir de um estado
                onChanged: (value) {
                  // TODO: Lógica para autenticação de dois fatores
                },
                activeColor: AppColors.primary,
              ),
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),
            _buildSettingsItem(
              title: 'Habilitar Biometria',
              icon: Icons.fingerprint,
              trailing: Switch(
                value: false, // O valor deve vir de um estado
                onChanged: (value) {
                  // TODO: Lógica para habilitar biometria
                },
                activeColor: AppColors.primary,
              ),
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),

            // SEÇÃO 3: SUPORTE
            _buildSectionHeader(context, 'Suporte'),
            _buildSettingsItem(
              title: 'Ajuda e FAQ',
              icon: Icons.help_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpFaqScreen(),
                  ),
                );
              },
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),
            _buildSettingsItem(
              title: 'Termos de Serviço',
              icon: Icons.description_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsOfServiceScreen(),
                  ),
                );
              },
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),

            // SEÇÃO 4: CONTA
            _buildSectionHeader(context, 'Conta'),
            _buildSettingsItem(
              title: 'Sair',
              icon: Icons.logout,
              onTap: () {},
              context: context,
              backgroundColor: colors.surface,
              contentColor: colors.text,
            ),
            _buildSettingsItem(
              title: 'Deletar Conta',
              icon: Icons.delete_outline,
              onTap: () {},
              context: context,
              backgroundColor: AppColors.error, // Fundo vermelho
              contentColor: Colors.white, // Texto e ícone brancos
            ),

            const SizedBox(height: 40),
            // Versão (como na imagem)
            Center(
              child: Text(
                'Versão 1.0.0',
                style: GoogleFonts.lexend(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
