import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/screens/activity_screen.dart';
import 'package:hibrido/features/chat/screens/chat_screen.dart';
import 'package:hibrido/features/home/screens/home_screen.dart';
import 'package:hibrido/features/map/screens/map_screen.dart';
import 'package:hibrido/features/profile/screens/profile_screen.dart';
import 'package:hibrido/features/activity/screens/activity_screen.dart'
    show ActivityScreenState;

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  // Armazena o índice da tela atualmente selecionada na barra de navegação.
  int _selectedIndex = 0;

  // Lista de telas que serão exibidas.
  late final List<Widget> _screens;
  // NOVO: Chave para acessar o estado da ActivityScreen
  final GlobalKey<ActivityScreenState> _activityScreenKey =
      GlobalKey<ActivityScreenState>();

  @override
  void initState() {
    super.initState();
    // Inicializamos a lista de telas aqui para poder passar o callback para a ProfileScreen.
    _screens = [
      const HomeScreen(),
      // NOVO: Passa a chave para a ActivityScreen
      ActivityScreen(key: _activityScreenKey),
      const ChatScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Scaffold é a estrutura principal da tela, que contém o corpo (body) e a barra de navegação inferior.
    return Material(
      color: colors.background,
      child: Scaffold(
        // IndexedStack exibe apenas um widget da lista `_screens` por vez, com base no `_selectedIndex`.
        // Ele é eficiente pois mantém o estado das outras telas que não estão visíveis.
        backgroundColor: colors.background,
        body: IndexedStack(index: _selectedIndex, children: _screens),
        // Define a barra de navegação inferior da tela, construída pelo método `_buildBottomNavigationBar`.
        bottomNavigationBar: _buildBottomNavigationBar(context),
      ),
    );
  }

  /// Constrói a barra de navegação inferior customizada.
  Widget _buildBottomNavigationBar(BuildContext context) {
    final colors = AppColors.of(context);

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
              color: colors.surface,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.1).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            // Row que organiza os 4 itens de navegação (`_buildNavItem`) lado a lado.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem(
                  SvgPicture.asset(
                    'assets/images/icons/home.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 0
                          ? AppColors.dark()
                                .background // Ícone preto quando selecionado
                          : colors.text.withOpacity(
                              0.7,
                            ), // Cor padrão quando não selecionado
                      BlendMode.srcIn,
                    ),
                  ),
                  0,
                ), // Item para HomeScreen
                _buildNavItem(
                  SvgPicture.asset(
                    'assets/images/icons/estatistica.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 1
                          ? AppColors.dark()
                                .background // Ícone preto quando selecionado
                          : colors.text.withOpacity(
                              0.7,
                            ), // Cor padrão quando não selecionado
                      BlendMode.srcIn,
                    ),
                  ),
                  1,
                ), // Item para ActivityScreen
                _buildNavItem(
                  SvgPicture.asset(
                    'assets/images/icons/chat.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 2
                          ? AppColors.dark()
                                .background // Ícone preto quando selecionado
                          : colors.text.withOpacity(
                              0.7,
                            ), // Cor padrão quando não selecionado
                      BlendMode.srcIn,
                    ),
                  ),
                  2,
                ), // Item para ChatScreen
                _buildNavItem(
                  SvgPicture.asset(
                    'assets/images/icons/perfil.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 3
                          ? AppColors.dark()
                                .background // Ícone preto quando selecionado
                          : colors.text.withOpacity(
                              0.7,
                            ), // Cor padrão quando não selecionado
                      BlendMode.srcIn,
                    ),
                  ),
                  3,
                ), // Item para ProfileScreen
              ],
            ),
          ),
          // Container circular que serve como fundo para o botão de corrida.
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha((255 * 0.4).round()),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            // O botão de ação com o ícone de corrida.
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/images/icons/corrida.svg',
                colorFilter: ColorFilter.mode(
                  AppColors.dark().background,
                  BlendMode.srcIn,
                ),
                width: 30,
                height: 30,
              ),
              // Ao ser pressionado, atualiza o estado para mostrar a tela de Atividade (índice 1).
              onPressed: () async {
                // Navega para a tela do mapa.
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );

                // Se a MapScreen retornar 'true', significa que uma atividade foi salva.
                // Então, mudamos para a aba de atividades (índice 1).
                if (result == true) {
                  setState(() {
                    _selectedIndex = 1;
                    // NOVO: Força a ActivityScreen a recarregar
                    _activityScreenKey.currentState?.reloadActivities();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um item de navegação individual (ícone).
  Widget _buildNavItem(Widget icon, int index) {
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              )
            : null,
        // O ícone do item. A cor também muda com base na seleção.
        child: icon,
      ),
    );
  }
}
