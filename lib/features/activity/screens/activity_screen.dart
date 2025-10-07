import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/services/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:hibrido/widgets/activity_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => ActivityScreenState();
}

class ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  final ActivityRepository _repository = ActivityRepository();
  // NOVO: Gerencia a lista de atividades no estado.
  List<ActivityData> _activities = [];
  bool _isLoading = true;

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
    if (mounted) setState(() => _isLoading = true);
    _repository.getActivities().then((loadedActivities) {
      if (mounted) {
        setState(() {
          _activities = loadedActivities;
          _isLoading = false;
        });
      }
    });
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
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColors colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activities.isEmpty) {
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

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async => reloadActivities(),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              return ActivityCard(
                activityData: _activities[index],
                onDelete: () {
                  setState(() {
                    _activities.removeAt(index);
                  });
                },
                onUpdate: (updatedActivity) {
                  setState(() {
                    _activities[index] = updatedActivity;
                  });
                },
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
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
