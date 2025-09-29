import 'dart:convert';
import 'package:hibrido/features/activity/models/activity_data.dart';
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
}
