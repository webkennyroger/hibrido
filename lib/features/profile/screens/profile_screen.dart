import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/custom_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.quaternary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Barra de navegação do topo
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.black),
                      onPressed: () {
                        // Ação do botão de edição
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Imagem e nome do perfil
              CircleAvatar(
                radius: 50,
                backgroundColor: CustomColors.primary, // Cor de fundo do avatar
                child: CircleAvatar(
                  radius: 47,
                  backgroundImage: NetworkImage(
                    'https://i.ibb.co/L8Gj18j/avatar.png',
                  ), // Imagem de placeholder
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Joseph_7',
                style: GoogleFonts.lexend(
                  color: CustomColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Seção de Total de Pontos e Records
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: CustomColors.tertiary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Total Points',
                          style: GoogleFonts.lexend(
                            color: CustomColors.textLight,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '35766',
                          style: GoogleFonts.lexend(
                            color: CustomColors.textLight,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 50, width: 1, color: CustomColors.card),
                    Column(
                      children: [
                        Text(
                          'Total Records',
                          style: GoogleFonts.lexend(
                            color: CustomColors.textLight,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '35766',
                          style: GoogleFonts.lexend(
                            color: CustomColors.textLight,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Barra de progresso do nível
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level',
                          style: GoogleFonts.lexend(
                            color: CustomColors.textDark,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '35000 / 50000 Pts',
                          style: GoogleFonts.lexend(
                            color: CustomColors.textDark,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: 35000 / 50000,
                      backgroundColor: CustomColors.card.withAlpha(
                        (255 * 0.5).round(),
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        CustomColors.primary,
                      ),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '10',
                          style: GoogleFonts.lexend(
                            color: CustomColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '11',
                          style: GoogleFonts.lexend(
                            color: CustomColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Seção de Registros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Records',
                      style: GoogleFonts.lexend(
                        color: CustomColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'see all',
                        style: GoogleFonts.lexend(
                          color: CustomColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Lista de Registros (Cartões)
              _buildRecordCard(
                'Dec-Half-Marathon',
                '+2550 pts',
                '1st',
                'https://i.ibb.co/3Wf4Q4X/marathon.jpg',
                context,
              ),
              _buildRecordCard(
                'Running challenge',
                '+1350 pts',
                '2nd',
                'https://i.ibb.co/n6v98Vq/running.jpg',
                context,
              ),
              _buildRecordCard(
                'Nov-jogging challenge',
                '+1000 pts',
                '3rd',
                'https://i.ibb.co/tBf3yXv/jogging.jpg',
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(
    String title,
    String pts,
    String rank,
    String imageUrl,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: CustomColors.quinary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(imageUrl)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    color: CustomColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pts,
                  style: GoogleFonts.lexend(
                    color: CustomColors.textDark,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            rank,
            style: GoogleFonts.lexend(
              color: CustomColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
