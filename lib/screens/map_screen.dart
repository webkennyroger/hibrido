import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/custom_colors.dart';
import 'home_screen.dart';
import 'activity_screen.dart';
import 'workout_screen.dart';
import 'profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Obtém a localização atual do usuário.
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está habilitado.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // O serviço de localização está desabilitado.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // As permissões foram negadas.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // As permissões foram negadas permanentemente.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
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
                        builder: (context) => ProfileScreen(
                          onBack: () => Navigator.of(context).pop(),
                        ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Botão de música.
                _buildActionButton(
                  Icons.music_note_outlined,
                  CustomColors.tertiary,
                ),
                // Botão "START".
                _buildStartButton(),
                // Botão de alvo/objetivo.
                _buildActionButton(
                  Icons.track_changes_outlined,
                  CustomColors.tertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        color: CustomColors.quinary,
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

  // Constrói o botão "START".
  Widget _buildStartButton() {
    return Container(
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
    );
  }
}
