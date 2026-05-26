import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  bool _darkMode = false;

  bool get darkMode => _darkMode;
  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }
}