import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modelo de dados para representar uma atividade.
class ActivityData {
  final String id; // ID único para cada atividade
  final String userName;
  final String activityTitle;
  final String runTime;
  final String location;
  final double distanceInMeters;
  final Duration duration;
  final List<LatLng> routePoints;
  final double calories;
  int likes;
  bool isLiked; // Estado de curtida do usuário local
  List<String> commentsList;
  final int shares;

  ActivityData({
    required this.id,
    required this.userName,
    required this.activityTitle,
    required this.runTime,
    required this.location,
    required this.distanceInMeters,
    required this.duration,
    required this.routePoints,
    required this.calories,
    required this.likes,
    this.isLiked = false,
    List<String>? commentsList,
    required this.shares,
  }) : commentsList = commentsList ?? [];

  // Método para criar uma cópia do objeto com alguns valores alterados.
  ActivityData copyWith({
    String? id,
    int? likes,
    bool? isLiked,
    List<String>? commentsList,
  }) {
    return ActivityData(
      id: id ?? this.id,
      userName: userName,
      activityTitle: activityTitle,
      runTime: runTime,
      location: location,
      distanceInMeters: distanceInMeters,
      duration: duration,
      routePoints: routePoints,
      calories: calories,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      commentsList: commentsList ?? this.commentsList,
      shares: shares,
    );
  }

  /// Converte uma instância de ActivityData em um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'activityTitle': activityTitle,
      'runTime': runTime,
      'location': location,
      'distanceInMeters': distanceInMeters,
      'durationInMilliseconds': duration.inMilliseconds,
      'routePoints': routePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'calories': calories,
      'likes': likes,
      'isLiked': isLiked,
      'commentsList': commentsList,
      'shares': shares,
    };
  }

  /// Cria uma instância de ActivityData a partir de um mapa JSON.
  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      id: json['id'],
      userName: json['userName'],
      activityTitle: json['activityTitle'],
      runTime: json['runTime'],
      location: json['location'],
      distanceInMeters: json['distanceInMeters'],
      duration: Duration(milliseconds: json['durationInMilliseconds']),
      routePoints: (json['routePoints'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
      calories: json['calories'],
      likes: json['likes'],
      isLiked: json['isLiked'] ?? false,
      commentsList: List<String>.from(json['commentsList'] ?? []),
      shares: json['shares'],
    );
  }
}
