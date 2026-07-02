import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import '../../core/database/database_helper.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbPath = await DatabaseHelper().getDatabasePath();
      final file = File(dbPath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(file.path)], text: 'Backup Inventario BD');
      } else {
        throw Exception('El archivo de base de datos no existe.');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  Future<void> _importDatabase(BuildContext context) async {
    try {
      const XTypeGroup dbGroup = XTypeGroup(
        label: 'Database',
        extensions: <String>['db', 'sqlite'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[dbGroup]);

      if (file != null) {
        File sourceFile = File(file.path);
        if (sourceFile.path.endsWith('.db')) {
          final targetPath = await DatabaseHelper().getDatabasePath();
          await sourceFile.copy(targetPath);
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('¡Restauración Exitosa!'),
                content: const Text('La base de datos se ha restaurado. Por favor, reinicia la aplicación para aplicar los cambios.'),
                actions: [
                  TextButton(
                    onPressed: () => exit(0), // Cierra la app para obligar al reinicio
                    child: const Text('Cerrar App'),
                  ),
                ],
              ),
            );
          }
        } else {
          throw Exception('Por favor selecciona un archivo .db válido.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copias de Seguridad')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 80, color: Color(0xFF0284C7)),
              const SizedBox(height: 24),
              const Text(
                'Protege tu inventario creando copias de seguridad de la base de datos local y guárdalas en un lugar seguro.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => _exportDatabase(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Exportar Copia de Seguridad'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _importDatabase(context),
                icon: const Icon(Icons.download),
                label: const Text('Restaurar desde un Archivo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Colors.white,
                  foregroundColor: const Color(0xFF0284C7),
                  side: const BorderSide(color: Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
