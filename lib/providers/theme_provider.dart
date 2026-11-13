import 'package:flutter/material.dart';
import '../data/datasource/local_datasource.dart';

/// ThemeProvider manages the application's light/dark mode state
/// and persists the user's choice in Hive.
class ThemeProvider extends ChangeNotifier {
  final LocalDataSource _local;
  bool isDark;

  ThemeProvider(this._local) : isDark = _local.isDark;

  /// Toggle between Light and Dark mode
  void toggle() {
    isDark = !isDark;
    _local.saveDark(isDark);
    notifyListeners();
  }
}
