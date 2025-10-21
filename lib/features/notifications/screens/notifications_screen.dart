import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/notifications/models/notification_model.dart'
    as model;
import 'package:hibrido/features/notifications/widgets/notification_cards.dart';
import 'package:hibrido/features/settings/screens/account_settings_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Dados de exemplo para as notificações
  final List<model.Notification> notifications = const [
    model.Notification(
      userAvatar: 'https://i.pravatar.cc/150?img=5',
      userName: 'FlutterDev',
      userHandle: '@flutterdev',
      content: 'anunciou uma nova versão do Flutter!',
      type: model.NotificationType.tweet,
    ),
    model.Notification(
      userAvatar: 'https://i.pravatar.cc/150?img=6',
      userName: 'Ana',
      userHandle: '@anacoding',
      content: 'mencionou você em um tweet.',
      type: model.NotificationType.mention,
      tweetContent: 'Ei @seu_usuario, o que acha do novo app?',
    ),
    model.Notification(
      userAvatar: 'https://i.pravatar.cc/150?img=7',
      userName: 'Carlos',
      userHandle: '@carlosrunner',
      content: 'começou a seguir você.',
      type: model.NotificationType.follow,
    ),
    model.Notification(
      userAvatar: 'https://i.pravatar.cc/150?img=8',
      userName: 'Maria',
      userHandle: '@maridev',
      content: 'curtiu seu tweet.',
      type: model.NotificationType.like,
      tweetContent: 'Minha primeira corrida de 10km! 🚀',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Cabeçalho Padrão
              _buildCustomHeader(context, colors),

              // 2. Espaço e Linha Divisória (como na tela de estatísticas)
              const SizedBox(height: 10),
              Divider(
                color: colors.surface,
                thickness: 1.0,
                indent: 20,
                endIndent: 20,
              ),

              // 3. Barra de Abas (Tabs)
              TabBar(
                labelStyle: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                labelColor: colors.text,
                unselectedLabelColor: colors.textSecondary,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Verified'),
                  Tab(text: 'Mentions'),
                ],
                indicatorColor: AppColors.primary,
              ),

              // 4. Conteúdo das Abas
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAllNotificationsList(colors),
                    _buildVerifiedNotificationsList(colors),
                    _buildMentionsList(colors),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho customizado.
  Widget _buildCustomHeader(BuildContext context, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.text, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Notificações',
            style: GoogleFonts.lexend(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.text, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Constrói a lista para a aba "All".
  Widget _buildAllNotificationsList(AppColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        switch (notification.type) {
          case model.NotificationType.tweet:
            return TweetNotificationCard(
                leadingIcon: Icons.article_outlined,
                iconColor: AppColors.info,
                userAvatar: notification.userAvatar,
                userName: notification.userName,
                content: notification.content);
          case model.NotificationType.follow:
            return TweetNotificationCard(
                leadingIcon: Icons.person_add_alt_1_outlined,
                iconColor: AppColors.primary,
                userAvatar: notification.userAvatar,
                userName: notification.userName,
                content: notification.content);
          case model.NotificationType.mention:
            return TweetMentionNotificationCard(
                leadingIcon: Icons.alternate_email,
                iconColor: AppColors.warning,
                userAvatar: notification.userAvatar,
                userName: notification.userName,
                userHandle: notification.userHandle,
                mentionContent: notification.content,
                tweetContent: notification.tweetContent ?? '');
          case model.NotificationType.like:
            return TweetMentionNotificationCard(
                leadingIcon: Icons.favorite,
                iconColor: AppColors.error,
                userAvatar: notification.userAvatar,
                userName: notification.userName,
                userHandle: notification.userHandle,
                mentionContent: notification.content,
                tweetContent: notification.tweetContent ?? '');
        }
      },
      separatorBuilder: (ctx, i) => Divider(thickness: 1, color: colors.surface),
      itemCount: notifications.length,
    );
  }

  /// Constrói a lista para a aba "Verified".
  Widget _buildVerifiedNotificationsList(AppColors colors) {
    final verifiedNotifications =
        notifications.where((n) => n.type == model.NotificationType.tweet).toList();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final notification = verifiedNotifications[index];
        return TweetNotificationCard(
            leadingIcon: Icons.article_outlined,
            iconColor: AppColors.info,
            userAvatar: notification.userAvatar,
            userName: notification.userName,
            content: notification.content);
      },
      separatorBuilder: (ctx, i) => Divider(thickness: 1, color: colors.surface),
      itemCount: verifiedNotifications.length,
    );
  }

  /// Constrói a lista para a aba "Mentions".
  Widget _buildMentionsList(AppColors colors) {
    final mentionNotifications =
        notifications.where((n) => n.type == model.NotificationType.mention).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final notification = mentionNotifications[index];
        return TweetMentionNotificationCard(
            leadingIcon: Icons.alternate_email,
            iconColor: AppColors.warning,
            userAvatar: notification.userAvatar,
            userName: notification.userName,
            userHandle: notification.userHandle,
            mentionContent: notification.content,
            tweetContent: notification.tweetContent ?? '');
      },
      itemCount: mentionNotifications.length,
    );
  }
}