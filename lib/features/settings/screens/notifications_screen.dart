import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Certifique-se de que o caminho para o seu arquivo de cores está correto
import 'package:hibrido/core/theme/custom_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock data para gerenciar os estados dos switches
  bool _generalNotifications = true;
  bool _newFollowers = true;
  bool _likesAndComments = true;
  bool _activityReminders = false;
  bool _appUpdates = true;

  // --- Widgets Auxiliares ---

  /// Constrói um item de configuração com um título, descrição opcional e um Switch.
  Widget _buildNotificationItem({
    required String title,
    String? description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
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
      child: Row(
        children: [
          Icon(icon, color: colors.text, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null)
                  Text(
                    description,
                    style: GoogleFonts.lexend(
                      color: colors.text.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary, // Botão ativo verde
            inactiveThumbColor: colors.text,
            inactiveTrackColor: colors.text.withOpacity(0.3),
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
      backgroundColor: colors.background, // Fundo escuro
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notificações',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Texto de cabeçalho
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Gerencie quais notificações você gostaria de receber:',
                style: GoogleFonts.lexend(
                  color: colors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),

            // 1. Notificações Gerais (Todas)
            _buildNotificationItem(
              title: 'Notificações Gerais',
              description: 'Inclui todas as notificações abaixo.',
              icon: Icons.notifications_active_outlined,
              value: _generalNotifications,
              onChanged: (bool newValue) {
                setState(() {
                  _generalNotifications = newValue;
                  // Se desligar geral, desliga todas as outras (opcional)
                  if (!newValue) {
                    _newFollowers = false;
                    _likesAndComments = false;
                    _activityReminders = false;
                    _appUpdates = false;
                  }
                });
              },
            ),

            const SizedBox(height: 10),

            // 2. Novos Seguidores
            _buildNotificationItem(
              title: 'Novos Seguidores',
              icon: Icons.person_add_outlined,
              value: _newFollowers,
              onChanged: (bool newValue) {
                setState(() {
                  _newFollowers = newValue;
                });
              },
            ),

            // 3. Curtidas e Comentários
            _buildNotificationItem(
              title: 'Curtidas e Comentários',
              icon: Icons.favorite_border,
              value: _likesAndComments,
              onChanged: (bool newValue) {
                setState(() {
                  _likesAndComments = newValue;
                });
              },
            ),

            // 4. Lembretes de Atividade
            _buildNotificationItem(
              title: 'Lembretes de Atividade',
              description: 'Alertas para iniciar uma nova atividade.',
              icon: Icons.timer_outlined,
              value: _activityReminders,
              onChanged: (bool newValue) {
                setState(() {
                  _activityReminders = newValue;
                });
              },
            ),

            // 5. Atualizações do Aplicativo
            _buildNotificationItem(
              title: 'Atualizações do App',
              description: 'Notícias sobre novas funcionalidades.',
              icon: Icons.system_update_alt_outlined,
              value: _appUpdates,
              onChanged: (bool newValue) {
                setState(() {
                  _appUpdates = newValue;
                });
              },
            ),

            const SizedBox(height: 20),

            // Exemplo de como implementar uma seção
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Text(
                'E-mail',
                style: GoogleFonts.lexend(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            _buildNotificationItem(
              title: 'Newsletters',
              icon: Icons.mail_outline,
              value: true,
              onChanged: (bool newValue) {},
            ),
          ],
        ),
      ),
    );
  }
}
