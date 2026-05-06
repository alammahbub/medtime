import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._();
  SettingsService._();

  static const String _keyBreakfast = 'meal_breakfast';
  static const String _keyLunch = 'meal_lunch';
  static const String _keyDinner = 'meal_dinner';
  static const String _keyInitialSet = 'meal_times_set';

  Future<bool> areMealTimesSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyInitialSet) ?? false;
  }

  Future<void> setMealTimes({
    required TimeOfDay breakfast,
    required TimeOfDay lunch,
    required TimeOfDay dinner,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBreakfast, _timeToString(breakfast));
    await prefs.setString(_keyLunch, _timeToString(lunch));
    await prefs.setString(_keyDinner, _timeToString(dinner));
    await prefs.setBool(_keyInitialSet, true);
  }

  Future<Map<String, TimeOfDay>> getMealTimes() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'Breakfast': _stringToTime(prefs.getString(_keyBreakfast) ?? '08:00'),
      'Lunch': _stringToTime(prefs.getString(_keyLunch) ?? '13:00'),
      'Dinner': _stringToTime(prefs.getString(_keyDinner) ?? '20:00'),
    };
  }

  String _timeToString(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  TimeOfDay _stringToTime(String str) {
    final parts = str.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
