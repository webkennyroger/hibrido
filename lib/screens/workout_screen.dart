import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/custom_colors.dart';
import 'home_screen.dart'; // Import da tela de Plano de Treino
import 'activity_screen.dart'; // Import da tela de Atividade

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura base da tela, fornecendo um layout visual.
    return Scaffold(
            // Define a cor de fundo da tela para um tom de cinza escuro.
      backgroundColor: CustomColors.tertiary,
      body: Stack(
        children: [
          // Container para a imagem de fundo.
          Container(
            decoration: const BoxDecoration(
              // DecorationImage define a imagem de fundo, seu caminho e como ela se ajusta.
              image: DecorationImage(
                image: AssetImage('assets/images/running.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Conteúdo principal da tela.
          // Padding adiciona espaçamento interno para o conteúdo.
          Padding(
            padding: const EdgeInsets.all(16.0),
            // Column organiza os widgets filhos verticalmente.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho da tela.
                // Row alinha o título 'Your Workout' e os ícones de ação horizontalmente.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Título da tela.
                    Text(
                      'Your Workout',
                      style: GoogleFonts.lexend(
                        color: CustomColors.textLight,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Row para agrupar os botões de ação (pausa e menu).
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.pause,
                            color: CustomColors.textLight,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.menu,
                            color: CustomColors.textLight,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                // Spacer é um widget flexível que ocupa o espaço disponível, empurrando o conteúdo para a parte inferior.
                const Spacer(),
                // O card principal branco que contém os controles do timer.
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  // BoxDecoration estiliza o card com cor, bordas arredondadas e sombra.
                  decoration: BoxDecoration(
                    color: CustomColors.textLight,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  // Column para organizar o conteúdo do card verticalmente.
                  child: Column(
                    children: [
                      // Pequena barra cinza no topo do card, sugerindo que ele pode ser arrastado.
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: CustomColors.textDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Row para exibir as informações do timer (tempo decorrido, tempo principal, set).
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Coluna para "Elapsed" (tempo decorrido).
                          Column(
                            children: [
                              // Rótulo "Elapsed".
                              Text(
                                'Elapsed',
                                style: GoogleFonts.lexend(
                                  color: CustomColors.textDark.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              // Valor do tempo decorrido.
                              Text(
                                '04:30',
                                style: GoogleFonts.lexend(
                                  color: CustomColors.textDark,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Exibição principal do timer.
                          Text(
                            '01:30',
                            style: GoogleFonts.lexend(
                              color: CustomColors.textDark,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Coluna para "Set" (série atual).
                          Column(
                            children: [
                              // Rótulo "Set".
                              Text(
                                'Set',
                                style: GoogleFonts.lexend(
                                  color: CustomColors.textDark.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              // Valor da série (ex: 2 de 5).
                              Text(
                                '2/5',
                                style: GoogleFonts.lexend(
                                  color: CustomColors.textDark,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row para os botões de controle (retroceder, play, avançar).
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Chama o método que constrói cada ícone de controle.
                          _buildControlIcon(Icons.fast_rewind),
                          _buildControlIcon(Icons.play_arrow),
                          _buildControlIcon(Icons.fast_forward),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um ícone de controle circular (play, pause, etc.).
  Widget _buildControlIcon(IconData iconData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomColors.primary,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(iconData, color: CustomColors.textDark),
    );
  }
}
