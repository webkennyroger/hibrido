import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/screens/activity_screen.dart';
import 'package:hibrido/features/home/screens/home_screen.dart';
import 'package:hibrido/features/map/screens/map_screen.dart';
import 'package:hibrido/features/profile/screens/profile_screen.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({Key? key}) : super(key: key);

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  // Armazena o índice da tela atualmente selecionada na barra de navegação.
  int _selectedIndex = 0;

  // Lista de telas que serão exibidas.
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Inicializamos a lista de telas aqui para poder passar o callback para a ProfileScreen.
    _screens = [
      const HomeScreen(),
      const ActivityScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura principal da tela, que contém o corpo (body) e a barra de navegação inferior.
    return Scaffold(
      // IndexedStack exibe apenas um widget da lista `_screens` por vez, com base no `_selectedIndex`.
      // Ele é eficiente pois mantém o estado das outras telas que não estão visíveis.
      body: IndexedStack(index: _selectedIndex, children: _screens),
      // Define a barra de navegação inferior da tela, construída pelo método `_buildBottomNavigationBar`.
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  /// Constrói a barra de navegação inferior customizada.
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Padding(
      // Adiciona espaçamento nas bordas da barra de navegação para um visual mais limpo.
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      // Row organiza os dois elementos principais (o menu de navegação e o botão de corrida) horizontalmente.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Container branco com bordas arredondadas que agrupa os 4 ícones de navegação.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CustomColors.textLight,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            // Row que organiza os 4 itens de navegação (`_buildNavItem`) lado a lado.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem(Icons.home_outlined, 0), // Item para HomeScreen
                _buildNavItem(Icons.bar_chart, 1), // Item para ActivityScreen
                _buildNavItem(
                  Icons.person_outline,
                  2,
                ), // Item para ProfileScreen
              ],
            ),
          ),
          // Container circular que serve como fundo para o botão de corrida.
          Container(
            decoration: BoxDecoration(
              color: CustomColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CustomColors.primary.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            // O botão de ação com o ícone de corrida.
            child: IconButton(
              icon: const Icon(
                Icons.directions_run,
                color: CustomColors.tertiary,
                size: 30,
              ),
              // Ao ser pressionado, atualiza o estado para mostrar a tela de Atividade (índice 1).
              onPressed: () {
                // Navega para a tela do mapa.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const MapScreen();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um item de navegação individual (ícone).
  Widget _buildNavItem(IconData icon, int index) {
    // Verifica se este item de navegação é o que está atualmente selecionado.
    final bool isSelected = index == _selectedIndex;

    // GestureDetector detecta o toque no ícone para acionar a mudança de tela.
    return GestureDetector(
      // Ao tocar, atualiza o estado `_selectedIndex` com o índice deste item.
      // O `setState` notifica o Flutter para reconstruir o widget, mostrando a nova tela.
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      // O corpo visual do item de navegação.
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        // A decoração (fundo colorido) só é aplicada se o item estiver selecionado.
        decoration: isSelected
            ? BoxDecoration(
                color: CustomColors.primary,
                borderRadius: BorderRadius.circular(25),
              )
            : null,
        // O ícone do item. A cor também muda com base na seleção.
        child: Icon(
          icon,
          color: isSelected
              ? CustomColors.textDark
              : CustomColors.textDark.withOpacity(0.7),
          size: 28,
        ),
      ),
    );
  }
}
