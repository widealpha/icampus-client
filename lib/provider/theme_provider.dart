import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  static ThemeProvider? _instance;

  ThemeProvider._();

  factory ThemeProvider() {
    _instance ??= ThemeProvider._();
    return _instance!;
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeData _theme = ThemeData.light();
  ThemeData _darkTheme = ThemeData.light();

  ThemeMode get themeMode => _themeMode;

  set themeMode(ThemeMode value) {
    if (value != _themeMode) {
      _themeMode = value;
      notifyListeners();
    }
  }

  ThemeData get theme => _theme;

  set theme(ThemeData value) {
    if (value != _theme) {
      _theme = value;
      notifyListeners();
    }
  }

  ThemeData get darkTheme => _darkTheme;

  set darkTheme(ThemeData value) {
    if (value != _darkTheme) {
      _darkTheme = value;
      notifyListeners();
    }
  }
}
