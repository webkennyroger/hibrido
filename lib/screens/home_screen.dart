import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/custom_colors.dart';
import 'activity_screen.dart';
import 'workout_screen.dart';
import 'challenges_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold é a estrutura base da tela, fornecendo appBar, body, etc.
    return Scaffold(
      // Define a cor de fundo da tela para um tom de cinza escuro.
      backgroundColor: CustomColors.tertiary,
      // SafeArea garante que o conteúdo não seja obstruído por elementos da interface do sistema (como o notch do celular).
      body: SafeArea(
        // SingleChildScrollView permite que o conteúdo da tela seja rolável se exceder o tamanho da tela.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          // Column organiza os widgets filhos em uma coluna vertical.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do perfil
              Row(
                children: [
                  // Exibe a imagem de perfil do usuário.
                  const CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://placehold.co/60x60/FFFFFF/000000?text=HP',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Texto de saudação para o usuário.
                      Text(
                        'HI JAMES',
                        style: GoogleFonts.lexend(
                          color: CustomColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Subtítulo ou status do usuário.
                      Text(
                        'Fitness Freak',
                        style: GoogleFonts.lexend(
                          color: CustomColors.textLight.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Calendário no topo
              // Chama o método que constrói e exibe o widget do calendário.
              _buildCalendar(),
              const SizedBox(height: 20),
              // Métricas do dia
              // Chama o método que constrói a linha de cards com as métricas da atividade.
              _buildMetricsCards(),
              const SizedBox(height: 20),
              // Nova seção de desafios
              // Chama o método que constrói o card de resumo dos desafios.
              _buildChallengesCard(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o card que exibe um resumo dos desafios e permite a navegação para a tela de desafios.
  Widget _buildChallengesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GestureDetector torna a área do título clicável para navegação.
          GestureDetector(
            onTap: () {
              // Navega para a tela de desafios (`ChallengesScreen`) ao ser tocado.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChallengesScreen(),
                ),
              );
            },
            // Row para alinhar o título e o ícone de seta horizontalmente.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Título da seção de desafios.
                    Text(
                      'Desafios Conquistados',
                      style: GoogleFonts.lexend(
                        color: CustomColors.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Exibe a contagem de desafios conquistados.
                    Text(
                      '(4)',
                      style: GoogleFonts.lexend(
                        color: CustomColors.textLight.withOpacity(0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Ícone de seta para indicar que a seção é navegável.
                Icon(
                  Icons.arrow_forward_ios,
                  color: CustomColors.textLight,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Row que exibe uma prévia de alguns ícones de desafios.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChallengeItem(
                icon: Icons.directions_run,
                label: 'Primeiros 5k',
              ),
              _buildChallengeItem(
                icon: Icons.fitness_center,
                label: 'Mais de 10k',
              ),
              _buildChallengeItem(
                icon: Icons.star,
                label: 'Três meses seguidos',
              ),
              _buildChallengeItem(
                icon: Icons.local_fire_department,
                label: 'Queimando calorias',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói um item individual de desafio (ícone e rótulo).
  Widget _buildChallengeItem({required IconData icon, required String label}) {
    return Column(
      children: [
        // CircleAvatar serve como um fundo circular para o ícone.
        CircleAvatar(
          backgroundColor: CustomColors.primary.withOpacity(0.2),
          child: Icon(icon, color: CustomColors.primary),
        ),
        const SizedBox(height: 8),
        // Text exibe o rótulo do desafio abaixo do ícone.
        Text(
          label,
          style: GoogleFonts.lexend(
            color: CustomColors.textLight,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Constrói a linha horizontal que contém os quatro cards de métricas.
  Widget _buildMetricsCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Expanded garante que cada card de métrica ocupe um espaço igual na linha.
        Expanded(
          child: _buildMetricsCard(
            color: CustomColors.card,
            icon: Icons.directions_run,
            iconColor: CustomColors.primary,
            title: '6,28',
            value: 'KM',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricsCard(
            color: CustomColors.card,
            icon: Icons.schedule,
            iconColor: CustomColors.primary,
            title: '50:14',
            value: 'TEMPO',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricsCard(
            color: CustomColors.card,
            icon: Icons.speed,
            iconColor: CustomColors.primary,
            title: '5.19',
            value: 'VELOCIDADE',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricsCard(
            color: CustomColors.card,
            icon: Icons.local_fire_department,
            iconColor: CustomColors.primary,
            title: '454',
            value: 'CALORIAS',
          ),
        ),
      ],
    );
  }

  /// Constrói um card individual para exibir uma métrica (ex: distância, tempo).
  Widget _buildMetricsCard({
    required Color color,
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
    // Container é o corpo do card.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      // Column organiza o ícone, o valor e o rótulo verticalmente.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone que representa a métrica.
          Icon(icon, color: iconColor ?? Colors.white, size: 24),
          const SizedBox(height: 8),
          // Texto principal, exibindo o valor da métrica (ex: "6,28").
          Text(
            title,
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Texto secundário, exibindo a unidade da métrica (ex: "KM").
          Text(
            value,
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o widget do calendário usando o pacote `table_calendar`.
  Widget _buildCalendar() {
    // Container que envolve o calendário, aplicando cor de fundo e bordas arredondadas.
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.card,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TableCalendar(
        // Define o idioma do calendário para português do Brasil.
        locale: 'pt_BR',
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        // Predicado para determinar qual dia está selecionado.
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        // Callback executado quando um dia é selecionado.
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        // Estilização do cabeçalho do calendário (título do mês e setas de navegação).
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.lexend(
            color: CustomColors.textLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: const Icon(
            Icons.arrow_back_ios,
            color: CustomColors.textLight,
            size: 16,
          ),
          rightChevronIcon: const Icon(
            Icons.arrow_forward_ios,
            color: CustomColors.textLight,
            size: 16,
          ),
        ),
        // Estilização dos dias do calendário (dias normais, fim de semana, dia selecionado, dia atual).
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(
            color: CustomColors.textLight.withOpacity(0.7),
          ),
          weekendTextStyle: TextStyle(
            color: CustomColors.textLight.withOpacity(0.7),
          ),
          todayDecoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: CustomColors.textLight,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: const BoxDecoration(
            color: CustomColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: CustomColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Estilização dos nomes dos dias da semana (Seg, Ter, Qua...).
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: CustomColors.textLight),
          weekendStyle: TextStyle(color: CustomColors.textLight),
        ),
        // `calendarBuilders` permite construir widgets customizados para dias específicos.
        calendarBuilders: CalendarBuilders(
          // `todayBuilder` customiza a aparência do dia atual.
          todayBuilder: (context, day, focusedDay) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: const BoxDecoration(
                  color: CustomColors.primary,
                  shape: BoxShape.circle,
                ),
                // Exibe um ícone de corrida no dia de hoje.
                child: const Icon(
                  Icons.directions_run,
                  color: CustomColors.primary,
                  size: 18,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
