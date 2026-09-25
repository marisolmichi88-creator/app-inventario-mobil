import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Busca en bases públicas el nombre del producto que hay detrás de un código
/// de barras.
///
/// Un código de barras no lleva datos dentro: `7750123456789` es solo ese
/// número. Lo único que se puede hacer es preguntarle a un catálogo externo si
/// lo conoce. Esos catálogos cubren bien el retail y mal el material eléctrico
/// o industrial, así que **devolver null es el resultado normal**, no un
/// error. Por eso la pantalla ofrece siempre el botón de buscar en internet,
/// que funciona para cualquier código.
///
/// Solo sale del teléfono el número escaneado. No se envía ningún dato del
/// inventario ni del usuario.
class BarcodeLookup {
  const BarcodeLookup._();

  /// Búsqueda web del código, para cuando ningún catálogo lo reconoce. Es lo
  /// mismo que escribir el número a mano en el buscador.
  static Uri searchUrl(String code) =>
      Uri.https('www.google.com', '/search', {'q': code.trim()});

  /// Nombre sugerido para el producto, o null si nadie lo conoce.
  static Future<String?> productName(String code) async {
    final digits = code.trim();
    // Los catálogos indexan EAN y UPC: entre 8 y 14 dígitos. Cualquier otra
    // cosa (un QR interno, una URL) no tiene sentido consultarla.
    if (!RegExp(r'^\d{8,14}$').hasMatch(digits)) return null;

    return await _fromUpcItemDb(digits) ?? await _fromOpenFoodFacts(digits);
  }

  /// Catálogo general de productos de retail.
  static Future<String?> _fromUpcItemDb(String code) async {
    try {
      final response = await http
          .get(Uri.https('api.upcitemdb.com', '/prod/trial/lookup', {
            'upc': code,
          }))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map || data['items'] is! List) return null;
      final items = data['items'] as List;
      if (items.isEmpty) return null;
      final first = items.first;
      if (first is! Map) return null;

      return _compose(
        first['title']?.toString(),
        first['brand']?.toString(),
      );
    } catch (e) {
      debugPrint('UPCitemdb lookup failed: $e');
      return null;
    }
  }

  /// Segundo intento. Cubre sobre todo alimentación, pero es gratuito y a
  /// veces reconoce códigos que el anterior no.
  static Future<String?> _fromOpenFoodFacts(String code) async {
    try {
      final response = await http
          .get(
            Uri.https('world.openfoodfacts.org', '/api/v2/product/$code.json', {
              'fields': 'product_name,brands',
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map || data['status'] != 1) return null;
      final product = data['product'];
      if (product is! Map) return null;

      return _compose(
        product['product_name']?.toString(),
        product['brands']?.toString().split(',').first,
      );
    } catch (e) {
      debugPrint('OpenFoodFacts lookup failed: $e');
      return null;
    }
  }

  static String? _compose(String? title, String? brand) {
    final nombre = (title ?? '').trim();
    if (nombre.isEmpty) return null;
    final marca = (brand ?? '').trim();
    if (marca.isEmpty || nombre.toLowerCase().contains(marca.toLowerCase())) {
      return nombre;
    }
    return '$nombre - $marca';
  }
}
