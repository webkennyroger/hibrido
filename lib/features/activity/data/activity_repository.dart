import 'dart:convert';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uma classe de repositório para gerenciar o armazenamento e a recuperação
/// de dados de atividades no armazenamento local.
class ActivityRepository {
  // Chave usada para armazenar a lista de atividades no SharedPreferences.
  static const _activitiesKey = 'user_activities';

  /// Salva uma nova atividade na lista de atividades existentes.
  ///
  /// Recupera a lista atual, adiciona a nova atividade e salva a lista
  /// atualizada de volta no armazenamento local.
  Future<void> saveActivity(ActivityData newActivity) async {
    final prefs = await SharedPreferences.getInstance();
    // Busca as atividades existentes.
    final existingActivities = await getActivities();
    // Adiciona a nova atividade no início da lista.
    existingActivities.insert(0, newActivity);

    // Converte a lista de objetos ActivityData para uma lista de Mapas (JSON).
    final List<String> activitiesJson = existingActivities
        .map((activity) => jsonEncode(activity.toJson()))
        .toList();

    // Salva a lista de JSON strings no SharedPreferences.
    await prefs.setStringList(_activitiesKey, activitiesJson);
  }

  /// Atualiza uma atividade existente na lista.
  Future<void> updateActivity(ActivityData updatedActivity) async {
    final prefs = await SharedPreferences.getInstance();
    final existingActivities = await getActivities();

    // Encontra o índice da atividade a ser atualizada pelo ID.
    final int index = existingActivities.indexWhere(
      (act) => act.id == updatedActivity.id,
    );

    if (index != -1) {
      // Substitui a atividade antiga pela nova.
      existingActivities[index] = updatedActivity;

      final List<String> activitiesJson = existingActivities
          .map((activity) => jsonEncode(activity.toJson()))
          .toList();
      await prefs.setStringList(_activitiesKey, activitiesJson);
    }
  }

  /// Exclui uma atividade da lista com base no seu ID.
  Future<void> deleteActivity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existingActivities = await getActivities();

    // Remove a atividade que corresponde ao ID fornecido.
    existingActivities.removeWhere((activity) => activity.id == id);

    // Converte a lista atualizada de volta para JSON.
    final List<String> activitiesJson = existingActivities
        .map((activity) => json.encode(activity.toJson()))
        .toList();
    await prefs.setStringList(_activitiesKey, activitiesJson);
  }

  /// Recupera a lista de todas as atividades salvas.
  Future<List<ActivityData>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    // Obtém a lista de JSON strings.
    final List<String>? activitiesJson = prefs.getStringList(_activitiesKey);

    if (activitiesJson == null) return [];

    // Converte a lista de JSON strings de volta para uma lista de objetos ActivityData.
    return activitiesJson
        .map((jsonString) => ActivityData.fromJson(jsonDecode(jsonString)))
        .toList();
  }

  /// Calcula estatísticas agregadas de todas as atividades.
  Future<AggregatedStats> calculateAggregatedStats() async {
    final activities = await getActivities();
    double totalDistance = 0;
    double totalDurationSeconds = 0;
    int totalPoints = 0;

    for (var activity in activities) {
      totalDistance += activity.distanceInMeters;
      totalDurationSeconds += activity.duration.inSeconds;
      totalPoints += activity.points;
    }

    final weeklyDistances = List.filled(7, 0.0);
    final today = DateTime.now();

    for (var activity in activities) {
      final difference = today.difference(activity.createdAt).inDays;
      if (difference >= 0 && difference < 7) {
        // O índice 6 é hoje, 5 é ontem, etc.
        weeklyDistances[6 - difference] += activity.distanceInMeters / 1000.0;
      }
    }

    return AggregatedStats(
      activityCount: activities.length,
      totalDistanceKm: totalDistance / 1000,
      totalHours: totalDurationSeconds / 3600,
      totalPoints: totalPoints,
      weeklyDistances: weeklyDistances,
    );
  }

  /// Retorna uma lista com as abreviações dos últimos 7 dias.
  List<String> getLast7DaysAbbreviated() {
    final days = <String>[];
    final today = DateTime.now();
    final formatter = DateFormat('E', 'pt_BR'); // 'E' para dia da semana curto

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      days.add(formatter.format(day));
    }
    return days;
  }
}

/// Modelo para armazenar as estatísticas agregadas.
class AggregatedStats {
  final int activityCount;
  final double totalDistanceKm;
  final double totalHours;
  final int totalPoints;
  final List<double> weeklyDistances;

  AggregatedStats({
    required this.activityCount,
    required this.totalDistanceKm,
    required this.totalHours,
    required this.totalPoints,
    required this.weeklyDistances,
  });
}
