import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/custom_colors.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  /// Constrói um widget para exibir um ícone de conquista ou recorde pessoal.
  /// Inclui uma imagem, um título e um subtítulo.
  Widget _buildAchievementIcon(String title, String subtitle, String imageUrl) {
    return Column(
      children: [
        // Container que define a moldura do ícone (quadrado com bordas arredondadas).
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          // Padding para a imagem dentro da moldura.
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            // Image.asset carrega a imagem do ícone a partir dos assets locais.
            child: Image.asset(
              imageUrl,
              fit: BoxFit.contain,
              // errorBuilder exibe um ícone padrão caso a imagem não seja encontrada.
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.sports_soccer,
                  size: 40,
                  color: Colors.grey,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Título da conquista.
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        // Subtítulo (geralmente a data) da conquista.
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  /// Constrói um card que exibe um registro de uma atividade de corrida anterior.
  Widget _buildRunRecord(
    String date,
    String distance,
    String time,
    String pace,
    String calories,
  ) {
    // Container principal do card.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CustomColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha superior com o ícone e a data da corrida.
          Row(
            children: [
              const Icon(Icons.directions_run, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                date,
                style: GoogleFonts.lexend(
                  color: CustomColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Linha com os detalhes da corrida (distância, tempo, etc.).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRecordDetail(distance, 'km'),
              _buildRecordDetail(time, 'tempo'),
              _buildRecordDetail(pace, '/km'),
              _buildRecordDetail(calories, 'Calorias'),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar que constrói uma coluna para um detalhe específico do registro (ex: "6,28" e "km").
  Widget _buildRecordDetail(String value, String label) {
    return Column(
      children: [
        // O valor numérico da métrica.
        Text(
          value,
          style: GoogleFonts.lexend(
            color: CustomColors.textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // O rótulo que descreve a métrica.
        Text(
          label,
          style: GoogleFonts.lexend(
            color: CustomColors.textLight.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Constrói um botão de filtro de atividade (ex: "Correr", "Caminhar").
  /// A aparência do botão muda se ele está selecionado (`isSelected`).
  Widget _buildActivityFilterButton(
    IconData icon,
    String text,
    bool isSelected,
  ) {
    // Container que define o formato e a cor do botão.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? CustomColors.primary : CustomColors.card,
        borderRadius: BorderRadius.circular(25),
      ),
      // Row para alinhar o ícone e o texto dentro do botão.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? CustomColors.textDark : Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.lexend(
              color: isSelected ? CustomColors.textDark : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um card para um desafio individual na aba 'Desafios'.
  Widget _buildChallengeCard({
    required String title,
    required String description,
    required String date,
    required IconData icon,
    bool isJoined = false,
  }) {
    // Card é a base do widget, com sombra e bordas arredondadas.
    return Card(
      color: CustomColors.card,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone que representa o desafio.
            Icon(icon, color: CustomColors.primary, size: 30),
            const Spacer(),
            // Título do desafio.
            Text(
              title,
              style: GoogleFonts.lexend(
                color: CustomColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Data relacionada ao desafio.
            Text(
              date,
              style: GoogleFonts.lexend(
                color: CustomColors.textLight.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            // Botão para "Ingressar" ou mostrar que já "Ingressou".
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  // Lógica para entrar ou sair do desafio
                },
                style: ElevatedButton.styleFrom(
                  // A cor de fundo muda se o usuário já ingressou.
                  backgroundColor: isJoined
                      ? Colors.transparent
                      : CustomColors.primary,
                  // A borda aparece se o usuário já ingressou.
                  side: isJoined
                      ? BorderSide(color: CustomColors.primary, width: 1)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  // O texto do botão também muda.
                  isJoined ? 'Ingressou' : 'Ingressar',
                  style: GoogleFonts.lexend(
                    color: isJoined
                        ? CustomColors.primary
                        : CustomColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                _buildAchievementIcon(
                  'Definir uma meta',
                  '',
                  'assets/images/trophy.png',
                ),
                const SizedBox(width: 16),
                _buildAchievementIcon(
                  'Primeira corrida',
                  '5 de ago. de 2025',
                  'assets/images/rocket.png',
                ),
                const SizedBox(width: 16),
                _buildAchievementIcon(
                  'Corria mais longa',
                  '27 de ago. de 2025',
                  'assets/images/man_running.png',
                ),
                const SizedBox(width: 16),
                _buildAchievementIcon(
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
                _buildAchievementIcon(
                  'Corria mais longa',
                  '27 de ago. de 2025',
                  'assets/images/man_running.png',
                ),
                const SizedBox(width: 16),
                _buildAchievementIcon(
                  'Maior elevação acumulada',
                  '10 de set. de 2025',
                  'assets/images/mountain.png',
                ),
                const SizedBox(width: 16),
                _buildAchievementIcon(
                  'Melhor tempo em 5K',
                  '8 de set. de 2025',
                  'assets/images/5k_medal.png',
                ),
                const SizedBox(width: 16),
                _buildAchievementIcon(
                  'Melhor tempo em 10K',
                  'Treinar',
                  'assets/images/10k_medal.png',
                ),
                const SizedBox(width: 16),
                _buildAchievementIcon(
                  'Melhor tempo em Maratona',
                  'Treinar',
                  'assets/images/42k_medal.png',
                ),
                const SizedBox(width: 16),
                _buildAchievementIcon(
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
          _buildRunRecord(
            'Manhã de quarta-feira',
            '6,28',
            '50:14',
            '8:00',
            '414',
          ),
          _buildRunRecord(
            'Manhã de segunda-feira',
            '5,04',
            '23:40',
            '4:42',
            '390',
          ),
          _buildRunRecord('Manhã de sábado', '5,21', '27:33', '5:17', '394'),
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
                  _buildActivityFilterButton(
                    Icons.directions_run,
                    'Correr',
                    true,
                  ),
                  _buildActivityFilterButton(
                    Icons.directions_walk,
                    'Caminhar',
                    false,
                  ),
                  _buildActivityFilterButton(
                    Icons.directions_bike,
                    'Bicicleta',
                    false,
                  ),
                  _buildActivityFilterButton(Icons.pool, 'Nadar', false),
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
              _buildChallengeCard(
                title: 'Corrida Mais Rápida',
                description: 'Seu melhor tempo em uma corrida.',
                date: 'Alcançado em 08/09/2025',
                icon: Icons.speed,
                isJoined: true,
              ),
              _buildChallengeCard(
                title: 'Maior Distância de Bike',
                description: 'Sua pedalada mais longa até hoje.',
                date: 'Alcançado em 27/08/2025',
                icon: Icons.directions_bike,
              ),
              _buildChallengeCard(
                title: 'Maior Elevação',
                description: 'O maior ganho de elevação em uma atividade.',
                date: 'Alcançado em 10/09/2025',
                icon: Icons.hiking,
              ),
              _buildChallengeCard(
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
        backgroundColor: CustomColors.primary,
        // AppBar contém o título e a barra de abas.
        appBar: AppBar(
          title: Text(
            'Desafios e Conquistas',
            style: GoogleFonts.lexend(
              color: CustomColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: CustomColors.primary,
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
