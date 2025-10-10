import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modelo de dados para representar uma atividade.
class ActivityData {
  final String id; // ID único para cada atividade
  final String userName;
  final String activityTitle;
  final String runTime;
  final String location;
  final String sport;
  final double distanceInMeters;
  final Duration duration;
  final List<LatLng> routePoints;
  final double calories;
  int likes;
  bool isLiked; // Estado de curtida do usuário local
  List<String> commentsList;
  final int shares;
  final String privacy;
  final String? notes;
  final List<String> taggedPartnerIds;
  final int? mood;
  final List<String> mediaPaths; // Renomeado de imagePaths

  ActivityData({
    required this.id,
    required this.userName,
    required this.activityTitle,
    required this.runTime,
    required this.location,
    required this.sport,
    required this.distanceInMeters,
    required this.duration,
    required this.routePoints,
    required this.calories,
    required this.likes,
    this.isLiked = false,
    List<String>? commentsList,
    required this.shares,
    this.privacy = 'public',
    this.notes,
    this.taggedPartnerIds = const [],
    this.mood,
    this.mediaPaths = const [],
  }) : commentsList = commentsList ?? [];

  // Método para criar uma cópia do objeto com alguns valores alterados.
  ActivityData copyWith({
    String? id,
    double? distanceInMeters,
    Duration? duration,
    List<LatLng>? routePoints,
    double? calories,
    String? activityTitle,
    String? sport,
    int? mood,
    String? privacy,
    String? notes,
    List<String>? taggedPartnerIds,
    int? likes,
    bool? isLiked,
    List<String>? commentsList,
    List<String>? mediaPaths,
  }) {
    return ActivityData(
      id: id ?? this.id, // Preserva o ID original
      userName: this.userName, // Preserva o nome do usuário original
      activityTitle: activityTitle ?? this.activityTitle,
      runTime: this.runTime, // Preserva o tempo original
      location: this.location, // Preserva a localização original
      sport: sport ?? this.sport,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
      duration: duration ?? this.duration,
      routePoints: routePoints ?? this.routePoints,
      calories: calories ?? this.calories,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      commentsList: commentsList ?? this.commentsList,
      shares: this.shares, // Preserva os compartilhamentos originais
      privacy: privacy ?? this.privacy,
      notes: notes ?? this.notes,
      taggedPartnerIds: taggedPartnerIds ?? this.taggedPartnerIds,
      mood: mood ?? this.mood,
      mediaPaths: mediaPaths ?? this.mediaPaths,
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
      'sport': sport,
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
      'privacy': privacy,
      'notes': notes,
      'taggedPartnerIds': taggedPartnerIds,
      'mood': mood,
      'mediaPaths': mediaPaths,
    };
  }

  /// Cria uma instância de ActivityData a partir de um mapa JSON.
  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      id: json['id'] ?? '',
      userName: json['userName'] ?? 'Usuário',
      activityTitle: json['activityTitle'] ?? 'Atividade',
      runTime: json['runTime'] ?? 'Data desconhecida',
      location: json['location'] ?? 'Localização desconhecida',
      sport: json['sport'] ?? 'Corrida', // Valor padrão para atividades antigas
      distanceInMeters: (json['distanceInMeters'] as num?)?.toDouble() ?? 0.0,
      duration: Duration(milliseconds: json['durationInMilliseconds'] ?? 0),
      routePoints: (json['routePoints'] as List? ?? [])
          .map(
            (point) => LatLng(
              (point['lat'] as num).toDouble(),
              (point['lng'] as num).toDouble(),
            ),
          )
          .toList(),
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      likes: json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      commentsList: List<String>.from(json['commentsList'] ?? []),
      shares: json['shares'] ?? 0,
      privacy: json['privacy'] ?? 'public',
      notes: json['notes'],
      taggedPartnerIds: List<String>.from(json['taggedPartnerIds'] ?? []),
      mood: json['mood'],
      mediaPaths: List<String>.from(json['mediaPaths'] ?? []),
    );
  }
}
