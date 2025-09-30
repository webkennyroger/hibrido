// main_screen.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Certifique-se de que o caminho para o seu arquivo de cores está correto
import 'package:hibrido/core/theme/custom_colors.dart';
// Certifique-se de que os caminhos para os arquivos de dados e tela estão corretos
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/activity/screens/activity_detail_screen.dart';
import 'package:hibrido/features/map/screens/finished_confirmation_sheet.dart';
import 'package:hibrido/services/spotify_service.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// Enum para os diferentes estados da atividade física.
enum ActivityState { notStarted, running, paused, finished }

/// Enum para as opções de tipo de mapa disponíveis para o usuário.
enum MapTypeOption { normal, satellite, hybrid }

/// Enum para as opções de esporte.
enum SportOption { corrida, pedalada, caminhada }

class _MapScreenState extends State<MapScreen> {
  // Controlador para interagir com o Google Map.
  GoogleMapController? _mapController;
  // Posição geográfica atual do usuário.
  Position? _currentPosition;
  // Conjunto de marcadores a serem exibidos no mapa (ex: localização atual).
  final Set<Marker> _markers = {};
  // Tipo atual do mapa (normal, satélite, etc.).
  MapType _currentMapType = MapType.normal;
  // Inclinação atual da câmera do mapa para a visualização 3D.
  double _currentCameraTilt = 0.0;
  // Flag que indica se o GPS do dispositivo está ativado.
  bool _isGpsOn = false;
  // Conjunto de polilinhas para desenhar a rota da atividade no mapa.
  final Set<Polyline> _polylines = {};

  // Estado atual da atividade (não iniciada, correndo, pausada, finalizada).
  ActivityState _activityState = ActivityState.notStarted;

  // Cronômetro para medir a duração da atividade.
  final Stopwatch _stopwatch = Stopwatch();
  // Timer para atualizar a interface do usuário com a duração do cronômetro.
  Timer? _timer;
  // Texto formatado da duração (ex: "00:00").
  String _durationText = '00:00';
  // Distância total percorrida em metros.
  double _totalDistanceInMeters = 0.0;
  // Estimativa de calorias queimadas durante a atividade.
  double _caloriesBurned = 0.0;
  // NOVO: Ritmo atual (min/km)
  String _currentPaceText = '00:00';
  // NOVO: Ritmo médio (min/km)
  String _averagePaceText = '00:00';
  // Lista de coordenadas geográficas que compõem a rota percorrida.
  final List<LatLng> _routePoints = [];
  // Inscrição no stream de atualizações de posição do Geolocator.
  StreamSubscription<Position>? _positionStreamSubscription;
  // Inscrição no stream de estado do player do Spotify.
  StreamSubscription? _playerStateSubscription;

  // Controla a visibilidade do widget do player do Spotify.
  bool _isPlayerVisible = false;

  // Serviço para interagir com a API do Spotify.
  final SpotifyService _spotifyService = SpotifyService();
  // Nome da música atualmente tocando no Spotify.
  String _trackName = 'Nenhuma música';
  // Nome do artista da música atual.
  String _artistName = 'Conecte-se ao Spotify';
  // Flag que indica se uma música está tocando.
  bool _isMusicPlaying = false;
  // Flag que indica se o app está conectado ao Spotify.
  bool _isSpotifyConnected = false;
  // Imagem do álbum da música atual.
  ImageProvider _trackImage =
      const AssetImage('assets/images/spotify_placeholder.png');
  // Duração total e posição atual da música para a barra de progresso.
  int _trackDuration = 0;
  int _trackPosition = 0;

  // Opção de tipo de mapa selecionada pelo usuário na interface.
  MapTypeOption _selectedMapType = MapTypeOption.normal;
  // Controla a visibilidade do seletor de tipos de mapa.
  bool _showMapOptions = false;

  // Opção de esporte selecionada pelo usuário.
  SportOption _selectedSport = SportOption.corrida;
  // Controla a visibilidade do seletor de esportes.
  bool _showSportSelector = false;

