// main_screen.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
// Certifique-se de que o caminho para o seu arquivo de cores está correto
import 'package:hibrido/core/theme/custom_colors.dart';
// Certifique-se de que os caminhos para os arquivos de dados e tela estão corretos
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/map/screens/finished_confirmation_sheet.dart'; // Assuming this is correct
import 'package:hibrido/features/map/screens/sport_selection_button.dart'; // Corrected import path
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
  ImageProvider _trackImage = const AssetImage(
    'assets/images/spotify_placeholder.png',
  );
  // Duração total e posição atual da música para a barra de progresso.
  int _trackDuration = 0;
  int _trackPosition = 0;
  // Posição do player de música na tela (para arrastar).
  Offset _playerOffset = const Offset(16, 450);

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
    _listenToSpotifyPlayerState(); // Garante que o app ouça o Spotify desde o início
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
    final Paint farolHaloPaint = Paint()
      ..color = Colors.white.withOpacity(0.2); // Halo branco translúcido
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
    canvas.drawCircle(const Offset(center, center), size / 2 - 5, shadowPaint);

    // Desenha a borda branca (círculo maior)
    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(center, center), size / 3, whitePaint);

    // Desenha o círculo azul interno
    final Paint bluePaint = Paint()..color = Colors.blue.shade700;
    canvas.drawCircle(const Offset(center, center), blueRadius, bluePaint);

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
      if (mounted) {
        await Geolocator.openAppSettings();
      }
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
    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (sheetContext) => FinishedConfirmationSheet(
          activityData: tempActivityData,
          onSaveAndNavigate: (newTitle) async {
            final finalActivityData = tempActivityData.copyWith(
              activityTitle: newTitle,
            );

            await _saveActivity(finalActivityData);

            // Usa o contexto do sheet para fechar a si mesmo
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop(true);
            }
          },
          onDiscard: () {
            // Usa o contexto do sheet para fechar a si mesmo
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            _resetActivityState();
          },
        ),
      ),
    );

    // 4. Se o resultado do Navigator.push for 'true' (atividade salva), fecha a MapScreen.
    if (mounted && (result as bool? ?? false)) {
      Navigator.of(context).pop(true);
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
            rotation:
                position.heading, // Atualiza a direção do marcador (farol)
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
              if (totalDistanceInKm > 0.05) {
                // Evita divisão por zero ou ritmo infinito no início
                final averagePaceSecondsPerKm =
                    totalTimeInSeconds / totalDistanceInKm;

                final avgPaceMinutes = (averagePaceSecondsPerKm / 60).floor();
                final avgPaceSeconds = (averagePaceSecondsPerKm % 60).round();
                _averagePaceText =
                    '${avgPaceMinutes.toString().padLeft(2, '0')}:${avgPaceSeconds.toString().padLeft(2, '0')}';
              } else {
                _averagePaceText = '00:00';
              }

              // Ritmo Atual (Pace Current)
              final currentVelocityMps = position.speed; // Velocidade em m/s
              if (currentVelocityMps > 0.5) {
                // Se estiver se movendo
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

  /// Abre a câmera para tirar uma foto.
  Future<void> _openCamera() async {
    final ImagePicker picker = ImagePicker();
    // Captura uma imagem usando a câmera.
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // A imagem foi capturada com sucesso.
      // Você pode adicionar lógica aqui para salvar o caminho da imagem
      // ou exibi-la em algum lugar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto capturada: ${image.path}')),
        );
      }
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
              selectedSport: _selectedSport,
              getSportLabel: _getSportLabel,
              getSportIconPath: _getSportIconPath,
              getSportCheckIcon: _getSportCheckIcon,
              onCamera: _openCamera,
            ),

          // Botão de status do GPS, visível apenas antes de iniciar ou após finalizar.
          if (_activityState == ActivityState.notStarted ||
              _activityState == ActivityState.finished)
            Positioned(
              bottom: 200,
              left: 20,
              right: 20,
              child: Center(child: _buildGpsButton()),
            ),
          // Controles inferiores (Iniciar/Música/Esporte) - APENAS no estado NotStarted
          if (_activityState == ActivityState.notStarted ||
              _activityState == ActivityState.finished)
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
      child: SizedBox(
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
        // Itera sobre todas as opções de esporte e cria um botão para cada uma
        for (var sport in SportOption.values)
          SportSelectionButton(
            iconPath: _getSportIconPath(sport),
            label: _getSportLabel(sport),
            option: sport,
            selectedSport: _selectedSport,
            onTap: () => _updateSport(sport),
            fallbackIcon: _getSportCheckIcon(sport),
            isLarge: true, // Define o tamanho grande com texto
          ),
      ],
    );
  }

  //================================================================================
  // Outros Widgets da UI (Spotify, Controles, Stats)
  //================================================================================

  /// Constrói o widget do player do Spotify com efeito de vidro fosco.
  Widget _buildSpotifyPlayer() {
    // O player agora é um widget flutuante e arrastável.
    return Positioned(
      left: _playerOffset.dx,
      top: _playerOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _playerOffset += details.delta;
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: MediaQuery.of(context).size.width - 32, // Largura fixa
              decoration: BoxDecoration(
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
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Linha com imagem, nome da música e artista
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                                Column(
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
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Barra de progresso da música
                        if (_trackDuration > 0)
                          LinearProgressIndicator(
                            value: _trackDuration > 0
                                ? _trackPosition / _trackDuration
                                : 0.0,
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
                  // Botões de controle do player (Minimizar e Fechar)
                  _buildPlayerControls(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói os botões de Minimizar e Fechar para o player de música.
  Widget _buildPlayerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botão para MINIMIZAR (esconde o player, mas não para a música)
        IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: CustomColors.primary,
            size: 28,
          ),
          onPressed: () => setState(() => _isPlayerVisible = false),
        ),
        // Botão para FECHAR (esconde o player e para a música)
        IconButton(
          icon: const Icon(Icons.close, color: CustomColors.primary, size: 24),
          onPressed: () {
            _spotifyService.pause();
            setState(() => _isPlayerVisible = false);
          },
        ),
      ],
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
          color: CustomColors.tertiary, // Fundo preto
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
              color: _isGpsOn ? CustomColors.primary : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 5),
            Text(
              _isGpsOn ? 'GPS - ON' : 'GPS - OFF',
              style: GoogleFonts.lexend(
                color: CustomColors.textLight, // Texto branco
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
  final SportOption selectedSport; // O esporte atualmente selecionado
  final String Function(SportOption)
  getSportLabel; // Função para obter o rótulo
  final String Function(SportOption)
  getSportIconPath; // Função para obter o caminho do ícone
  final IconData Function(SportOption)
  getSportCheckIcon; // Função para obter o ícone de fallback
  final VoidCallback onSportSelect; // Callback para quando o botão é tocado

  const _NotStartedControls({
    required this.onStart,
    required this.onMusic,
    required this.selectedSport,
    required this.getSportLabel,
    required this.getSportIconPath,
    required this.getSportCheckIcon,
    required this.onSportSelect,
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
        SportSelectionButton(
          iconPath: getSportIconPath(selectedSport),
          label: getSportLabel(selectedSport),
          option: selectedSport,
          selectedSport: selectedSport,
          onTap: onSportSelect,
          fallbackIcon: getSportCheckIcon(selectedSport),
          useDarkMode: true, // Ativa o novo estilo preto
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
}

/// Constrói um botão de ação para os controles de Pausa (Retomar/Concluir).
Widget _buildActionButton(
  IconData icon,
  Color color, {
  VoidCallback? onTap,
  bool isPrimary = false,
  Color? backgroundColor,
  String? text,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: text != null ? null : 70, // Largura automática se tiver texto
      height: 70, // Altura consistente
      padding: text != null
          ? const EdgeInsets.symmetric(
              horizontal: 16,
            ) // Padding horizontal reduzido
          : null,
      decoration: BoxDecoration(
        shape: text != null ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: text != null ? BorderRadius.circular(35) : null,
        color:
            backgroundColor ??
            (isPrimary ? CustomColors.primary : CustomColors.secondary),
        boxShadow: [
          BoxShadow(
            color:
                (backgroundColor ??
                        (isPrimary ? CustomColors.primary : Colors.black))
                    .withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: text != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.lexend(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 35),
                if (text != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: GoogleFonts.lexend(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
    ),
  );
}

/// Constrói um botão de ação circular pequeno (usado no estado Pausado)
Widget _buildSmallActionButton(
  IconData icon,
  Color color, {
  VoidCallback? onTap,
  bool isHighlighted = false,
}) {
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
            color: isHighlighted
                ? CustomColors.primary.withAlpha(100)
                : Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: isHighlighted ? CustomColors.tertiary : color,
        size: 30,
      ),
    ),
  );
}

/// Constrói um botão de ação que é apenas um ícone clicável, sem fundo.
Widget _buildIconOnlyButton(IconData icon, Color color, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Icon(icon, color: color, size: 30),
  );
}

/// Widget que exibe os controles quando a atividade está pausada.
class _PausedControls extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onStop;
  final bool showText;

  const _PausedControls({
    required this.onResume,
    required this.onStop,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          Icons.play_arrow,
          CustomColors.tertiary,
          onTap: onResume,
          isPrimary: true,
          text: showText ? 'RETORNAR' : null,
        ),
        const SizedBox(width: 15),
        _buildActionButton(
          Icons.stop,
          Colors.white,
          onTap: onStop,
          backgroundColor: CustomColors.quinary,
          text: showText ? 'CONCLUIR' : null,
        ),
      ],
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
  final SportOption selectedSport; // Passa o SportOption completo
  final String Function(SportOption) getSportLabel; // Funções para obter dados
  final String Function(SportOption) getSportIconPath;
  final IconData Function(SportOption) getSportCheckIcon;

  final VoidCallback onCamera;
  const _ActivityStatsSheet({
    required this.durationText,
    required this.distanceInKm,
    required this.currentPace,
    required this.averagePace,
    required this.calories,
    required this.activityState,
    required this.onPause,
    required this.onStop,
    required this.onSportSelect,
    required this.isPlayerVisible,
    required this.selectedSport,
    required this.getSportLabel,
    required this.getSportIconPath,
    required this.getSportCheckIcon,
    required this.onMusic, // Mantém onMusic
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    // Controlador para acessar o estado do sheet.
    final DraggableScrollableController sheetController =
        DraggableScrollableController();

    // Define a altura mínima (minimizado) e máxima (tela cheia)
    // 0.85 para tela cheia (como na primeira imagem)
    // 0.2 para minimizado (como na segunda imagem)
    const double minHeight = 0.32; // Aumentado para evitar cobrir os botões
    const double maxHeight = 0.85;

    // O DraggableScrollableSheet gerencia o redimensionamento por arraste.
    return DraggableScrollableSheet(
      initialChildSize: maxHeight, // Começa em tela cheia ao iniciar a corrida.
      minChildSize: minHeight,
      maxChildSize: maxHeight,
      controller: sheetController,
      builder: (context, scrollController) {
        // Usa um LayoutBuilder para saber o tamanho atual do sheet
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Verifica se o sheet está minimizado (altura próxima ao minChildSize)
            final bool isMinimized =
                constraints.maxHeight <
                MediaQuery.of(context).size.height * (minHeight + 0.1);

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF232530),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              // Se estiver minimizado, mostra o layout de resumo.
              // Caso contrário, mostra o layout detalhado.
              child: isMinimized
                  ? _buildMinimizedLayout(
                      context,
                      sheetController,
                      scrollController,
                    )
                  : _buildExpandedLayout(
                      context,
                      scrollController,
                      sheetController,
                    ),
            );
          },
        );
      },
    );
  }

  /// Constrói o layout RESUMIDO para quando o painel está minimizado.
  Widget _buildMinimizedLayout(
    BuildContext context,
    DraggableScrollableController sheetController,
    ScrollController scrollController,
  ) {
    const double maxHeight = 0.85;
    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Handle de arraste com função de clique
            GestureDetector(
              onTap: () => sheetController.animateTo(
                maxHeight,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: CustomColors.primary.withOpacity(0.5),
                  size: 32,
                ),
              ),
            ),
            // Linha de estatísticas resumidas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatColumn('DURAÇÃO', durationText, fontSize: 26),
                _buildStatColumn(
                  'DISTÂNCIA',
                  distanceInKm,
                  unit: '',
                  fontSize: 40,
                ),
                _buildStatColumn('RITMO', averagePace, unit: '', fontSize: 26),
              ],
            ),
            const SizedBox(height: 24),
            _buildActionControls(context),
          ],
        ),
      ),
    );
  }

  /// Constrói o layout DETALHADO para quando o painel está expandido.
  Widget _buildExpandedLayout(
    BuildContext context,
    ScrollController scrollController,
    DraggableScrollableController sheetController,
  ) {
    const double minHeight = 0.2;
    const double maxHeight = 0.85;

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          // Handle de Arraste/Minimizar
          GestureDetector(
            onTap: () {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: CustomColors.primary.withOpacity(0.5),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Estatísticas Detalhadas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                _buildMainStat(
                  'DURAÇÃO',
                  durationText,
                  ' ',
                  fontSize: 40,
                  alignment: CrossAxisAlignment.center,
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white12, thickness: 1),
                const SizedBox(height: 24),
                _buildMainStat(
                  'DISTÂNCIA',
                  distanceInKm,
                  'km',
                  fontSize: 80,
                  alignment: CrossAxisAlignment.center,
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white12, thickness: 1),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMainStat(
                        'RITMO ATUAL',
                        currentPace,
                        '/km',
                        fontSize: 40,
                        alignment: CrossAxisAlignment.start,
                      ),
                    ),
                    const SizedBox(
                      height: 80,
                      child: VerticalDivider(
                        color: Colors.white12,
                        thickness: 1,
                      ),
                    ),
                    Expanded(
                      child: _buildMainStat(
                        'RITMO MÉDIO',
                        averagePace,
                        '/km',
                        fontSize: 40,
                        alignment: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
                _buildCalorieStat(calories),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Controles (Pause/Stop/Retomar)
          activityState == ActivityState.running
              ? _buildPauseButton()
              // Layout expandido mostra o texto
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                  ), // Padding reduzido
                  child: _PausedControls(
                    onResume: onPause,
                    onStop: onStop,
                    showText: true,
                  ),
                ),
          const SizedBox(height: 20),

          // Botões de Música e Esporte (no estado Pausado)
          if (activityState == ActivityState.paused)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSmallActionButton(
                  Icons.music_note_outlined,
                  CustomColors.tertiary,
                  onTap: onMusic,
                  isHighlighted: isPlayerVisible,
                ),
                const SizedBox(width: 15),
                SportSelectionButton(
                  iconPath: getSportIconPath(selectedSport),
                  label: getSportLabel(selectedSport),
                  option: selectedSport,
                  selectedSport: selectedSport,
                  onTap: onSportSelect,
                  fallbackIcon: getSportCheckIcon(selectedSport),
                  isLarge: false,
                ),
              ],
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Constrói a linha de controles de ação (Câmera, Ação Principal, Configurações).
  Widget _buildActionControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botão Câmera
          _buildIconOnlyButton(
            Icons.camera_alt_outlined,
            CustomColors.primary,
            onTap: onCamera,
          ),
          // Ação Principal (Pausar ou Retomar/Concluir)
          if (activityState == ActivityState.running)
            _buildPauseButton(isSmall: true) // Usa a versão pequena do botão
          else
            // Layout minimizado não mostra texto
            SizedBox(
              width: 155, // Largura para conter os dois botões
              child: _PausedControls(
                onResume: onPause,
                onStop: onStop,
                showText: false,
              ),
            ),
          // Botão Configurações
          _buildIconOnlyButton(
            Icons.settings_outlined,
            CustomColors.primary,
            onTap: () => _showSettingsModal(context),
          ),
        ],
      ),
    );
  }

  /// Mostra o modal de configurações da atividade.
  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF232530),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingsOption(
                context,
                'Mostrar calorias',
                true,
                (value) {},
              ),
              _buildSettingsOption(context, 'Modo padrão', true, (value) {}),
              _buildSettingsOption(context, 'Modo satélite', false, (value) {}),
              _buildSettingsOption(context, 'Modo híbrido', false, (value) {}),
              _buildSettingsOption(context, 'Modo noturno', false, (value) {}),
              _buildSettingsOption(
                context,
                'Dados por áudio',
                false,
                (value) {},
              ),
            ],
          ),
        );
      },
    );
  }

  /// Constrói uma opção com checkbox para o modal de configurações.
  Widget _buildSettingsOption(
    BuildContext context,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      activeColor: CustomColors.primary,
      checkColor: CustomColors.tertiary,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  /// Constrói o botão grande de "Pausar".
  Widget _buildPauseButton({bool isSmall = false}) {
    final double size = isSmall ? 70 : 110;
    final double iconSize = isSmall ? 35 : 50;
    return GestureDetector(
      onTap: onPause,
      child: Container(
        width: size,
        height: size,
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
          child: Icon(
            Icons.pause,
            color: CustomColors.tertiary,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  /// Constrói o layout de estatística principal (Ritmo, Duração, Distância)
  Widget _buildMainStat(
    String label,
    String value,
    String unit, {
    required double fontSize,
    CrossAxisAlignment alignment = CrossAxisAlignment.center,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.lexend(
              fontSize: fontSize,
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
                  fontSize: fontSize * 0.4, // Unidade proporcional ao valor
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

  /// Constrói uma coluna de estatística para o layout minimizado.
  Widget _buildStatColumn(
    String label,
    String value, {
    String unit = '',
    required double fontSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.lexend(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: value),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.lexend(
                    color: CustomColors.primary,
                    fontSize: 14,
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
}
