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

  /// Contenido opcional bajo el título y la ubicación, a lo ancho de la tarjeta.
  final Widget? footer;

  const AdminListCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.footer,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                if (footer != null) ...[
                  const SizedBox(height: 12),
                  footer!,
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

/// Botón de eliminar para los formularios de administración.
Widget adminDeleteButton({
  required VoidCallback onPressed,
  String tooltip = 'Eliminar',
}) {
  return IconButton(
    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
    tooltip: tooltip,
    onPressed: onPressed,
  );
}

/// Confirmación centrada para borrados definitivos.
///
/// Devuelve `true` solo si la persona eligió eliminar. El botón de cancelar es
/// el que queda por defecto para que un toque distraído no borre nada.
///
/// [itemName] es lo que se va a eliminar y [warning] explica la consecuencia
/// concreta (por ejemplo, que se pierde el historial asociado).
Future<bool> showAdminDeleteConfirm(
  BuildContext context, {
  required String title,
  required String itemName,
  String? warning,
  String confirmLabel = 'Eliminar definitivamente',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFEF4444), size: 28),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              itemName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(dialogCtx).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              warning ?? 'Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    confirmLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  return result ?? false;
}
