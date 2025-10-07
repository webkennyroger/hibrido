import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/challenges/screens/challenges_screen.dart';
import 'package:hibrido/features/settings/screens/account_settings_screen.dart';
import 'package:hibrido/providers/user_provider.dart';
import 'package:hibrido/services/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.week;

  // --- Spotify State ---
  final SpotifyService _spotifyService = SpotifyService();
  StreamSubscription? _playerStateSubscription;
  bool _isPlayerVisible = false;
  String _trackName = '';
  String _artistName = '';
  bool _isMusicPlaying = false;
  ImageProvider _trackImage = const AssetImage(
    'assets/images/spotify_placeholder.png',
  );

  @override
  void initState() {
    super.initState();
    _listenToSpotifyPlayerState();
    _pageController.addListener(() {
      setState(() {
        // int _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Lida com a ação de "puxar para atualizar".
  Future<void> _handleRefresh() async {
    // Simula uma chamada de rede ou recarregamento de dados.
    await Future.delayed(const Duration(seconds: 1));

    // Se você tiver dados que precisam ser recarregados (ex: de uma API),
    // a lógica de recarregamento viria aqui.
    if (mounted) {
      setState(() {
        // Atualiza a UI se necessário após carregar os novos dados.
      });
    }
  }

  /// Ouve as mudanças no estado do player do Spotify.
  void _listenToSpotifyPlayerState() {
    // Primeiro, tenta conectar silenciosamente.
    _spotifyService.initializeAndAuthenticate();

    _playerStateSubscription = SpotifySdk.subscribePlayerState().listen((
      playerState,
    ) {
      if (mounted) {
        final isPlaying = playerState.track != null && !playerState.isPaused;
        setState(() {
          _isPlayerVisible = isPlaying;
          if (isPlaying) {
            _trackName = playerState.track!.name;
            _artistName =
                playerState.track!.artist.name ?? 'Artista desconhecido';
            _isMusicPlaying = !playerState.isPaused;

            // Busca a imagem do álbum
            _spotifyService.getTrackImage(playerState.track!).then((image) {
              if (mounted) setState(() => _trackImage = image);
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // NOVO: Consome os dados do UserProvider
    final user = context.watch<UserProvider>().user;

    // Scaffold é a estrutura base da tela, fornecendo appBar, body, etc.
    return Scaffold(
      // Define a cor de fundo da tela para um tom de cinza escuro.
      backgroundColor: colors.background,
      // SafeArea garante que o conteúdo não seja obstruído por elementos da interface do sistema (como o notch do celular).
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _handleRefresh,
              // SingleChildScrollView permite que o conteúdo da tela seja rolável se exceder o tamanho da tela.
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Garante que o scroll sempre funcione
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
                // Column organiza os widgets filhos em uma coluna vertical.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header do perfil
                    _buildHeader(context, user),
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
            // Miniplayer do Spotify
            if (_isPlayerVisible)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildMinimizedPlayer(),
              ),
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho da tela com informações do usuário e botão de configurações.
  // Widget _buildHeader(BuildContext context, dynamic user) { // <-- Linha removida por engano
  Widget _buildHeader(BuildContext context, dynamic user) {
    // <-- Linha restaurada
    final colors = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(backgroundImage: user.profileImage),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.toUpperCase(),
                  style: GoogleFonts.lexend(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user.location,
                  style: GoogleFonts.lexend(
                    color: colors.text.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Botão de Configurações
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountSettingsScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
              ],
            ),
            child: Icon(Icons.settings, color: colors.text),
          ),
        ),
      ],
    );
  }

  /// Constrói o widget do miniplayer de música.
  Widget _buildMinimizedPlayer() {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.text.withOpacity(0.2),
                AppColors.primary.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: _trackImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _trackName,
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _artistName,
                      style: GoogleFonts.lexend(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isMusicPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  if (_isMusicPlaying) {
                    _spotifyService.pause();
                  } else {
                    _spotifyService.resume();
                  }
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  _spotifyService.skipNext();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o card que exibe um resumo dos desafios e permite a navegação para a tela de desafios.
  Widget _buildChallengesCard(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
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
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Exibe a contagem de desafios conquistados.
                    Text(
                      '(4)',
                      style: GoogleFonts.lexend(
                        color: colors.text.withOpacity(0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Ícone de seta para indicar que a seção é navegável.
                Icon(Icons.arrow_forward_ios, color: colors.text, size: 16),
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
    final colors = AppColors.of(context);
    return Column(
      children: [
        // CircleAvatar serve como um fundo circular para o ícone.
        CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        // Text exibe o rótulo do desafio abaixo do ícone.
        Text(
          label,
          style: GoogleFonts.lexend(color: colors.text, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Constrói a linha horizontal que contém os quatro cards de métricas.
  Widget _buildMetricsCards() {
    final colors = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Expanded garante que cada card de métrica ocupe um espaço igual na linha.
        Expanded(
          child: _buildMetricsCard(
            color: colors.surface,
            icon: Icons.directions_run,
            iconColor: AppColors.primary,
            title: '6,28',
            value: 'KM',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricsCard(
            color: colors.surface,
            icon: Icons.schedule,
            iconColor: AppColors.primary,
            title: '50:14',
            value: 'TEMPO',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricsCard(
            color: colors.surface,
            icon: Icons.speed,
            iconColor: AppColors.primary,
            title: '5.19',
            value: 'VELOCIDADE',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricsCard(
            color: colors.surface,
            icon: Icons.local_fire_department,
            iconColor: AppColors.primary,
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
    final colors = AppColors.of(context);
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
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Texto secundário, exibindo a unidade da métrica (ex: "KM").
          Text(
            value,
            style: GoogleFonts.lexend(
              color: colors.text.withOpacity(0.7),
              fontSize: 08,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o widget do calendário usando o pacote `table_calendar`.
  Widget _buildCalendar() {
    final colors = AppColors.of(context);
    // Container que envolve o calendário, aplicando cor de fundo e bordas arredondadas.
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
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
            color: colors.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: Icon(
            Icons.arrow_back_ios,
            color: colors.text,
            size: 16,
          ),
          rightChevronIcon: Icon(
            Icons.arrow_forward_ios,
            color: colors.text,
            size: 16,
          ),
        ),
        // Estilização dos dias do calendário (dias normais, fim de semana, dia selecionado, dia atual).
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: colors.text.withOpacity(0.7)),
          weekendTextStyle: TextStyle(color: colors.text.withOpacity(0.7)),
          todayDecoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Estilização dos nomes dos dias da semana (Seg, Ter, Qua...).
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: colors.text),
          weekendStyle: TextStyle(color: colors.text),
        ),
        // `calendarBuilders` permite construir widgets customizados para dias específicos.
        calendarBuilders: CalendarBuilders(
          // `todayBuilder` customiza a aparência do dia atual.
          todayBuilder: (context, day, focusedDay) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                // Exibe um ícone de corrida no dia de hoje.
                child: Icon(
                  Icons.directions_run,
                  color: AppColors.dark().background,
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