  // Ícone customizado para o marcador de localização.
  BitmapDescriptor? _locationMarkerIcon;

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
    _listenToGpsStatusChanges();
    _initializeMap();
    _listenToSpotifyPlayerState();
  }

  @override
  /// Libera os recursos (timers, streams, controllers) quando o widget é descartado.
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Inicializa o mapa e o marcador customizado.
  Future<void> _initializeMap() async {
    // Cria e carrega o ícone customizado para o marcador de localização.
    _locationMarkerIcon = await _createCustomMarkerBitmap();
    // Obtém a localização inicial após carregar o ícone.
    await _getCurrentLocation();
  }

  /// Cria um BitmapDescriptor customizado para o marcador de localização.
  /// Implementa o círculo azul, a borda branca e o cone de direção (farol).
  Future<BitmapDescriptor> _createCustomMarkerBitmap() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 100.0; // Tamanho total do ícone, incluindo sombra
    const double center = size / 2;
    
    // Raio do círculo azul
    const double blueRadius = size / 3 - 4;
    
    // =========================================================================
    // 1. Desenha o "farol" (cone) de direção - Translúcido e Grande
    // O cone aponta para cima (direção 0), e será rotacionado pelo Marker.
    // =========================================================================
    final Paint farolHaloPaint = Paint()..color = Colors.white.withOpacity(0.2); // Halo branco translúcido
    final farolPath = Path()
      ..moveTo(center, center) // Começa no centro do círculo
      ..lineTo(center - 30, center - 120) // Ponto lateral esquerdo (mais longe)
      ..lineTo(center + 30, center - 120) // Ponto lateral direito (mais longe)
      ..close();
    canvas.drawPath(farolPath, farolHaloPaint);
    
    // =========================================================================
    // 2. Desenha o círculo azul, borda e sombra (por cima do farol)
    // =========================================================================

    // Desenha o halo/sombra
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(
      const Offset(center, center),
      size / 2 - 5,
      shadowPaint,
    );

    // Desenha a borda branca (círculo maior)
    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(center, center), size / 3, whitePaint);

    // Desenha o círculo azul interno
    final Paint bluePaint = Paint()..color = Colors.blue.shade700;
    canvas.drawCircle(
      const Offset(center, center),
      blueRadius,
      bluePaint,
    );

    final img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  //================================================================================
  // Lógica de Localização e GPS (Location & GPS Logic)
  //================================================================================

  /// Obtém a localização atual do usuário, lidando com permissões.
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
      // Adiciona o marcador customizado na posição inicial.
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(position.latitude, position.longitude),
          icon: _locationMarkerIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5), // Centraliza o ícone no ponto
          flat: true, // Mantém o marcador "deitado" no mapa ao inclinar
          rotation: position.heading, // Define a rotação inicial (farol)
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

  //================================================================================
  // Lógica de Integração com Spotify (Spotify Integration Logic)
  //================================================================================

  /// Ouve as mudanças no estado do player do Spotify (play, pause, mudança de faixa).
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
          _trackDuration = playerState.track?.duration ?? 0;
          _trackPosition = playerState.playbackPosition;

          // Busca a imagem do álbum se a faixa for nova.
          if (playerState.track != null) {
            _spotifyService.getTrackImage(playerState.track!).then((image) {
              if (mounted) {
                setState(() => _trackImage = image);
              }
            });
          }
        });
      }
    });
  }

  /// Busca e atualiza as informações da faixa atual do Spotify.
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

  /// Alterna entre tocar e pausar a música no Spotify.
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

  /// Pula para a próxima música na playlist do Spotify.
  void _playNextTrack() async {
    await _spotifyService.skipNext();
    await _updatePlayerState();
  }

  /// Volta para a música anterior na playlist do Spotify.
  void _playPreviousTrack() async {
    await _spotifyService.skipPrevious();
    await _updatePlayerState();
  }

  /// Inicia a reprodução de uma playlist específica do Spotify.
  void _startPlaylist() async {
    final playlistUri = await _spotifyService.getPlaylistUri();
    if (playlistUri != null) {
      await _spotifyService.playTrack(playlistUri);
      await _updatePlayerState();
    }
  }

  /// Alterna a visibilidade do player do Spotify e lida com a autenticação inicial.
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

  //================================================================================
  // Lógica de Controle da Atividade (Activity Control Logic)
  //================================================================================
  /// Lida com o pressionar do botão de ação principal (Iniciar, Pausar, Retomar).
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
          _currentPaceText = '00:00';
          _averagePaceText = '00:00';
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

  /// Lida com o pressionar do botão de parar/concluir a atividade.
  void _onStopButtonPressed() async {
    // 1. Interrompe cronômetro e streams
    _stopwatch.stop();
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    
    // 2. Cria um objeto ActivityData TEMPORÁRIO com os dados finais.
    final tempActivityData = ActivityData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: 'Kenny',
      activityTitle: _getSportLabel(_selectedSport),
      runTime: 'Manhã de Quarta-feira',
      location: 'São Paulo, SP',
      distanceInMeters: _totalDistanceInMeters,
      duration: _stopwatch.elapsed,
      routePoints: List.from(_routePoints),
      calories: _caloriesBurned,
      likes: 0,
      commentsList: [],
      shares: 0,
    );

    // 3. Navega para a tela de confirmação (FinishedConfirmationSheet)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FinishedConfirmationSheet(
          activityData: tempActivityData,
          // Ação: Salvar, aplicar o novo título e Navegar
          onSaveAndNavigate: (newTitle) async {
            // 3a. Cria a ActivityData FINAL com o título atualizado.
            final finalActivityData = tempActivityData.copyWith(
              activityTitle: newTitle,
            );

            // 3b. Salva a atividade
            await _saveActivity(finalActivityData);

            // 3c. Fecha a tela de confirmação e a tela do mapa, retornando 'true' para indicar sucesso.
            Navigator.of(context).pop(true); // Pop FinishedConfirmationSheet
          },
          // Ação: Descartar a Atividade
          onDiscard: () {
            Navigator.of(context).pop(); // Fecha a tela de confirmação
            _resetActivityState(); // Reseta o estado.
          },
        ),
      ),
    );

    // 4. Se o resultado do Navigator.push for 'true' (atividade salva), fecha a MapScreen.
    if (context.mounted && (await result as bool? ?? false)) {
      Navigator.of(context).pop(true); // Pop MapScreen
    }
  }

  /// NOVO: Método para resetar o estado da tela de mapa.
  void _resetActivityState() {
    if (!mounted) return;
    setState(() {
      _activityState = ActivityState.notStarted;
      _stopwatch.reset();
      _durationText = '00:00';
      _totalDistanceInMeters = 0.0;
      _caloriesBurned = 0.0;
      _currentPaceText = '00:00';
      _averagePaceText = '00:00';
      _routePoints.clear();
      _polylines.clear();
      // Você também pode querer centralizar o mapa novamente aqui
      _centerOnLocation();
    });
  }

  /// Salva a atividade finalizada no armazenamento local do dispositivo.
  Future<void> _saveActivity(ActivityData newActivity) async {
    final repository = ActivityRepository();
    await repository.saveActivity(newActivity);
  }

  /// Inicia um timer que atualiza a duração da atividade na tela a cada segundo.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _durationText =
            '${_stopwatch.elapsed.inMinutes.toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  /// Inicia o rastreamento da localização do usuário para desenhar a rota.
  void _startTrackingLocation({bool resume = false}) {
    if (_positionStreamSubscription != null) {
      if (resume) {
        _positionStreamSubscription?.resume();
      }
      return;
    }

    // Configurações de precisão e filtro de distância para o rastreamento.
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          // Ignora atualizações se a atividade não estiver em andamento.
          if (_activityState != ActivityState.running) return;

          // Atualiza a posição e rotação do marcador customizado.
          final newMarker = Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(position.latitude, position.longitude),
            icon: _locationMarkerIcon ?? BitmapDescriptor.defaultMarker,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: position.heading, // Atualiza a direção do marcador (farol)
          );

          // Remove o marcador antigo e adiciona o novo.
          _markers.removeWhere(
            (marker) => marker.markerId.value == 'currentLocation',
          );
          _markers.add(newMarker);

          setState(() {
            if (_routePoints.isNotEmpty) {
              // Calcula a distância desde o último ponto e atualiza o total.
              final lastPoint = _routePoints.last;
              final distance = Geolocator.distanceBetween(
                lastPoint.latitude,
                lastPoint.longitude,
                position.latitude,
                position.longitude,
              );
              
              // Atualiza a distância e as calorias.
              _totalDistanceInMeters += distance;
              // NOTA: A lógica de cálculo de calorias deve considerar o esporte
              // e o peso do usuário para ser mais precisa.
              _caloriesBurned = _totalDistanceInMeters / 16;
              
              // Cálculo e atualização do Ritmo
              final totalDistanceInKm = _totalDistanceInMeters / 1000;
              final totalTimeInSeconds = _stopwatch.elapsed.inSeconds;

              // Ritmo Médio (Pace Average)
              if (totalDistanceInKm > 0.05) { // Evita divisão por zero ou ritmo infinito no início
                final averagePaceSecondsPerKm = totalTimeInSeconds / totalDistanceInKm;
                
                final avgPaceMinutes = (averagePaceSecondsPerKm / 60).floor();
                final avgPaceSeconds = (averagePaceSecondsPerKm % 60).round();
                _averagePaceText =
                    '${avgPaceMinutes.toString().padLeft(2, '0')}:${avgPaceSeconds.toString().padLeft(2, '0')}';
              } else {
                _averagePaceText = '00:00';
              }

              // Ritmo Atual (Pace Current)
              final currentVelocityMps = position.speed; // Velocidade em m/s
              if (currentVelocityMps > 0.5) { // Se estiver se movendo
                  final paceSecondsPerMeter = 1 / currentVelocityMps;
                  final paceSecondsPerKm = paceSecondsPerMeter * 1000;
                  
                  final curPaceMinutes = (paceSecondsPerKm / 60).floor();
                  final curPaceSeconds = (paceSecondsPerKm % 60).round();
                  _currentPaceText =
                      '${curPaceMinutes.toString().padLeft(2, '0')}:${curPaceSeconds.toString().padLeft(2, '0')}';
              } else {
                  _currentPaceText = '00:00'; // Parado ou muito lento
              }
            }
            
            _routePoints.add(LatLng(position.latitude, position.longitude));

            // Adiciona a nova polilinha (ou atualiza a existente) ao mapa.
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: _routePoints,
                color: CustomColors.primary,
                width: 5,
              ),
            );

            // Anima a câmera do mapa para seguir o usuário.
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          });
        });
  }

  /// Verifica o status do serviço de localização (GPS) do dispositivo na inicialização.
  Future<void> _checkGpsStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _isGpsOn = serviceEnabled;
    });
  }

  /// Ouve continuamente as mudanças no status do serviço de GPS.
  void _listenToGpsStatusChanges() {
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      setState(() {
        _isGpsOn = status == ServiceStatus.enabled;
      });
    });
  }

  //================================================================================
  // Lógica de Controle do Mapa (Map Control Logic)
  //================================================================================

  /// Alterna a visibilidade do seletor de tipos de mapa.
  void _toggleMapOptions() {
    setState(() {
      _showMapOptions = !_showMapOptions;
      // Garante que o seletor de esporte está fechado
      _showSportSelector = false;
    });
  }

  /// Alterna a visualização do mapa entre 2D e 3D (alterando a inclinação da câmera).
  void _toggle3DView() {
    final newTilt = _currentCameraTilt == 0.0 ? 60.0 : 0.0;
    setState(() {
      _currentCameraTilt = newTilt;
    });
    _centerOnLocation(); // Re-centraliza com a nova inclinação
  }

  /// Centraliza o mapa na localização atual do usuário.
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

  /// Atualiza o tipo de mapa exibido com base na seleção do usuário.
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
      }
    });
  }

  //================================================================================
  // Lógica de Controle do Esporte (Sport Control Logic)
  //================================================================================

  /// NOVO: Alterna a visibilidade do seletor de esportes.
  void _toggleSportSelector() {
    setState(() {
      _showSportSelector = !_showSportSelector;
      // Garante que o seletor de mapa está fechado
      _showMapOptions = false;
    });
  }

  /// NOVO: Atualiza o esporte selecionado pelo usuário.
  void _updateSport(SportOption option) {
    setState(() {
      _selectedSport = option;
      _toggleSportSelector(); // Fecha o seletor após a seleção
      // Lógica futura para atualizar a interface (ícone, cores) com base no esporte
    });
  }

  /// NOVO: Mapeia o enum do esporte para uma string de rótulo.
  String _getSportLabel(SportOption option) {
    switch (option) {
      case SportOption.corrida:
        return 'Corrida';
      case SportOption.pedalada:
        return 'Pedalada';
      case SportOption.caminhada:
        return 'Caminhada';
    }
  }

  /// NOVO: Mapeia o enum do esporte para o caminho do ícone SVG.
  String _getSportIconPath(SportOption option) {
    switch (option) {
      case SportOption.corrida:
        return 'assets/images/icons/corrida.svg';
      case SportOption.pedalada:
        return 'assets/images/icons/bicicleta.svg'; // Ícone simulado
      case SportOption.caminhada:
        return 'assets/images/icons/caminhada.svg'; // Ícone simulado
    }
  }

  /// NOVO: Mapeia o enum do esporte para o ícone de marcação (usado no seletor)
  IconData _getSportCheckIcon(SportOption option) {
    switch (option) {
      case SportOption.corrida:
        return Icons.directions_run;
      case SportOption.pedalada:
        return Icons.directions_bike;
      case SportOption.caminhada:
        return Icons.directions_walk;
    }
  }

  //================================================================================
  // Método `build` e Widgets da UI
  //================================================================================
  @override
  /// Constrói a interface gráfica da tela.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.quaternary,
      body: Stack(
        children: [
          // Exibe um indicador de progresso enquanto a localização inicial não é obtida.
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  // Configurações e widgets do Google Map.
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
                  // Desativado para não mostrar o ponto azul nativo junto com o nosso customizado.
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
          // Borda branca decorativa ao redor do mapa.
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
          // Ícones superiores (Rotas e Configurações).
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
          // Botões de controle do mapa (Camadas, 3D, Centralizar) visíveis apenas antes de iniciar.
          if (_activityState == ActivityState.notStarted &&
              !_showSportSelector) // Esconde quando o seletor de esporte estiver aberto
            Positioned(
              bottom: 240, // Ajuste para subir os botões
              right: 20,
              child: Column(
                children: [
                  _buildMapControlButton(
                    icon: Icons.layers_outlined,
                    onPressed: () {
                      _toggleMapOptions();
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
          
          // NOVO: Widget de Estatísticas Detalhadas Redimensionável (Running/Paused)
          if (_activityState == ActivityState.running ||
              _activityState == ActivityState.paused)
            _ActivityStatsSheet(
              durationText: _durationText,
              distanceInKm: (_totalDistanceInMeters / 1000).toStringAsFixed(2),
              currentPace: _currentPaceText,
              onMusic: _toggleSpotifyPlayer,
              onSportSelect: _toggleSportSelector,
              averagePace: _averagePaceText,
              calories: _caloriesBurned.toStringAsFixed(0),
              activityState: _activityState,
              onPause: _onMainActionButtonPressed,
              onStop: _onStopButtonPressed,
              isPlayerVisible: _isPlayerVisible,
            ),
            
          // Botão de status do GPS (Mantido, mas movido para não colidir com o sheet)
          Positioned(
            bottom: (_activityState == ActivityState.notStarted || _activityState == ActivityState.finished) ? 200 : 80,
            left: 20,
            right: 20,
            child: Center(child: _buildGpsButton()),
          ),
          // Controles inferiores (Iniciar/Música/Esporte) - APENAS no estado NotStarted
          if (_activityState == ActivityState.notStarted || _activityState == ActivityState.finished)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
          
          // Player do Spotify, visível quando ativado.
          if (_isPlayerVisible) _buildSpotifyPlayer(),
          // Seletor de tipo de mapa, visível quando ativado.
          if (_showMapOptions) _buildMapOptionSelector(),
          // Seletor de esporte, visível quando ativado.
          if (_showSportSelector) _buildSportSelector(),
        ],
      ),
    );
  }

  //================================================================================
  // Widgets do Seletor de Mapa
  //================================================================================

  /// Constrói o painel inferior para selecionar o tipo de mapa.
  Widget _buildMapOptionSelector() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          // Permite fechar o painel arrastando para baixo.
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
              // "Handle" visual para indicar que o painel é arrastável.
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
              _buildMapOptionsRow(), // Mantém apenas a linha de tipos de mapa
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói a linha com as opções de tipo de mapa.
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

  /// Constrói um item individual de opção de mapa (ícone, rótulo).
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
        // ignore: sized_box_for_whitespace
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
                      // Aplica filtro de cor se estiver bloqueado
                      color: isLocked
                          ? Colors.white.withAlpha((255 * 0.5).round())
                          : null,
                      colorBlendMode: isLocked ? BlendMode.modulate : null,
                      // Placeholder para simular as cores da imagem
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF232530),
                          child: Center(
                            child: isLocked
                                ? const Icon(Icons.lock, color: Colors.white)
                                : const Icon(Icons.map, color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (isLocked)
                  const Positioned(
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

  //================================================================================
  // Widgets do Seletor de Esporte
  //================================================================================

  /// Constrói o painel inferior para selecionar o esporte (baseado na imagem).
  Widget _buildSportSelector() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          // Permite fechar o painel arrastando para baixo ou usando o 'x'
          if (details.primaryVelocity! > 0) {
            _toggleSportSelector();
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
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 40,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha do Título e Botão Fechar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Escolha um esporte',
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleSportSelector,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10, height: 1, thickness: 1),
              const SizedBox(height: 24),
              // Seus esportes principais
              Text(
                'Seus esportes principais',
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildMainSportsRow(),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói a linha dos esportes principais (Corrida, Pedalada, Caminhada).
  Widget _buildMainSportsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMainSportItem(
          iconPath: 'assets/images/icons/corrida.svg',
          label: 'Corrida',
          option: SportOption.corrida,
        ),
        _buildMainSportItem(
          iconPath: 'assets/images/icons/bicicleta.svg',
          label: 'Pedalada',
          option: SportOption.pedalada,
        ),
        _buildMainSportItem(
          iconPath: 'assets/images/icons/caminhada.svg',
          label: 'Caminhada',
          option: SportOption.caminhada,
        ),
      ],
    );
  }

  /// Constrói um item de esporte principal (círculo grande com ícone e texto).
  Widget _buildMainSportItem({
    required String iconPath,
    required String label,
    required SportOption option,
  }) {
    final isSelected = _selectedSport == option;

    return GestureDetector(
      onTap: () => _updateSport(option),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? CustomColors.primary.withAlpha((255 * 0.4).round())
                      : CustomColors.secondary,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: ColorFilter.mode(
                      isSelected ? CustomColors.primary : CustomColors.textDark,
                      BlendMode.srcIn,
                    ),
                    width: 35,
                    height: 35,
                    // Placeholder para simular ícones
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        _getSportCheckIcon(option),
                        color: isSelected
                            ? CustomColors.secondary
                            : CustomColors.textDark,
                        size: 35,
                      );
                    },
                  ),
                ),
              ),
              if (isSelected)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    color: CustomColors.primary,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.lexend(
              color: isSelected ? CustomColors.primary : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  //================================================================================
  // Outros Widgets da UI (Spotify, Controles, Stats)
  //================================================================================

  /// Constrói o widget do player do Spotify com efeito de vidro fosco.
  Widget _buildSpotifyPlayer() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  // Cor de fundo com gradiente sutil
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2E2F3A).withOpacity(0.8),
                      const Color(0xFF232530).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Linha com imagem, nome da música e artista
                    Row(
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
                            children: [
                              Text(
                                _trackName,
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _artistName,
                                style: GoogleFonts.lexend(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Barra de progresso da música
                    if (_trackDuration > 0)
                      LinearProgressIndicator(
                        value: _trackPosition / _trackDuration,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          CustomColors.primary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Controles de Play/Pause, Avançar, Voltar
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

  /// Retorna o conjunto de controles correto com base no estado atual da atividade.
  Widget _buildBottomControls() {
    switch (_activityState) {
      case ActivityState.running:
      case ActivityState.paused:
        // Controles Running/Paused agora estão dentro do _ActivityStatsSheet
        return const SizedBox.shrink(); 
      case ActivityState.notStarted:
      case ActivityState.finished:
        return _NotStartedControls(
          onStart: _onMainActionButtonPressed,
          onMusic: _toggleSpotifyPlayer,
          onSportSelect: _toggleSportSelector,
          selectedSport: _selectedSport,
          getSportLabel: _getSportLabel,
          getSportIconPath: _getSportIconPath,
          getSportCheckIcon: _getSportCheckIcon,
        );
    }
  }

  /// Constrói um ícone circular com sombra para os botões superiores.
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

  /// Constrói o botão que exibe o status do GPS e abre as configurações de localização ao ser tocado.
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

  /// Constrói um botão de controle de mapa genérico (circular, branco com sombra).
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
}

/// Widget que exibe os controles quando a atividade ainda não foi iniciada.
class _NotStartedControls extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onMusic;
  // Propriedades para seleção de esporte
  final VoidCallback onSportSelect;
  final SportOption selectedSport;
  final String Function(SportOption) getSportLabel;
  final String Function(SportOption) getSportIconPath;
  final IconData Function(SportOption) getSportCheckIcon;

  const _NotStartedControls({
    required this.onStart,
    required this.onMusic,
    required this.onSportSelect,
    required this.selectedSport,
    required this.getSportLabel,
    required this.getSportIconPath,
    required this.getSportCheckIcon,
  });

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
        // Usa a função de seleção de esporte e o esporte atual
        _buildIconWithLabel(
          icon: getSportIconPath(selectedSport),
          label: getSportLabel(selectedSport),
          iconSize: 35,
          onTap: onSportSelect, // Chama o seletor de esporte
        ),
      ],
    );
  }

  /// Constrói um botão de ação circular (ex: botão de música).
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

  /// Constrói o botão grande "COMEÇAR".
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

  /// Constrói o ícone com rótulo para selecionar o tipo de atividade (ex: Corrida).
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
              // O botão lateral agora usa a cor primária (CustomColors.primary)
              // com opacidade, assim como o ícone central, se estiver ativo.
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
                  CustomColors.textDark, // Cor do ícone pequeno
                  BlendMode.srcIn,
                ),
                width: iconSize,
                // Placeholder para simular ícones
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    // Fallback para ícone de corrida, mas usa o ícone check do esporte.
                    getSportCheckIcon(selectedSport),
                    color: CustomColors.textDark,
                    size: iconSize,
                  );
                },
              ),
            ),
          ),
          // Checkmark de seleção (baseado na imagem)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CustomColors.tertiary,
              ),
              child: Icon(
                Icons.check, // Altera para sempre usar o ícone de check
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

/// Widget que exibe os controles enquanto a atividade está em andamento.
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

  /// Constrói o botão grande de "Pausar".
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

/// Widget que exibe os controles quando a atividade está pausada.
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

  /// Constrói o botão "RETOMAR".
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

  /// Constrói o botão "CONCLUIR".
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

/// Widget que gerencia o DraggableScrollableSheet com as estatísticas detalhadas
/// e os controles da atividade (Running/Paused).
class _ActivityStatsSheet extends StatelessWidget {
  final String durationText;
  final String distanceInKm;
  final String currentPace;
  final String averagePace;
  final String calories;
  final ActivityState activityState;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final VoidCallback onMusic;
  final VoidCallback onSportSelect;
  final bool isPlayerVisible;

  const _ActivityStatsSheet({
    required this.durationText,
    required this.distanceInKm,
    required this.currentPace,
    required this.averagePace,
    required this.calories,
    required this.activityState,
    required this.onPause,
    required this.onStop,
    required this.onMusic,
    required this.onSportSelect,
    required this.isPlayerVisible,
  });

  @override
  Widget build(BuildContext context) {
    // Controlador para acessar o estado do sheet.
    final DraggableScrollableController sheetController = DraggableScrollableController();

    // Define a altura mínima (minimizado) e máxima (tela cheia)
    // 0.85 para tela cheia (como na primeira imagem)
    // 0.2 para minimizado (como na segunda imagem)
    const double minHeight = 0.2; 
    const double maxHeight = 0.85;

    // O DraggableScrollableSheet gerencia o redimensionamento por arraste.
    return DraggableScrollableSheet(
      initialChildSize: maxHeight, // Começa em tela cheia ao iniciar a corrida.
      minChildSize: minHeight,
      maxChildSize: maxHeight,
      controller: sheetController,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF232530),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            // Usa o scrollController do DraggableScrollableSheet para gerenciar o arraste
            controller: scrollController,
            child: Column(
              children: [
                // === Handle de Arraste/Minimizar ===
                GestureDetector(
                  onTap: () {
                    // Implementa a função de clique: alterna entre minimizado e expandido
                    if (sheetController.size > minHeight + 0.05) { // Se estiver perto do máximo
                      sheetController.animateTo(
                        minHeight,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else { // Se estiver perto do mínimo
                      sheetController.animateTo(
                        maxHeight,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // === Estatísticas Detalhadas ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Linha da Duração (Tempo) com o ícone de Minimizar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainStat(
                            'DURAÇÃO',
                            durationText,
                            ' ',
                            large: true,
                            alignment: CrossAxisAlignment.start,
                          ),
                          // Ícone de Minimizar/Maximizar
                          GestureDetector(
                            onTap: () {
                                // Alterna o tamanho do sheet ao clicar
                                if (sheetController.size > minHeight + 0.05) {
                                    sheetController.animateTo(
                                      minHeight,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                } else {
                                    sheetController.animateTo(
                                      maxHeight,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Linha da Distância (Km)
                      _buildMainStat(
                        'DISTÂNCIA',
                        distanceInKm,
                        'km',
                        large: true,
                        alignment: CrossAxisAlignment.start,
                      ),
                      const SizedBox(height: 40),
                      
                      // Linha de Ritmos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMainStat(
                            'RITMO ATUAL',
                            currentPace,
                            '/km',
                            large: false,
                            alignment: CrossAxisAlignment.start,
                          ),
                          _buildMainStat(
                            'RITMO MÉDIO',
                            averagePace,
                            '/km',
                            large: false,
                            alignment: CrossAxisAlignment.end,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      // Linha de Calorias
                      _buildCalorieStat(calories),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // === Controles (Pause/Stop/Retomar) ===
                activityState == ActivityState.running
                    ? _RunningControls(onPressed: onPause)
                    : _PausedControls(onResume: onPause, onStop: onStop),
                
                const SizedBox(height: 20),
                
                // Botões de Música e Esporte (na tela minimizada - Pausado)
                if (activityState == ActivityState.paused)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     _buildSmallActionButton(
                      Icons.music_note_outlined,
                      CustomColors.tertiary,
                      onTap: onMusic,
                      // Destaca se o player estiver visível
                      isHighlighted: isPlayerVisible, 
                    ),
                    const SizedBox(width: 15),
                    _buildSmallActionButton(
                      Icons.directions_run, // Placeholder para o seletor de esporte
                      CustomColors.tertiary,
                      onTap: onSportSelect,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Constrói o layout de estatística principal (Ritmo, Duração, Distância)
  Widget _buildMainStat(
    String label,
    String value,
    String unit, {
    required bool large,
    CrossAxisAlignment alignment = CrossAxisAlignment.center,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            color: Colors.white.withOpacity(0.5),
            fontSize: large ? 16 : 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.lexend(
              fontSize: large ? 60 : 40,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.lexend(
                  color: CustomColors.primary,
                  fontSize: large ? 24 : 18,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói o layout de estatística de calorias
  Widget _buildCalorieStat(String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          const Divider(color: Colors.white12, thickness: 1),
          const SizedBox(height: 16),
          Text(
            'CALORIAS QUEIMADAS',
            style: GoogleFonts.lexend(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.lexend(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: ' kcal',
                  style: GoogleFonts.lexend(
                    color: CustomColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um botão de ação circular pequeno (usado no estado Pausado)
  Widget _buildSmallActionButton(IconData icon, Color color, {VoidCallback? onTap, bool isHighlighted = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHighlighted ? CustomColors.primary : CustomColors.secondary,
          boxShadow: [
            BoxShadow(
              color: isHighlighted ? CustomColors.primary.withAlpha(100) : Colors.black.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: isHighlighted ? CustomColors.tertiary : color, size: 30),
      ),
    );
  }
}