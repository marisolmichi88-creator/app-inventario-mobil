import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required Color accentColor,
    required IconData icon,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Eliminar la snackbar actual si hay alguna activa
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: screenHeight - 220,
          left: screenWidth * 0.38,
          right: screenWidth * 0.02,
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Forma de píldora redondeada
          side: BorderSide(
            color: isDark
                ? accentColor.withValues(alpha: 0.3)
                : accentColor.withValues(alpha: 0.25),
            width: 1.5,
          ), // Borde sutil del color de la alerta
        ),
        elevation: isDark ? 2 : 4,
        duration: const Duration(seconds: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message: message,
      accentColor: const Color(0xFF34D399), // Verde esmeralda claro
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    show(
      context,
      message: message,
      accentColor: const Color(0xFFF87171), // Rojo pastel
      icon: Icons.error_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    show(
      context,
      message: message,
      accentColor: const Color(0xFFFBBF24), // Amarillo ámbar
      icon: Icons.warning_rounded,
    );
  }
}
