import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Certifique-se de que o caminho para o seu arquivo de cores está correto
import 'package:hibrido/core/theme/custom_colors.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // Mock data para gerenciar os estados dos switches
  bool _twoFactorAuth = true;
  bool _saveLoginInfo = true;
  bool _securityAlerts = true;

  // --- Widgets Auxiliares ---

  /// Constrói um item de configuração com um título, descrição opcional e um Switch/Ação.
  Widget _buildSecurityItem({
    required String title,
    String? description,
    required IconData icon,
    bool isSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
    VoidCallback? onTap,
    String? actionText,
  }) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surface, // Fundo Cinza Claro
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: isSwitch ? null : onTap,
        child: Row(
          children: [
            Icon(
              icon,
              color: colors.text, // Ícone escuro
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lexend(
                      color: colors.text, // Texto escuro
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description,
                      style: GoogleFonts.lexend(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (isSwitch && onSwitchChanged != null)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: AppColors.primary, // Botão ativo verde
                inactiveThumbColor: colors.text,
                inactiveTrackColor: colors.text.withOpacity(0.3),
              )
            else if (actionText != null)
              Row(
                children: [
                  Text(
                    actionText,
                    style: GoogleFonts.lexend(
                      color: colors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: colors.text, // Seta escura
                    size: 16,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // --- Widget Principal ---

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background, // Fundo escuro
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Configurações de Privacidade',
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
                'Estas configurações permitem controlar quem pode ver suas'
                'atividades, mapas e seguidores.'
                'Com uma conta pública, você pode compartilhar suas atividades,'
                'mapas e listas de seguidores com todos, dependendo de suas configurações.',
                style: GoogleFonts.lexend(
                  color: colors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),

            // 1. Autenticação de Dois Fatores
            _buildSecurityItem(
              title: 'Conta publica',
              description: 'Quem vai poder ver seus conteudos',
              icon: Icons.security_outlined,
              isSwitch: true,
              switchValue: _twoFactorAuth,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _twoFactorAuth = newValue;
                });
              },
            ),

            // 2. Salvar Informações de Login
            _buildSecurityItem(
              title: 'Salvar Informações de Login',
              description: 'Permitir entrada rápida em dispositivos salvos.',
              icon: Icons.vpn_key_outlined,
              isSwitch: true,
              switchValue: _saveLoginInfo,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _saveLoginInfo = newValue;
                });
              },
            ),

            // 3. Alertas de Segurança
            _buildSecurityItem(
              title: 'Atividades',
              description: 'Receber notificação sobre novos logins.',
              icon: Icons.security_outlined,
              isSwitch: true,
              switchValue: _securityAlerts,
              onSwitchChanged: (bool newValue) {
                setState(() {
                  _securityAlerts = newValue;
                });
              },
            ),

            // 4. Alterar Senha (Ação)
            _buildSecurityItem(
              title: 'Mapas',
              icon: Icons.password_outlined,
              actionText: 'Atualizar',
              onTap: () {
                // TODO: Navegar para a tela de alteração de senha
                print('Navegar para Alterar Senha');
              },
            ),
          ],
        ),
      ),
    );
  }
}
