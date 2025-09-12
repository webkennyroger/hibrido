import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/custom_colors.dart';
import 'home_screen.dart'; // Import da tela de Plano de Treino
import 'workout_screen.dart'; // Import da tela de Treino

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura base da tela, fornecendo um layout visual.
    return Scaffold(
      backgroundColor: CustomColors.tertiary,
      // SafeArea garante que o conteúdo não seja obstruído por elementos da interface do sistema.
      body: SafeArea(
        // SingleChildScrollView permite que o conteúdo da tela seja rolável se exceder o tamanho da tela.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          // Column organiza os widgets filhos em uma coluna vertical.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com o título "Your Activity" e ícones de ação.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Título da tela.
                  Text(
                    'Your Activity',
                    style: GoogleFonts.lexend(
                      color: CustomColors.textLight,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Row para agrupar os botões de ação.
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.compare_arrows,
                          color: CustomColors.textLight,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.more_horiz,
                          color: CustomColors.textLight,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Container que representa um calendário simplificado.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CustomColors.card,
                  borderRadius: BorderRadius.circular(15),
                ),
                // Column para organizar o título do mês, os dias da semana e os dias numerados.
                child: Column(
                  children: [
                    // Título do mês.
                    Text(
                      'May 2024',
                      style: GoogleFonts.lexend(
                        color: CustomColors.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Row para exibir as iniciais dos dias da semana.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        Text(
                          'M',
                          style: TextStyle(color: CustomColors.textLight),
                        ),
                        Text(
                          'T',
                          style: TextStyle(color: CustomColors.textLight),
                        ),
                        Text(
                          'W',
                          style: TextStyle(color: CustomColors.textLight),
                        ),
                        Text(
                          'T',
                          style: TextStyle(color: CustomColors.textLight),
                        ),
                        Text(
                          'F',
                          style: TextStyle(color: CustomColors.textLight),
                        ),
                        Text(
                          'S',
                          style: TextStyle(color: CustomColors.textLight),
                        ),
                        Text(
                          'S',
                          style: TextStyle(color: CustomColors.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row para exibir os dias do mês de forma simplificada.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      // Gera 7 widgets de dia (CircleAvatar) para representar uma semana.
                      children: List.generate(7, (index) {
                        // CircleAvatar serve como fundo para o número do dia.
                        return CircleAvatar(
                          // O dia 4 (índice) é destacado como o dia selecionado.
                          backgroundColor: index == 4
                              ? CustomColors.primary
                              : Colors.transparent,
                          child: Text(
                            '${20 + index}',
                            style: TextStyle(
                              // A cor do texto também muda para o dia selecionado.
                              color: index == 4
                                  ? CustomColors.textDark
                                  : CustomColors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Título da seção "Desafio de hoje".
              Text(
                "Desafio de hoje",
                style: GoogleFonts.lexend(
                  color: CustomColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Container que funciona como um card para o desafio do dia.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CustomColors.card,
                  borderRadius: BorderRadius.circular(15),
                ),
                // Row para alinhar o texto e a imagem do desafio horizontalmente.
                child: Row(
                  children: [
                    // Expanded permite que a coluna de texto ocupe o espaço restante.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título do desafio.
                          Text(
                            'Keep it up!',
                            style: GoogleFonts.lexend(
                              color: CustomColors.textLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Descrição do desafio.
                          Text(
                            'Do your plan before 8:00 AM',
                            style: GoogleFonts.lexend(
                              color: CustomColors.textLight.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ClipRRect aplica bordas arredondadas à imagem.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        'https://placehold.co/100x80/000000/FFFFFF?text=Imagem',
                        fit: BoxFit.cover,
                        width: 80,
                        height: 60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Row para exibir os cards de estatísticas lado a lado.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Chama o método que constrói um card de estatística.
                  _buildStatCard(
                    icon: Icons.directions_run,
                    title: 'Steps',
                    value: '1840',
                    color: Colors.purple.shade200,
                  ),
                  _buildStatCard(
                    icon: Icons.trending_up,
                    title: 'My Goals',
                    value: '48%',
                    color: Colors.pink.shade200,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Container para o card do gráfico de calorias.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CustomColors.card,
                  borderRadius: BorderRadius.circular(15),
                ),
                // Row para alinhar os detalhes de texto e o gráfico circular.
                child: Row(
                  children: [
                    // Expanded para que a coluna de texto ocupe o espaço disponível.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Detalhes de texto sobre as calorias.
                          Text(
                            '• 1200 Kcal Target',
                            style: GoogleFonts.lexend(
                              color: CustomColors.primary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '• 328 Kcal Burned',
                            style: GoogleFonts.lexend(
                              color: CustomColors.textLight.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '• 872 Kcal Remaining',
                            style: GoogleFonts.lexend(
                              color: CustomColors.textLight.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // SizedBox para definir um tamanho fixo para o gráfico circular.
                    const SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: 0.3,
                        backgroundColor: CustomColors.secondary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          CustomColors.primary,
                        ),
                        strokeWidth: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói um card individual para exibir uma estatística (ex: Passos, Metas).
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CustomColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      // Column para organizar o ícone e os textos verticalmente.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone da estatística.
          Icon(icon, color: color),
          const SizedBox(height: 4),
          // Título da estatística.
          Text(
            title,
            style: GoogleFonts.lexend(
              color: CustomColors.textLight,
              fontSize: 14,
            ),
          ),
          // Valor da estatística.
          Text(
            value,
            style: GoogleFonts.lexend(
              color: CustomColors.textLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
