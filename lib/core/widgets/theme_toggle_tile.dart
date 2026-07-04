import 'package:flutter/material.dart';

class ThemeToggleTile extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const ThemeToggleTile({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDarkMode ? 'Modo oscuro' : 'Modo claro',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Switch.adaptive(
            value: isDarkMode,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: accent,
            inactiveThumbColor: isDark ? Colors.grey.shade400 : Colors.white,
            inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
