import 'package:flutter/material.dart';

/// Sombras suaves y consistentes para reducir el brillo excesivo en la UI.
abstract final class AppShadows {
  /// Sombra neutra para tarjetas, listas y contenedores.
  static List<BoxShadow> card({required bool isDark}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.012),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Sombra con tinte de color para elementos destacados.
  static List<BoxShadow> tinted(Color color, {double alpha = 0.1}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  /// Halo suave para iconos (login, splash).
  static List<BoxShadow> iconGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];
}
