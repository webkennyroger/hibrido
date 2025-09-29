// main_screen.dart
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
import 'package:hibrido/services/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum ActivityState { notStarted, running, paused, finished }

enum MapTypeOption { normal, satellite, hybrid, winter }

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  MapType _currentMapType = MapType.normal;
  double _currentCameraTilt = 0.0;
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

  // Novos estados para as opções de mapa e camadas
  MapTypeOption _selectedMapType = MapTypeOption.normal;

  bool _showMapOptions = false;

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
    _listenToGpsStatusChanges();
    _getCurrentLocation();
    _listenToSpotifyPlayerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _listenToSpotifyPlayerState() {
    _playerStateSubscription = SpotifySdk.subscribePlayerState().listen((
      playerState,
    ) {
      if (mounted) {
        setState(() {
          _isMusicPlaying = !playerState.isPaused;
          _trackName = playerState.track?.name ?? 'Música desconhecida';
          _artistName =
              playerState.track?.artist.name ?? 'Artista desconhecido';
        });
      }
    });
  }

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
    await _updatePlayerState();
  }

  void _playPreviousTrack() async {
    await _spotifyService.skipPrevious();
    await _updatePlayerState();
  }

  void _startPlaylist() async {
    final playlistUri = await _spotifyService.getPlaylistUri();
    if (playlistUri != null) {
      await _spotifyService.playTrack(playlistUri);
      await _updatePlayerState();
    }
  }

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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
          tilt: _currentCameraTilt,
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
          _stopwatch.reset();
          _routePoints.clear();
          _polylines.clear();
          _totalDistanceInMeters = 0.0;
          _caloriesBurned = 0.0;
          _activityState = ActivityState.running;
          _stopwatch.start();
          _startTimer();
          _startTrackingLocation(resume: false);
          break;
        case ActivityState.running:
          _activityState = ActivityState.paused;
          _stopwatch.stop();
          _timer?.cancel();
          _positionStreamSubscription?.pause();
          break;
        case ActivityState.paused:
          _activityState = ActivityState.running;
          _stopwatch.start();
          _startTimer();
          _startTrackingLocation(resume: true);
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

  void _updateMapType(MapTypeOption option) {
    setState(() {
      _selectedMapType = option;
      switch (option) {
        case MapTypeOption.normal:
          _currentMapType = MapType.normal;
          break;
        case MapTypeOption.satellite:
          _currentMapType = MapType.satellite;
          break;
        case MapTypeOption.hybrid:
          _currentMapType = MapType.hybrid;
          break;
        case MapTypeOption.winter:
          // A lógica para 'Inverno' seria mais complexa, exigindo um
          // serviço de mapa ou conjunto de dados de terceiros.
          // Por enquanto, vamos manter o padrão.
          _currentMapType = MapType.normal;
          break;
        // No default case
      }
    });
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
                  mapType: _currentMapType,
                  tiltGesturesEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 16.0,
                    tilt: _currentCameraTilt,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 8),
                ),
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
                  child: const Icon(
                    Icons.route_outlined,
                    color: CustomColors.textDark,
                  ),
                  onTap:
                      () {}, // Ação para a tela de rotas pode ser adicionada aqui
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
          if (_activityState == ActivityState.notStarted)
            Positioned(
              bottom: 200,
              right: 20,
              child: Column(
                children: [
                  _buildMapControlButton(
                    icon: Icons.layers_outlined,
                    onPressed: () {
                      setState(() {
                        _showMapOptions = !_showMapOptions;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildMapControlButton(
                    icon: Icons.threed_rotation,
                    onPressed: _toggle3DView,
                  ),
                  const SizedBox(height: 10),
                  _buildMapControlButton(
                    icon: Icons.my_location,
                    onPressed: _centerOnLocation,
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
                _buildStatsCard(_durationText, '', 'Duração'),
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
                  color: Colors.white.withAlpha((255 * 0.4).round()),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha((255 * 0.6).round()),
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
                          colorFilter: ColorFilter.mode(
                            CustomColors.primary.withAlpha((255 * 0.4).round()),
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
          if (_showMapOptions) _buildMapOptionSelector(),
        ],
      ),
    );
  }

  Widget _buildMapOptionSelector() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            setState(() {
              _showMapOptions = false;
            });
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF232530),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.3).round()),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tipos de mapa',
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildMapOptionsRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMapOptionItem(
          icon: 'assets/images/maps/map_standard.png',
          label: 'Padrão',
          option: MapTypeOption.normal,
          isSelected: _selectedMapType == MapTypeOption.normal,
          onTap: () => _updateMapType(MapTypeOption.normal),
        ),
        _buildMapOptionItem(
          icon: 'assets/images/maps/map_satellite.png',
          label: 'Satélite',
          option: MapTypeOption.satellite,
          isSelected: _selectedMapType == MapTypeOption.satellite,
          onTap: () => _updateMapType(MapTypeOption.satellite),
        ),
        _buildMapOptionItem(
          icon: 'assets/images/maps/map_hybrid.png',
          label: 'Híbrido',
          option: MapTypeOption.hybrid,
          isSelected: _selectedMapType == MapTypeOption.hybrid,
          onTap: () => _updateMapType(MapTypeOption.hybrid),
        ),
      ],
    );
  }

  Widget _buildMapOptionItem({
    required String icon,
    required String label,
    required dynamic option,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        width: 70,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? CustomColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      icon,
                      fit: BoxFit.cover,
                      color: isLocked
                          ? Colors.white.withAlpha((255 * 0.5).round())
                          : null,
                      colorBlendMode: isLocked ? BlendMode.modulate : null,
                    ),
                  ),
                ),
                if (isLocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.lock, color: Colors.white, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // e o player do Spotify,
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
                  color: CustomColors.primary.withAlpha((255 * 0.25).round()),
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
                              color: Colors.white.withAlpha(
                                // This was already corrected in the provided file.
                                (255 * 0.7).round(),
                              ),
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
        return _RunningControls(onPressed: _onMainActionButtonPressed);
      case ActivityState.paused:
        return _PausedControls(
          onResume: _onMainActionButtonPressed,
          onStop: _onStopButtonPressed,
        );
      case ActivityState.notStarted:
      case ActivityState.finished:
        return _NotStartedControls(
          onStart: _onMainActionButtonPressed,
          onMusic: _toggleSpotifyPlayer,
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
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 5,
            ),
          ],
        ),
        child: child,
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
            color: Colors.black.withAlpha((255 * 0.1).round()),
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
              color: Colors.black.withAlpha((255 * 0.1).round()),
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

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 5,
            ),
          ],
        ),
        child: Icon(icon, color: CustomColors.textDark, size: 24),
      ),
    );
  }

  void _toggle3DView() {
    final newTilt = _currentCameraTilt == 0.0 ? 60.0 : 0.0;
    setState(() {
      _currentCameraTilt = newTilt;
    });
    _centerOnLocation(); // Re-centraliza com a nova inclinação
  }

  void _centerOnLocation() {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 17,
            tilt: _currentCameraTilt,
          ),
        ),
      );
    }
  }

  void _toggleSpotifyPlayer() {
    setState(() {
      _isPlayerVisible = !_isPlayerVisible;
      if (_isPlayerVisible && !_isSpotifyConnected) {
        _spotifyService.initializeAndAuthenticate().then((isConnected) {
          if (mounted) {
            setState(() {
              _isSpotifyConnected = isConnected;
              if (isConnected) _startPlaylist();
            });
          }
        });
      }
    });
  }
}

