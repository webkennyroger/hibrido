import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/services/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import '../widgets/activity_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => ActivityScreenState();
}

class ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  final ActivityRepository _repository = ActivityRepository();
  late Future<List<ActivityData>> _activitiesFuture;

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
    // Carrega as atividades salvas quando a tela é iniciada.
    reloadActivities();
    _listenToSpotifyPlayerState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recarrega as atividades quando o app volta para o primeiro plano,
    // garantindo que a lista esteja sempre atualizada.
    if (state == AppLifecycleState.resumed) reloadActivities();
  }

  /// Carrega ou recarrega a lista de atividades do repositório.
  void reloadActivities() {
    _activitiesFuture = _repository.getActivities();
    if (mounted) setState(() {});
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Atividades',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
      ),
      // Usa um FutureBuilder para construir a UI com base no estado do carregamento das atividades.
      body: Stack(
        children: [
          FutureBuilder<List<ActivityData>>(
            future: _activitiesFuture,
            builder: (context, snapshot) {
              // Mostra um indicador de progresso enquanto os dados estão carregando.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Mostra uma mensagem de erro se algo der errado.
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar atividades: ${snapshot.error}'),
                );
              }
              // Mostra uma mensagem se não houver atividades salvas.
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Não tem atividades',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.text.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              }

              final activities = snapshot.data!;

              // Constrói a lista de atividades quando os dados estiverem prontos.
              // Adiciona o RefreshIndicator para permitir "puxar para atualizar".
              return RefreshIndicator(
                onRefresh: () async => reloadActivities(),
                child: ListView.separated(
                  // Adiciona padding na parte inferior para não sobrepor o player
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    // Para cada item na lista de dados, criamos um widget de card.
                    return ActivityCard(
                      activityData: activities[index],
                      onDelete:
                          reloadActivities, // Passa a função de recarregar
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                ),
              );
            },
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
    );
  }

  /// Constrói o widget do miniplayer de música.
  Widget _buildMinimizedPlayer() {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image(
              image: _trackImage,
              width: 48,
              height: 48,
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
                    color: colors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _artistName,
                  style: GoogleFonts.lexend(color: colors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isMusicPlaying ? Icons.pause : Icons.play_arrow,
              color: colors.text,
              size: 32,
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
            icon: Icon(Icons.skip_next, color: colors.text, size: 32),
            onPressed: () {
              _spotifyService.skipNext();
            },
          ),
        ],
      ),
    );
  }
}
