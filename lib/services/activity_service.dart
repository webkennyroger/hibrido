import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/activity/screens/comments_screen.dart'
    show Comment;

class ActivityService extends ChangeNotifier {
  final ActivityRepository _repository = ActivityRepository();
  List<ActivityData> _activities = [];

  List<ActivityData> get activities => _activities;

  Future<void> loadActivities() async {
    _activities = await _repository.getActivities();
    notifyListeners();
  }

  Future<void> toggleLike(String activityId, String userAvatarUrl) async {
    final index = _activities.indexWhere((act) => act.id == activityId);
    if (index != -1) {
      final activity = _activities[index];
      final isLiked = !activity.isLiked;
      final likes = isLiked ? activity.likes + 1 : activity.likes - 1;
      final likers = List<String>.from(activity.likers);

      if (isLiked) {
        if (!likers.contains(userAvatarUrl)) {
          likers.insert(0, userAvatarUrl);
        }
      } else {
        likers.remove(userAvatarUrl);
      }

      final updatedActivity = activity.copyWith(
        isLiked: isLiked,
        likes: likes,
        likers: likers,
      );
      _activities[index] = updatedActivity;
      await _repository.updateActivity(updatedActivity);
      notifyListeners();
    }
  }

  /// Converte um objeto Comment em uma string JSON.
  static String commentToJson(Comment comment) {
    final Map<String, dynamic> data = {
      'id': comment.id,
      'userId': comment.userId,
      'userName': comment.userName,
      'userAvatarUrl': comment.userAvatarUrl,
      'text': comment.text,
      'timestamp': comment.timestamp.toIso8601String(),
      'replies': comment.replies.map((reply) => commentToJson(reply)).toList(),
    };
    return json.encode(data);
  }

  /// Converte uma string JSON de volta para um objeto Comment.
  static Comment? commentFromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);

      // Converte a lista de JSONs de respostas de volta para uma lista de objetos Comment.
      final List<Comment> replies = (data['replies'] as List<dynamic>)
          .map((replyJson) {
            // A resposta é uma string JSON, então decodificamos e chamamos a função recursivamente.
            final replyString = replyJson is String
                ? replyJson
                : json.encode(replyJson);
            return commentFromJson(replyString);
          })
          .where((reply) => reply != null)
          .cast<Comment>()
          .toList();

      return Comment(
        id: data['id'],
        userId: data['userId'],
        userName: data['userName'],
        userAvatarUrl: data['userAvatarUrl'],
        text: data['text'],
        timestamp: DateTime.parse(data['timestamp']),
        replies: replies,
      );
    } catch (e) {
      // Se houver um erro ao decodificar, retorna nulo para evitar que o app quebre.
      // Isso pode acontecer se houver dados antigos salvos em um formato diferente.
      if (kDebugMode) {
        print('Erro ao decodificar comentário JSON: $e');
      }
      return null;
    }
  }

  /// Analisa uma lista de strings JSON e retorna uma lista de objetos Comment.
  static List<Comment> parseComments(List<String> commentsJson) {
    return commentsJson
        .map((json) => commentFromJson(json))
        .where((c) => c != null)
        .cast<Comment>()
        .toList();
  }
}
