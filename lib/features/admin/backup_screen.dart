import 'package:flutter/material.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/admin_ui.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: adminScaffoldBackground(context),
      appBar: adminAppBar(context, 'Copias de Seguridad'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.card(isDark: isDark),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF10B981).withValues(alpha: 0.25)
                          : const Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_done_rounded,
                      size: 56,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Datos Seguros en la Nube',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu inventario está respaldado automáticamente y en tiempo real en los servidores seguros de Supabase.\\n\\nYa no es necesario realizar copias de seguridad manuales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Volver'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1959AD),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
