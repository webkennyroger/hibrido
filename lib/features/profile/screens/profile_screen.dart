import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/profile/models/user_model.dart';
import 'package:hibrido/features/profile/screens/edit_profile_screen.dart';
import 'package:hibrido/features/activity/screens/activity_screen.dart';
import 'package:hibrido/features/challenges/screens/challenges_screen.dart';
import 'package:hibrido/features/settings/screens/account_settings_screen.dart';
import 'package:hibrido/features/statistics/stats_screen.dart';
import 'package:hibrido/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/custom_colors.dart';

// Definindo um enum para as opções de navegação na parte inferior,
// como na imagem (Atividades, Conquistas, etc.)
enum ProfileOption { activities, achievements, gear, settings }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final ActivityRepository _repository = ActivityRepository();
  bool _isLoading = true;
  int _activitiesCount = 0;
  double _totalDistanceKm = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadProfileStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadProfileStats();
    }
  }

  /// Carrega as atividades e calcula as estatísticas do perfil.
  Future<void> loadProfileStats() async {
    if (mounted) setState(() => _isLoading = true);

    final activities = await _repository.getActivities();
    double totalDistance = 0;
    for (var activity in activities) {
      totalDistance += activity.distanceInMeters;
    }

    if (mounted) {
      setState(() {
        _activitiesCount = activities.length;
        _totalDistanceKm = totalDistance / 1000;
        _isLoading = false;
      });
    }
  }

  /// Lida com a ação de "puxar para atualizar".
  Future<void> _handleRefresh() async {
    await loadProfileStats();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // NOVO: Consome os dados do UserProvider
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    // Usaremos a cor terciária (0xFF1E1E1E) como fundo da tela
    return Scaffold(
      backgroundColor: colors.background,
      // NOVO: Adiciona o RefreshIndicator para permitir "puxar para atualizar".
      body: RefreshIndicator(
        onRefresh: loadProfileStats,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 350.0, // Altura do cabeçalho expandido
              pinned: true,
              automaticallyImplyLeading:
                  false, // Remove o botão de voltar padrão
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(context, user),
              ),
            ),
            // O conteúdo restante da tela é colocado em um SliverList.
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildOptionCard(
                        label: 'Minhas Estatísticas',
                        icon: Icons.directions_run_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StatsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildOptionCard(
                        label: 'Minhas Atividades',
                        icon: Icons.directions_run_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ActivityScreen(),
                            ),
                          );
                        },
                      ),
                      _buildOptionCard(
                        label: 'Conquistas',
                        icon: Icons.emoji_events_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChallengesScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(
                        color: Colors.white12,
                        height: 32,
                        thickness: 1,
                      ),
                      _buildOptionCard(
                        label: 'Configurações',
                        icon: Icons.settings_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AccountSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---

  // NOVO: Renderiza o item de estatística usando texto branco para o rótulo
  Widget _buildStatItem(String value, String label) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lexend(
            color: AppColors.primary, // Cor Primária (Verde) para o valor
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lexend(
            color: colors.textSecondary, // Alterado para cinza escuro
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // NOVO: Card de opção de navegação
  Widget _buildOptionCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.text, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lexend(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: colors.text, size: 18),
          ],
        ),
      ),
    );
  }

  // CORRIGIDO: O Header do Perfil com Imagem de Fundo Desfocada
  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Imagem de Fundo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            child: Image(
              image: user.profileImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // Adiciona uma cor de preenchimento para garantir que não haja transparência
              color: colors.background.withOpacity(0.1),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // 2. Efeito de Desfoque (Blur)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10.0,
                  sigmaY: 10.0,
                ), // Aplica o Blur
                child: Container(
                  // Overlay escuro semi-transparente para melhorar a legibilidade
                  color: colors.background.withOpacity(0.6),
                ),
              ),
            ),
          ),

          // 3. Conteúdo do Perfil (Botões, Avatar, Nome, Stats)
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 24, // Adiciona padding na parte inferior do cabeçalho
            ),
            child: Column(
              children: [
                // BOTÃO DE VOLTAR E ÍCONE DE CONFIGURAÇÃO/EDIÇÃO
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        // Navega para a tela de edição e espera um resultado
                        final updatedUser = await Navigator.push<UserModel>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: user),
                          ),
                        );

                        if (updatedUser != null) {
                          // NOVO: Atualiza o usuário através do provider
                          context.read<UserProvider>().updateUser(updatedUser);
                        }
                      },
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // IMAGEM E NOME
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.profileImage, // Usa a mesma imagem
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  user.name, // Nome do usuário vindo do estado
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.location, // Localização vinda do estado
                  style: GoogleFonts.lexend(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                // ESTATÍSTICAS
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child:
                              _isLoading // Adicionado
                              ? const Center(child: CircularProgressIndicator())
                              : _buildStatItem(
                                  _activitiesCount.toString(),
                                  'Atividades',
                                ),
                        ),
                        VerticalDivider(
                          color: colors.text.withOpacity(0.12),
                          thickness: 1,
                          indent: 10, // Adiciona espaçamento vertical
                          endIndent: 10,
                        ),
                        Expanded(
                          child:
                              _isLoading // Adicionado
                              ? const Center(child: CircularProgressIndicator())
                              : _buildStatItem(
                                  _totalDistanceKm.toStringAsFixed(1),
                                  'Km Rodados',
                                ),
                        ),
                        VerticalDivider(
                          color: colors.text.withOpacity(0.12),
                          thickness: 1,
                          indent: 10,
                          endIndent: 10,
                        ),
                        Expanded(child: _buildStatItem('0', 'Conquistas')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
