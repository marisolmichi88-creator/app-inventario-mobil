import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  try {
    final file = File('assets/icon.svg');
    if (!file.existsSync()) {
      debugPrint('Error: assets/icon.svg no existe');
      return;
    }
    final content = file.readAsStringSync();
    final regExp = RegExp(r'base64,([^"]+)');
    final match = regExp.firstMatch(content);
    if (match == null) {
      debugPrint('Error: No se encontró la firma base64 en el SVG');
      return;
    }
    final base64Str = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
    final bytes = base64Decode(base64Str);
    File('assets/logo.png').writeAsBytesSync(bytes);
    debugPrint(
      'Éxito: assets/logo.png (Sol y Paneles) ha sido creado exitosamente (${bytes.length} bytes)',
    );
  } catch (e) {
    debugPrint('Error durante la extracción: $e');
  }
}
