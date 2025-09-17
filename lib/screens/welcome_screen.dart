import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/custom_colors.dart';
import 'app_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Define a cor de fundo para preto sólido (tertiary), combinando com a imagem de referência.
      backgroundColor: CustomColors.tertiary,
      body: Stack(
        children: [
          // Imagem de fundo ou elementos visuais decorativos

          // Imagem superior (home1)
          Positioned(
            right: -50, // Posiciona a imagem levemente fora da tela à direita
            top:
                MediaQuery.of(context).size.height *
                0.15, // Posiciona no terço superior
            child: Opacity(
              opacity: 0.5, // Define a transparência para um efeito suave
              child: Image.asset(
                'assets/images/home1.png', // Caminho para o asset da imagem
                width:
                    MediaQuery.of(context).size.width *
                    0.6, // Largura relativa à tela
                fit:
                    BoxFit.cover, // Garante que a imagem cubra o espaço alocado
              ),
            ),
          ),
          // Imagem inferior (home2) - Já posicionada na parte de baixo
          Positioned(
            left: -50, // Posiciona a imagem levemente fora da tela à esquerda
            bottom:
                MediaQuery.of(context).size.height *
                0.00, // Posiciona no terço inferior
            child: Opacity(
              opacity: 0.5, // Define a transparência
              child: Image.asset(
                'assets/images/home2.png', // Caminho para o asset da imagem
                width:
                    MediaQuery.of(context).size.width *
                    0.6, // Largura relativa à tela
                fit:
                    BoxFit.cover, // Garante que a imagem cubra o espaço alocado
              ),
            ),
          ),

          // Conteúdo principal (logo, texto e botão) - Colocado sobre as imagens de fundo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 60.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo "GoGGy"
                  Row(
                    children: [
                      Icon(
                        Icons.run_circle_outlined,
                        color: CustomColors
                            .primary, // Cor primary para o ícone do logo
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Triunfal',
                        style: GoogleFonts.lexend(
                          color: CustomColors
                              .textLight, // Texto claro para contraste
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(
                    flex: 2,
                  ), // Espaçador para empurrar o título para baixo
                  // Título principal
                  Text(
                    'Correr\nCaminhar\nAndar',
                    style: GoogleFonts.lexend(
                      color: CustomColors.textLight,
                      fontSize: 65,
                      fontWeight: FontWeight.bold,
                      height:
                          1.1, // Ajuste na altura da linha para o espaçamento
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 20), // Espaçamento após o título
                  // Subtítulo
                  SizedBox(
                    width:
                        MediaQuery.of(context).size.width *
                        0.6, // Limita a largura do texto
                    child: Text(
                      'Compartilha sua corrida de um jeito triunfal',
                      style: GoogleFonts.lexend(
                        color: CustomColors.textLight.withOpacity(
                          0.8,
                        ), // Texto com leve transparência
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1), // Mais espaçamento antes dos botões
                  // Botão principal "GET, SET, GO!"
                  SizedBox(
                    width: double.infinity, // Ocupa toda a largura disponível
                    height: 70, // Altura definida para o botão
                    child: ElevatedButton(
                      onPressed: () {
                        // Navega para a próxima tela ao ser pressionado
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors
                            .primary, // Cor primary vibrante para o botão
                        shape: RoundedRectangleBorder(
                          // Arredondamento máximo para um formato oval/circular
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 10, // Sombra para dar profundidade
                        shadowColor: CustomColors.primary.withOpacity(
                          0.5,
                        ), // Cor da sombra
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ), // Espaçamento interno do botão
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Centraliza o conteúdo do botão
                        children: [
                          // Espaçamento entre o ícone e o texto
                          Text(
                            'COMEÇAR',
                            style: GoogleFonts.lexend(
                              color: CustomColors
                                  .textDark, // Texto escuro para contraste com o fundo primary
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