class _NotStartedControls extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onMusic;

  const _NotStartedControls({required this.onStart, required this.onMusic});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildActionButton(
          Icons.music_note_outlined,
          CustomColors.tertiary,
          onTap: onMusic,
        ),
        _buildStartButton(),
        _buildIconWithLabel(
          icon: 'assets/images/sapato.svg',
          label: 'Corrida',
          iconSize: 30,
          onTap: () {},
        ),
      ],
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
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: onStart,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CustomColors.primary,
          boxShadow: [
            BoxShadow(
              color: CustomColors.primary.withAlpha((255 * 0.4).round()),
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

  Widget _buildIconWithLabel({
    required String icon,
    required String label,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CustomColors.primary.withAlpha((255 * 0.6).round()),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.1).round()),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                icon,
                colorFilter: const ColorFilter.mode(
                  CustomColors.textDark,
                  BlendMode.srcIn,
                ),
                width: iconSize,
              ),
            ),
          ),
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CustomColors.tertiary,
              ),
              child: const Icon(
                Icons.directions_run,
                color: CustomColors.primary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningControls extends StatelessWidget {
  final VoidCallback onPressed;
  const _RunningControls({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_buildPauseButton()],
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CustomColors.primary,
          boxShadow: [
            BoxShadow(
              color: CustomColors.primary.withAlpha((255 * 0.4).round()),
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
}

class _PausedControls extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _PausedControls({required this.onResume, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [_buildPlayButton(), _buildStopButton()],
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: onResume,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: CustomColors.primary,
          boxShadow: [
            BoxShadow(
              color: CustomColors.primary.withAlpha((255 * 0.4).round()),
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
      onTap: onStop,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: CustomColors.secondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
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
