import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import '../widgets/achievement_icon.dart';
import '../widgets/activity_filter_button.dart';
import '../widgets/challenge_card.dart';
import '../widgets/run_record_card.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  /// Constrói todo o conteúdo para a aba 'Conquistas'.
  Widget _buildActiveContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção 'Conquistas'.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Conquistas (4)',
              style: GoogleFonts.lexend(
                color: CustomColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ListView horizontal para os ícones de conquistas.
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const AchievementIcon(
                  'Definir uma meta',
                  '',
                  'assets/images/trophy.png',
                ),
                const SizedBox(width: 16),
                const AchievementIcon(
                  'Primeira corrida',
                  '5 de ago. de 2025',
                  'assets/images/rocket.png',
                ),
                const SizedBox(width: 16),
                const AchievementIcon(
                  'Corria mais longa',
                  '27 de ago. de 2025',
                  'assets/images/man_running.png',
                ),
                const SizedBox(width: 16),
                const AchievementIcon(
                  'Melhor tempo em 5K',
                  '8 de set. de 2025',
                  'assets/images/5k_medal.png',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Título da seção 'Recordes pessoais'.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Recordes pessoais de corridas',
              style: GoogleFonts.lexend(
                color: CustomColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ListView horizontal para os ícones de recordes.
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const AchievementIcon(
                  'Corria mais longa',
                  '27 de ago. de 2025',
                  'assets/images/man_running.png',
                ),
                const SizedBox(width: 16),
                const AchievementIcon(
                  'Maior elevação acumulada',
                  '10 de set. de 2025',
                  'assets/images/mountain.png',
                ),
                const SizedBox(width: 16),
                const AchievementIcon(
                  'Melhor tempo em 5K',
                  '8 de set. de 2025',
                  'assets/images/5k_medal.png',
                ),
                const SizedBox(width: 16),
                const AchievementIcon(
                  'Melhor tempo em 10K',
                  'Treinar',
                  'assets/images/10k_medal.png',
                ),
                const SizedBox(width: 16),
                const AchievementIcon(
                  'Melhor tempo em Maratona',
                  'Treinar',
                  'assets/images/42k_medal.png',
                ),
                const SizedBox(width: 16),
                const AchievementIcon(
                  'Melhor tempo em Meia maratona',
                  'Treinar',
                  'assets/images/21k_medal.png',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Título da seção de registros de atividades.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.directions_run, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recordes por atividade - Corrida',
                  style: GoogleFonts.lexend(
                    color: CustomColors.textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Lista de cards com os registros de corridas.
          const RunRecordCard(
            'Manhã de quarta-feira',
            '6,28',
            '50:14',
            '8:00',
            '414',
          ),
          const RunRecordCard(
            'Manhã de segunda-feira',
            '5,04',
            '23:40',
            '4:42',
            '390',
          ),
          const RunRecordCard('Manhã de sábado', '5,21', '27:33', '5:17', '394'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Constrói todo o conteúdo para a aba 'Desafios'.
  Widget _buildChallengesContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha com os botões de filtro de atividade.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const ActivityFilterButton(
                    Icons.directions_run,
                    'Correr',
                    true,
                  ),
                  const ActivityFilterButton(
                    Icons.directions_walk,
                    'Caminhar',
                    false,
                  ),
                  const ActivityFilterButton(
                    Icons.directions_bike,
                    'Bicicleta',
                    false,
                  ),
                  const ActivityFilterButton(Icons.pool, 'Nadar', false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Título da seção 'Desafios Ativos'.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'Desafios Ativos',
              style: GoogleFonts.lexend(
                color: CustomColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // GridView para exibir os cards de desafios em duas colunas.
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            children: [
              const ChallengeCard(
                title: 'Corrida Mais Rápida',
                description: 'Seu melhor tempo em uma corrida.',
                date: 'Alcançado em 08/09/2025',
                icon: Icons.speed,
                isJoined: true,
              ),
              const ChallengeCard(
                title: 'Maior Distância de Bike',
                description: 'Sua pedalada mais longa até hoje.',
                date: 'Alcançado em 27/08/2025',
                icon: Icons.directions_bike,
              ),
              const ChallengeCard(
                title: 'Maior Elevação',
                description: 'O maior ganho de elevação em uma atividade.',
                date: 'Alcançado em 10/09/2025',
                icon: Icons.hiking,
              ),
              const ChallengeCard(
                title: 'Recorde de 5K',
                description: 'Seu melhor tempo na distância de 5km.',
                date: 'Alcançado em 05/08/2025',
                icon: Icons.directions_run,
                isJoined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói o conteúdo de placeholder para a aba 'Clubs'.
  Widget _buildClubsContent() {
    return const Center(
      child: Text('Conteúdo de Clubes', style: TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // DefaultTabController gerencia o estado das abas (Conquistas, Desafios, Clubs).
    return DefaultTabController(
      length: 3,
      // Scaffold é a estrutura principal da tela.
      child: Scaffold(
        backgroundColor:
            CustomColors.tertiary, // Alterado para fundo escuro padrão
        // AppBar contém o título e a barra de abas.
        appBar: AppBar(
          title: Text(
            'Desafios e Conquistas',
            style: GoogleFonts.lexend(
              color: CustomColors
                  .textLight, // Mantém o texto claro no appbar escuro
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor:
              CustomColors.tertiary, // Alterado para fundo escuro padrão
          elevation: 0,
          bottom: TabBar(
            // Estilização da barra de abas.
            indicatorColor: CustomColors.primary,
            labelColor: CustomColors.textLight,
            unselectedLabelColor: CustomColors.textLight.withOpacity(0.6),
            tabs: const [
              Tab(text: 'Conquistas'),
              Tab(text: 'Desafios'),
              Tab(text: 'Clubs'),
            ],
          ),
        ),
        // TabBarView exibe o conteúdo correspondente à aba selecionada.
        body: TabBarView(
          children: [
            _buildActiveContent(), // Conteúdo de Conquistas
            _buildChallengesContent(), // Conteúdo de Desafios
            _buildClubsContent(),
          ],
        ),
      ),
    );
  }
}
