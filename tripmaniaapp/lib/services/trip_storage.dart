import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_activity.dart';

class TripActivityStorage {
  static const String _storageKey = 'trip_activities';

  // Save a trip activity
  static Future<bool> saveTripActivity(TripActivity activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing activities
      List<TripActivity> activities = await getTripActivities();

      // Add new activity
      activities.add(activity);

      // Convert to JSON strings
      List<String> activitiesJson = activities
          .map((activity) => jsonEncode(activity.toJson()))
          .toList();

      // Save to SharedPreferences
      return await prefs.setStringList(_storageKey, activitiesJson);
    } catch (e) {
      print('Error saving trip activity: $e');
      return false;
    }
  }

  // Get all trip activities
  static Future<List<TripActivity>> getTripActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? activitiesJson = prefs.getStringList(_storageKey);

      if (activitiesJson == null || activitiesJson.isEmpty) {
        return [];
      }

      return activitiesJson
          .map(
            (activityJson) => TripActivity.fromJson(jsonDecode(activityJson)),
          )
          .toList();
    } catch (e) {
      print('Error loading trip activities: $e');
      return [];
    }
  }

  // Delete a trip activity by ID
  static Future<bool> deleteTripActivity(String activityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<TripActivity> activities = await getTripActivities();

      // Remove the activity with matching ID
      activities.removeWhere((activity) => activity.id == activityId);

      // Convert to JSON strings
      List<String> activitiesJson = activities
          .map((activity) => jsonEncode(activity.toJson()))
          .toList();

      // Save updated list
      return await prefs.setStringList(_storageKey, activitiesJson);
    } catch (e) {
      print('Error deleting trip activity: $e');
      return false;
    }
  }

  // Get trip activities sorted by date (newest first)
  static Future<List<TripActivity>> getTripActivitiesSorted() async {
    List<TripActivity> activities = await getTripActivities();
    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activities;
  }

  // Get total number of saved activities
  static Future<int> getTripCount() async {
    List<TripActivity> activities = await getTripActivities();
    return activities.length;
  }

  // Clear all trip activities (for testing purposes)
  static Future<bool> clearAllTripActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing trip activities: $e');
      return false;
    }
  }
}
