import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hibrido/models/activity_data.dart';
import '../theme/custom_colors.dart';
import 'activity_card.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dados de exemplo para o feed. No futuro, isso viria de um banco de dados.
    final List<ActivityData> mockActivities = [
      ActivityData(
        userName: 'Kenny',
        activityTitle: 'Corrida no Parque Ibirapuera',
        runTime: 'Manhã de Domingo',
        location: 'São Paulo, SP',
        distanceInMeters: 5240,
        duration: const Duration(minutes: 28, seconds: 15),
        routePoints: const [
          LatLng(-23.5874, -46.6576),
          LatLng(-23.5891, -46.6582),
          LatLng(-23.5884, -46.6623),
          LatLng(-23.5852, -46.6612),
        ],
        calories: 350,
        likes: 128,
        comments: 12,
        shares: 5,
      ),
      ActivityData(
        userName: 'Kenny',
        activityTitle: 'Pedal na Av. Paulista',
        runTime: 'Tarde de Sábado',
        location: 'São Paulo, SP',
        distanceInMeters: 10100,
        duration: const Duration(minutes: 45, seconds: 30),
        routePoints: const [
          LatLng(-23.5613, -46.6565),
          LatLng(-23.5573, -46.6623),
          LatLng(-23.5613, -46.6565),
        ],
        calories: 510,
        likes: 256,
        comments: 23,
        shares: 11,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Atividades',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: CustomColors.textLight,
          ),
        ),
      ),
      // A tela agora é uma lista de widgets ActivityScreen.
      body: ListView.separated(
        itemCount: mockActivities.length,
        itemBuilder: (context, index) {
          // Para cada item na lista de dados, criamos um widget de card.
          return ActivityCard(activityData: mockActivities[index]);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 8),
      ),
    );
  }
}
