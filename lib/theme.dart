import 'package:flutter/material.dart';

import 'state.dart';

/// Colours for the hero card and accents of one colour theme.
class Palette {
  final Color seed;
  final Color heroBg; // dark card background
  final Color heroTrack; // ring track and chips
  final Color ring; // ring fill
  final Color ink; // main text on hero
  final Color soft; // secondary text on hero
  final Color accent; // bars, success
  const Palette({
    required this.seed,
    required this.heroBg,
    required this.heroTrack,
    required this.ring,
    required this.ink,
    required this.soft,
    required this.accent,
  });
}

const List<String> colorThemes = ['green', 'blue', 'purple', 'gold', 'coral'];
const List<String> themeModes = ['system', 'light', 'dark', 'black'];

const Map<String, Palette> palettes = {
  'green': Palette(
    seed: Color(0xFF0F7B5F),
    heroBg: Color(0xFF085041),
    heroTrack: Color(0xFF0F6E56),
    ring: Color(0xFFFAC775),
    ink: Color(0xFFE1F5EE),
    soft: Color(0xFF9FE1CB),
    accent: Color(0xFF1D9E75),
  ),
  'blue': Palette(
    seed: Color(0xFF185FA5),
    heroBg: Color(0xFF0C447C),
    heroTrack: Color(0xFF185FA5),
    ring: Color(0xFFFAC775),
    ink: Color(0xFFE6F1FB),
    soft: Color(0xFFB5D4F4),
    accent: Color(0xFF378ADD),
  ),
  'purple': Palette(
    seed: Color(0xFF534AB7),
    heroBg: Color(0xFF3C3489),
    heroTrack: Color(0xFF534AB7),
    ring: Color(0xFFFAC775),
    ink: Color(0xFFEEEDFE),
    soft: Color(0xFFCECBF6),
    accent: Color(0xFF7F77DD),
  ),
  'gold': Palette(
    seed: Color(0xFFBA7517),
    heroBg: Color(0xFF633806),
    heroTrack: Color(0xFF854F0B),
    ring: Color(0xFF9FE1CB),
    ink: Color(0xFFFAEEDA),
    soft: Color(0xFFFAC775),
    accent: Color(0xFFBA7517),
  ),
  'coral': Palette(
    seed: Color(0xFFD85A30),
    heroBg: Color(0xFF712B13),
    heroTrack: Color(0xFF993C1D),
    ring: Color(0xFFFAC775),
    ink: Color(0xFFFAECE7),
    soft: Color(0xFFF5C4B3),
    accent: Color(0xFFD85A30),
  ),
};

Palette paletteFor(String name) => palettes[name] ?? palettes['green']!;

/// The palette in use right now.
Palette get pal => paletteFor(app.colorTheme);

ThemeData buildTheme(String colorName, Brightness b, {bool black = false}) {
  final p = paletteFor(colorName);
  var scheme = ColorScheme.fromSeed(seedColor: p.seed, brightness: b);
  if (black) {
    scheme = scheme.copyWith(
      surface: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0E0E0E),
      surfaceContainer: const Color(0xFF141414),
      surfaceContainerHigh: const Color(0xFF1A1A1A),
      surfaceContainerHighest: const Color(0xFF222222),
    );
  }
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: black ? Colors.black : null,
  );
}

ThemeMode themeModeFor(String m) => switch (m) {
      'light' => ThemeMode.light,
      'dark' || 'black' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
