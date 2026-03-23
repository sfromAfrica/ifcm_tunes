import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

/// State Provider for managing the application's theme mode.
@Riverpod(
  keepAlive: true,
) // keepAlive keeps the state even if the user leaves the screen
class ThemeModeNotifier extends _$ThemeModeNotifier {
  // Initialize with the user's system preference as the default.
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  /// Toggles the theme between light and dark mode.
  /// If currently set to system, it switches to dark (as a common preference flow).
  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }

  /// Sets the theme mode explicitly.
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}
