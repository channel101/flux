// lib/main.dart

import 'package:flux/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String THEME_KEY = 'theme_mode';
  static const String DEFAULT_HABIT_TYPE_KEY = 'default_habit_type';
  static const String DEFAULT_DISPLAY_MODE_KEY = 'default_display_mode';
  
  // Theme settings
  static Future<bool> setDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDarkMode);
    return prefs.setBool(THEME_KEY, isDarkMode);
  }
  
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? false;
  }
  
  static Future<void> setSelectedTheme(String themeKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', themeKey);
  }
  
  static Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_theme') ?? 'default';
  }
  
  // Default habit type
  static Future<bool> setDefaultHabitType(HabitType type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(DEFAULT_HABIT_TYPE_KEY, type.index);
  }
  
  static Future<HabitType> getDefaultHabitType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(DEFAULT_HABIT_TYPE_KEY) ?? HabitType.SuccessBased.index;
    return HabitType.values[index];
  }
  
  // Default display mode
  static Future<bool> setDefaultDisplayMode(ReportDisplay mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(DEFAULT_DISPLAY_MODE_KEY, mode.index);
  }
  
  static Future<ReportDisplay> getDefaultDisplayMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt(DEFAULT_DISPLAY_MODE_KEY) ?? ReportDisplay.Rate.index;
    return ReportDisplay.values[index];
  }
}
