import 'package:flutter/material.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';

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
}
