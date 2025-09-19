import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/activity/screens/activity_detail_screen.dart';
import 'package:hibrido/features/profile/screens/profile_screen.dart';
import 'package:hibrido/services/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum ActivityState { notStarted, running, paused, finished }

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isGpsOn = false;
  final Set<Polyline> _polylines = {};

  ActivityState _activityState = ActivityState.notStarted;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _durationText = '00:00';
  double _totalDistanceInMeters = 0.0;
  double _caloriesBurned = 0.0;
  final List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _playerStateSubscription;

  bool _isPlayerVisible = false;

  final SpotifyService _spotifyService = SpotifyService();
  String _trackName = 'Nenhuma música';
  String _artistName = 'Conecte-se ao Spotify';
  bool _isMusicPlaying = false;
  bool _isSpotifyConnected = false;

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
    _listenToGpsStatusChanges();
    _getCurrentLocation();
    _listenToSpotifyPlayerState(); // Novo método para ouvir o player
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _playerStateSubscription?.cancel(); // Cancela a inscrição do listener
    _mapController?.dispose();
    super.dispose();
  }

  // Novo método para ouvir as mudanças de estado do player do Spotify
  void _listenToSpotifyPlayerState() {
    _playerStateSubscription = SpotifySdk.subscribePlayerState().listen((
      playerState,
    ) {
      if (mounted) {
        setState(() {
          _isMusicPlaying = playerState.isPaused != null
              ? !playerState.isPaused!
              : false;
          _trackName = playerState.track?.name ?? 'Música desconhecida';
          _artistName =
              playerState.track?.artist.name ?? 'Artista desconhecido';
        });
      }
    });
  }

  Future<void> _connectToSpotify() async {
    final isConnected = await _spotifyService.initializeAndAuthenticate();
    if (mounted) {
      setState(() {
        _isSpotifyConnected = isConnected;
        if (isConnected) {
          _artistName = 'Conectado!';
          _startPlaylist();
        } else {
          _artistName = 'Falha na conexão';
        }
      });
    }
  }

  // O método _updatePlayerState não é mais necessário, pois o listener faz isso
  // de forma mais eficiente. No entanto, é bom mantê-lo para chamadas pontuais.
  Future<void> _updatePlayerState() async {
    final trackInfo = await _spotifyService.getCurrentTrack();
    if (mounted && trackInfo != null) {
      setState(() {
        _trackName = trackInfo['name'] ?? 'Música desconhecida';
        _artistName = trackInfo['artist'] ?? 'Artista desconhecido';
        _isMusicPlaying = trackInfo['is_playing'] ?? false;
      });
    }
  }

  void _handlePlayPause() async {
    if (_isMusicPlaying) {
      await _spotifyService.pause();
    } else {
      final trackInfo = await _spotifyService.getCurrentTrack();
      if (trackInfo == null) {
        _startPlaylist();
      } else {
        await _spotifyService.resume();
      }
    }
  }

  void _playNextTrack() async {
    await _spotifyService.skipNext();
    await _updatePlayerState(); // Atualiza a UI para mostrar a nova música
  }

  void _playPreviousTrack() async {
    await _spotifyService.skipPrevious();
    await _updatePlayerState(); // Atualiza a UI para mostrar a nova música
  }

  void _startPlaylist() async {
    final playlistUri = await _spotifyService.getPlaylistUri();
    if (playlistUri != null) {
      await _spotifyService.playTrack(playlistUri);
      // Força a atualização da UI com as informações da nova música
      await _updatePlayerState();
    }
  }

  // Seus outros métodos (checkGpsStatus, getCurrentLocation, etc.)
  Future<void> _checkGpsStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _isGpsOn = serviceEnabled;
    });
  }

  void _listenToGpsStatusChanges() {
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      setState(() {
        _isGpsOn = status == ServiceStatus.enabled;
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Serviço de localização desabilitado. Por favor, ative o GPS.',
            ),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de localização negada.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Sua Localização'),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  void _onMainActionButtonPressed() {
    if (!_isGpsOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ligue o GPS para iniciar a atividade.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      switch (_activityState) {
        case ActivityState.notStarted:
        case ActivityState.paused:
          _activityState = ActivityState.running;
          _stopwatch.start();
          _startTimer();
          _startTrackingLocation(resume: true);
          break;
        case ActivityState.running:
          _activityState = ActivityState.paused;
          _stopwatch.stop();
          _timer?.cancel();
          _positionStreamSubscription?.pause();
          break;
        case ActivityState.finished:
          break;
      }
    });
  }

  void _onStopButtonPressed() {
    setState(() {
      _stopwatch.stop();
      _timer?.cancel();
      _positionStreamSubscription?.cancel();
      _activityState = ActivityState.finished;

      final activityDuration = _stopwatch.elapsed;
      final activityData = ActivityData(
        userName: 'Kenny',
        activityTitle: 'Corrida',
        runTime: 'Manhã de Quarta-feira',
        location: 'São Paulo, SP',
        distanceInMeters: _totalDistanceInMeters,
        duration: _stopwatch.elapsed,
        routePoints: List.from(_routePoints),
        calories: _caloriesBurned,
        likes: 0,
        comments: 0,
        shares: 0,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ActivityDetailScreen(activityData: activityData),
        ),
      ).then((_) {
        setState(() {
          _activityState = ActivityState.notStarted;
          _stopwatch.reset();
          _durationText = '00:00';
          _totalDistanceInMeters = 0.0;
          _caloriesBurned = 0.0;
          _routePoints.clear();
          _polylines.clear();
        });
      });
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _durationText =
            '${_stopwatch.elapsed.inMinutes.toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  void _startTrackingLocation({bool resume = false}) {
    if (_positionStreamSubscription != null) {
      if (resume) {
        _positionStreamSubscription?.resume();
      }
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (_activityState != ActivityState.running) return;

            setState(() {
              if (_routePoints.isNotEmpty) {
                final lastPoint = _routePoints.last;
                final distance = Geolocator.distanceBetween(
                  lastPoint.latitude,
                  lastPoint.longitude,
                  position.latitude,
                  position.longitude,
                );
                _totalDistanceInMeters += distance;
                _caloriesBurned = _totalDistanceInMeters / 16;
              }
              _routePoints.add(LatLng(position.latitude, position.longitude));

              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _routePoints,
                  color: CustomColors.primary,
                  width: 5,
                ),
              );

              _mapController?.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(position.latitude, position.longitude),
                ),
              );
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.quaternary,
      body: Stack(
        children: [
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 16.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 8),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopIcon(
                  child: const Icon(Icons.person, color: CustomColors.textDark),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildTopIcon(
                  child: const Icon(
                    Icons.settings,
                    color: CustomColors.textDark,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatsCard(
                  (_totalDistanceInMeters / 1000).toStringAsFixed(2),
                  'km',
                  'Distância',
                ),
                _buildStatsCard(_durationText, 'h', 'Duração'),
                _buildStatsCard(
                  _caloriesBurned.toStringAsFixed(0),
                  'kcal',
                  'Calorias',
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 200,
            left: 20,
            right: 20,
            child: Center(child: _buildGpsButton()),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2.8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.4),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: CustomColors.quaternary,
                        ),
                        child: SvgPicture.asset(
                          'assets/images/sapato.svg',
                          colorFilter: const ColorFilter.mode(
                            CustomColors.primary,
                            BlendMode.srcIn,
                          ),
                          width: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
          if (_isPlayerVisible) _buildSpotifyPlayer(),
        ],
      ),
    );
  }

  Widget _buildSpotifyPlayer() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: CustomColors.primary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        children: [
                          Text(
                            _trackName,
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _artistName,
                            style: GoogleFonts.lexend(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: _playPreviousTrack,
                        ),
                        IconButton(
                          icon: Icon(
                            _isMusicPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 50,
                          ),
                          onPressed: _handlePlayPause,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: _playNextTrack,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: CustomColors.tertiary,
                    size: 24,
                  ),
                  onPressed: () {
                    _spotifyService.pause();
                    setState(() => _isPlayerVisible = false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    switch (_activityState) {
      case ActivityState.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildPauseButton()],
        );
      case ActivityState.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildPlayButton(), _buildStopButton()],
        );
      case ActivityState.notStarted:
      case ActivityState.finished:
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildActionButton(
              Icons.music_note_outlined,
              CustomColors.tertiary,
              onTap: () {
                setState(() {
                  _isPlayerVisible = !_isPlayerVisible;
                  if (_isPlayerVisible && !_isSpotifyConnected) {
                    _connectToSpotify();
                  }
                });
              },
            ),
            _buildStartButton(),
            _buildActionButton(
              Icons.track_changes_outlined,
              CustomColors.tertiary,
            ),
          ],
        );
    }
  }

  Widget _buildTopIcon({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CustomColors.secondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  Widget _buildStatsCard(String value, String unit, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(color: CustomColors.textDark),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: CustomColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.lexend(
              color: CustomColors.tertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsButton() {
    return GestureDetector(
      onTap: () async {
        await Geolocator.openLocationSettings();
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              color: _isGpsOn ? CustomColors.primary : CustomColors.textDark,
              size: 20,
            ),
            const SizedBox(width: 5),
            Text(
              _isGpsOn ? 'GPS - ON' : 'GPS - OFF',
              style: GoogleFonts.lexend(
                color: _isGpsOn ? CustomColors.primary : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _onMainActionButtonPressed,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CustomColors.primary,
          boxShadow: [
            BoxShadow(
              color: CustomColors.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'COMEÇAR',
            style: GoogleFonts.lexend(
              color: CustomColors.tertiary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: _onMainActionButtonPressed,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CustomColors.primary,
          boxShadow: [
            BoxShadow(
              color: CustomColors.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.pause, color: CustomColors.tertiary, size: 50),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _onMainActionButtonPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: CustomColors.primary,
          boxShadow: [
            BoxShadow(
              color: CustomColors.primary.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_arrow,
              color: CustomColors.tertiary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'RETOMAR',
              style: GoogleFonts.lexend(
                color: CustomColors.tertiary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: _onStopButtonPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: CustomColors.secondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stop, color: CustomColors.tertiary, size: 20),
            const SizedBox(width: 8),
            Text(
              'CONCLUIR',
              style: GoogleFonts.lexend(
                color: CustomColors.tertiary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
