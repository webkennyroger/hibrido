import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modelo de dados para armazenar as informações de uma atividade concluída.
@immutable
class ActivityData {
  final String userName;
  final String activityTitle;
  final String runTime;
  final String location;
  final double distanceInMeters;
  final Duration duration;
  final List<LatLng> routePoints;
  final double calories;
  final int likes;
  final int comments;
  final int shares;

  const ActivityData({
    required this.userName,
    required this.activityTitle,
    required this.runTime,
    required this.location,
    required this.distanceInMeters,
    required this.duration,
    required this.routePoints,
    required this.calories,
    required this.likes,
    required this.comments,
    required this.shares,
  });
}
