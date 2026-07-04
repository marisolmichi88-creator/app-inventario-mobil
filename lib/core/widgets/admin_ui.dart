import 'package:flutter/material.dart';
import '../theme/app_shadows.dart';

Color adminScaffoldBackground(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
}

AppBar adminAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 20,
        letterSpacing: -0.5,
      ),
    ),
    actions: actions,
  );
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                    : const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdminListCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AdminListCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card(isDark: isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget adminEditButton({required VoidCallback onPressed}) {
  return IconButton(
    icon: const Icon(Icons.edit_outlined, size: 20),
    color: const Color(0xFF3B82F6),
    tooltip: 'Editar',
    onPressed: onPressed,
  );
}

Widget adminStatusSwitch({
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Transform.scale(
    scale: 0.85,
    child: Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.5),
      activeThumbColor: const Color(0xFF10B981),
    ),
  );
}

Widget adminFab({
  required BuildContext context,
  required VoidCallback onPressed,
  required String label,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return FloatingActionButton.extended(
    onPressed: onPressed,
    backgroundColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
    foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
    elevation: 1,
    icon: const Icon(Icons.add),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
}
