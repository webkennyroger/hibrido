import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hibrido/models/activity_data.dart';
import '../theme/custom_colors.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../widgets/activity_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// Enum para controlar o estado da atividade de forma clara.
enum ActivityState { notStarted, running, paused, finished }

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isGpsOn = false;
  final Set<Polyline> _polylines = {};

  // A variável de estado principal que controla a UI dos botões.
  ActivityState _activityState = ActivityState.notStarted;

  // Variáveis para rastreamento da atividade
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _durationText = '00:00';
  double _totalDistanceInMeters = 0.0;
  double _caloriesBurned = 0.0;
  final List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
    _listenToGpsStatusChanges();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    // Limpa os recursos para evitar vazamento de memória.
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Verifica o status inicial do serviço de GPS.
  Future<void> _checkGpsStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _isGpsOn = serviceEnabled;
    });
  }

  // Ouve mudanças no status do serviço de GPS.
  void _listenToGpsStatusChanges() {
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      setState(() {
        _isGpsOn = status == ServiceStatus.enabled;
      });
    });
  }

  // Obtém a localização atual do usuário.
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está habilitado.
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
      // As permissões foram negadas permanentemente. O usuário precisa ir para as configurações.
      await Geolocator.openAppSettings();
      return;
    }

    // Quando as permissões são concedidas, obtemos a localização.
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      // Adiciona um marcador na localização atual.
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Sua Localização'),
        ),
      );
    });

    // Move a câmera do mapa para a localização atual.
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  // Gerencia o clique no botão principal de ação (Começar, Pausar, Retomar).
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
          // Inicia ou retoma a atividade
          _activityState = ActivityState.running;
          _stopwatch.start();
          _startTimer();
          _startTrackingLocation(resume: true);
          break;
        case ActivityState.running:
          // Pausa a atividade
          _activityState = ActivityState.paused;
          _stopwatch.stop();
          _timer?.cancel();
          _positionStreamSubscription?.pause();
          break;
        case ActivityState.finished:
          // Não faz nada se já finalizou
          break;
      }
    });
  }

  // Finaliza a atividade e reseta os valores.
  void _onStopButtonPressed() {
    setState(() {
      _stopwatch.stop();
      _timer?.cancel();
      _positionStreamSubscription?.cancel();
      _activityState = ActivityState.finished;

      // Cria o objeto com os dados da atividade concluída.
      final activityDuration = _stopwatch.elapsed;
      final activityData = ActivityData(
        userName: 'Kenny', // Exemplo, pode vir de um serviço de usuário
        activityTitle: 'Corrida', // Exemplo
        runTime: 'Manhã de Quarta-feira', // Exemplo
        location: 'São Paulo, SP', // Exemplo, pode usar geocoding
        distanceInMeters: _totalDistanceInMeters,
        duration: _stopwatch.elapsed,
        routePoints: List.from(_routePoints), // Cria uma cópia da lista
        calories: _caloriesBurned,
        likes: 0, // Inicia com 0
        comments: 0, // Inicia com 0
        shares: 0, // Inicia com 0
      );

      // Navega para a tela de resumo e, DEPOIS que ela for fechada, reseta o estado.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ActivityDetailScreen(activityData: activityData),
        ),
      ).then((_) {
        // Este código executa quando o usuário volta da tela de resumo.
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

  // Inicia o cronômetro para atualizar a UI.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _durationText =
            '${_stopwatch.elapsed.inMinutes.toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  // Inicia o rastreamento da localização para calcular a distância.
  void _startTrackingLocation({bool resume = false}) {
    if (_positionStreamSubscription != null) {
      if (resume) {
        _positionStreamSubscription?.resume();
      }
      return; // Já está ouvindo, não precisa criar outro stream.
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Atualiza a cada 10 metros.
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
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
              // Fórmula simples para calorias: 1 kcal a cada 16 metros (aproximado)
              _caloriesBurned = _totalDistanceInMeters / 16;
            }
            _routePoints.add(LatLng(position.latitude, position.longitude));

            // Atualiza a linha (Polyline) no mapa com a nova rota.
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: _routePoints,
                color: CustomColors.primary,
                width: 5,
              ),
            );

            // Move a câmera para a nova posição
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.quaternary,
      body: Stack(
        children: [
          // Widget do Google Maps que substitui a imagem estática.
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
                  polylines: _polylines, // Adiciona as polylines ao mapa
                  myLocationEnabled: true, // Mostra o ponto azul da localização
                  myLocationButtonEnabled: true, // Botão para centralizar
                  zoomControlsEnabled: false,
                ),
          // Borda branca arredondada que enquadra o mapa.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 8),
              ),
            ),
          ),
          // Barra de navegação do topo com ícones de perfil e configurações.
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ícone de perfil no topo.
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
                // Ícone de configurações no topo.
                _buildTopIcon(
                  child: const Icon(
                    Icons.settings,
                    color: CustomColors.textDark,
                  ),
                  onTap: () {
                    // Ação do botão de configurações
                  },
                ),
              ],
            ),
          ),
          // Cards de estatísticas (Distância, Duração, Calorias).
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

          // Botão de GPS ON/OFF
          Positioned(
            bottom: 200, // Ajustado para ficar acima do botão 'COMEÇAR'
            left: 20,
            right: 20,
            child: Center(child: _buildGpsButton()),
          ),
          // Círculo central com o ícone do tênis.
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
                          color: Colors.white,
                        ),
                        child: SvgPicture.asset(
                          'assets/images/sapato.svg',
                          colorFilter: const ColorFilter.mode(
                            CustomColors.tertiary,
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
          // Botões de controle na parte inferior da tela.
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  // Constrói os botões de controle inferiores com base no estado da atividade.
  Widget _buildBottomControls() {
    switch (_activityState) {
      case ActivityState.running:
        // Mostra apenas o botão de PAUSE no centro.
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildPauseButton()],
        );
      case ActivityState.paused:
        // Mostra os botões STOP e PLAY.
        return Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Inverte a posição dos botões
          children: [
            _buildPlayButton(), // Botão "RETOMAR"
            _buildStopButton(),
          ], // Botão "CONCLUIR"
        );
      case ActivityState.notStarted:
      case ActivityState.finished:
      default:
        // Estado inicial com os 3 botões.
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildActionButton(
              Icons.music_note_outlined,
              CustomColors.tertiary,
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

  // Constrói um ícone no topo da tela (perfil ou configurações).
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

  // Constrói um botão de ação circular.
  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
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
    );
  }

  // Constrói um card de estatística.
  Widget _buildStatsCard(String value, String unit, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: 110, // Largura fixa para melhor alinhamento
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco para o card
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
          // RichText para combinar textos com estilos diferentes
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
                ), // Número em preto
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: CustomColors.secondary,
                    fontSize: 12, // Tamanho menor para a unidade
                    fontWeight: FontWeight.w500, // Peso normal para a unidade
                  ),
                ), // Unidade em cinza
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.lexend(
              color: CustomColors.secondary, // Rótulo em cinza
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Constrói o botão de status do GPS.
  Widget _buildGpsButton() {
    return GestureDetector(
      onTap: () async {
        // Abre as configurações de localização do dispositivo para o usuário
        // poder ligar ou desligar o GPS.
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

  // Constrói o botão "START".
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

  // Constrói o botão "PAUSE".
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

  // Constrói o botão "PLAY" (Retomar).
  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _onMainActionButtonPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Bordas arredondadas
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

  // Constrói o botão "CONCLUIR" (Finalizar).
  Widget _buildStopButton() {
    return GestureDetector(
      onTap: _onStopButtonPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Bordas arredondadas
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
