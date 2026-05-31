import 'package:flutter/material.dart';

/// Constantes de diseño del sistema de autenticación de GlobalScore.
/// Estilo: Brutalista Retro Japonés
/// Tipografías: DM Mono (mono) + Sora (sans)
/// Agrega en pubspec.yaml:
///   google_fonts: ^6.x
///   Y en assets o usa google_fonts package.
///
/// Colores:
///   cream   → fondo principal
///   surface → fondo elevado (sub-headers)
///   border  → líneas / separadores
///   dark    → texto principal
///   accent  → púrpura #5B4FD8
///   muted   → texto secundario / placeholders
abstract class AuthTheme {
  // Colores
  static const Color cream   = Color(0xFFF0EDE8);
  static const Color surface = Color(0xFFE8E4DE);
  static const Color border  = Color(0xFFD4CFC8);
  static const Color dark    = Color(0xFF1E202C);
  static const Color accent  = Color(0xFF5B4FD8);
  static const Color muted   = Color(0xFFB0AAA0);
  static const Color green   = Color(0xFF1D9E75);
  static const Color red     = Color(0xFFEF4444);

  // Tipografía
  // IMPORTANTE: Para usar DM Mono y Sora, agrega en pubspec.yaml:
  //   dependencies:
  //     google_fonts: ^6.2.1
  // Y en main.dart antes de runApp():
  //   GoogleFonts.config.allowRuntimeFetching = true;
  // Luego reemplaza las referencias a fontMono/fontSans con:
  //   GoogleFonts.dmMono(...) y GoogleFonts.sora(...)
  // Por ahora, 'monospace' y 'sans-serif' son fallbacks.
  static const String fontMono = 'DM Mono';
  static const String fontSans = 'Sora';
}

/// Extensión para aplicar el tema de autenticación desde cualquier widget.
/// Uso: AuthTheme.inputDecoration(label: 'CORREO', hint: '...')
