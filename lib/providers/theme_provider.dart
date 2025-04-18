import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeState {
  final bool isDarkMode;

  const ThemeState({
    this.isDarkMode = false,
  });

  ThemeState copyWith({bool? isDarkMode}) => ThemeState(
        isDarkMode: isDarkMode ?? this.isDarkMode,
      );
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'isDarkMode';
  static SharedPreferences? _prefs;

  ThemeNotifier() : super(const ThemeState());

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> loadTheme() async {
    await initialize();
    final isDarkMode = _prefs?.getBool(_themeKey) ?? false;
    state = state.copyWith(isDarkMode: isDarkMode);
  }

  Future<void> toggleTheme() async {
    await initialize();
    final isDarkMode = !state.isDarkMode;
    await _prefs?.setBool(_themeKey, isDarkMode);
    state = state.copyWith(isDarkMode: isDarkMode);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
