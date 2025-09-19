import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modelo de dados para representar uma atividade.
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

  ActivityData({
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