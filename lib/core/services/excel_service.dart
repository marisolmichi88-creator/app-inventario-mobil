import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/category_model.dart';
import '../../data/models/movement_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/warehouse_model.dart';

/// Genera archivos Excel (.xlsx) reales sin paquetes adicionales:
/// un .xlsx es un paquete ZIP con hojas XML en formato OpenXML,
/// por lo que se construye con el paquete `archive` que ya usa la app.
class ExcelService {
  /// Reporte de inventario (HU21): estado actual del stock en Excel.
  static Future<void> exportInventory(
    List<ProductModel> products,
    List<CategoryModel> categories,
  ) async {
    final rows = <List<Object?>>[
      [
        'Código',
        'Nombre',
        'Categoría',
        'Stock',
        'Stock Mínimo',
        'Unidad',
        'Precio',
        'Moneda',
        'Estado',
      ],
    ];

    for (final p in products) {
      final categoryName =
          categories.where((c) => c.id == p.categoryId).firstOrNull?.name ??
              'Sin categoría';
      rows.add([
        p.code,
        p.name,
        categoryName,
        p.stock,
        p.minStock,
        p.unit ?? '',
        p.price,
        p.currency == 'USD' ? 'Dólares' : 'Soles',
        p.isActive ? 'Activo' : 'Inactivo',
      ]);
    }

    final stamp = DateFormat('dd-MM-yyyy_HHmm').format(DateTime.now());
    await _buildAndShare(
      'Inventario',
      rows,
      'Inventario_Proenergim_$stamp.xlsx',
    );
  }

  /// Reporte de movimientos (HU22): historial de entradas y salidas en Excel.
  static Future<void> exportMovements(
    List<MovementModel> movements,
    List<ProductModel> products,
    List<WarehouseModel> warehouses,
    List<ProjectModel> projects,
    List<UserModel> users,
  ) async {
    final rows = <List<Object?>>[
      [
        'Fecha',
        'Producto',
        'Tipo',
        'Cantidad',
        'Almacén',
        'Proyecto / Destino',
        'Usuario',
        'Observación',
      ],
    ];

    for (final mov in movements) {
      final productName =
          products.where((p) => p.id == mov.productId).firstOrNull?.name ??
              'Desconocido';
      final warehouseName =
          warehouses.where((w) => w.id == mov.warehouseId).firstOrNull?.name ??
              '';
      final projectName =
          projects.where((p) => p.id == mov.projectId).firstOrNull?.name ?? '';
      final userName =
          users.where((u) => u.id == mov.userId).firstOrNull?.name ?? '';
      final date = DateTime.tryParse(mov.date);

      rows.add([
        date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : mov.date,
        productName,
        mov.type == 'IN' ? 'Entrada' : 'Salida',
        mov.quantity,
        warehouseName,
        projectName,
        userName,
        mov.notes ?? '',
      ]);
    }

    final stamp = DateFormat('dd-MM-yyyy_HHmm').format(DateTime.now());
    await _buildAndShare(
      'Movimientos',
      rows,
      'Movimientos_Proenergim_$stamp.xlsx',
    );
  }

  // ---------- Construcción interna del archivo .xlsx ----------

  static Future<void> _buildAndShare(
    String sheetName,
    List<List<Object?>> rows,
    String fileName,
  ) async {
    final bytes = _buildXlsx(sheetName, rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      text: 'Reporte generado por Proenergim Stock',
    );
  }

  static List<int> _buildXlsx(String sheetName, List<List<Object?>> rows) {
    final archive = Archive()
      ..addFile(_xmlFile('[Content_Types].xml', _contentTypesXml))
      ..addFile(_xmlFile('_rels/.rels', _relsXml))
      ..addFile(_xmlFile('xl/workbook.xml', _workbookXml(sheetName)))
      ..addFile(_xmlFile('xl/_rels/workbook.xml.rels', _workbookRelsXml))
      ..addFile(_xmlFile('xl/styles.xml', _stylesXml))
      ..addFile(_xmlFile('xl/worksheets/sheet1.xml', _sheetXml(rows)));
    return ZipEncoder().encode(archive);
  }

  static ArchiveFile _xmlFile(String path, String content) =>
      ArchiveFile.bytes(path, utf8.encode(content));

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  /// Convierte índice de columna (0 = A) y fila (1-based) en referencia "A1".
  static String _cellRef(int col, int row) {
    var c = col;
    var ref = '';
    while (c >= 0) {
      ref = String.fromCharCode(65 + (c % 26)) + ref;
      c = (c ~/ 26) - 1;
    }
    return '$ref$row';
  }

  static String _sheetXml(List<List<Object?>> rows) {
    final colCount = rows.isEmpty ? 1 : rows.first.length;
    final buffer = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
      )
      ..write(
        '<cols><col min="1" max="$colCount" width="20" customWidth="1"/></cols>',
      )
      ..write('<sheetData>');

    for (var r = 0; r < rows.length; r++) {
      buffer.write('<row r="${r + 1}">');
      final style = r == 0 ? ' s="1"' : '';
      for (var c = 0; c < rows[r].length; c++) {
        final value = rows[r][c];
        final ref = _cellRef(c, r + 1);
        if (value is num) {
          buffer.write('<c r="$ref"$style><v>$value</v></c>');
        } else {
          final text = _escape(value?.toString() ?? '');
          buffer.write(
            '<c r="$ref"$style t="inlineStr"><is><t xml:space="preserve">$text</t></is></c>',
          );
        }
      }
      buffer.write('</row>');
    }

    buffer.write('</sheetData></worksheet>');
    return buffer.toString();
  }

  static String _workbookXml(String sheetName) =>
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="${_escape(sheetName)}" sheetId="1" r:id="rId1"/></sheets>'
      '</workbook>';

  static const String _contentTypesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '</Types>';

  static const String _relsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';

  static const String _workbookRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  static const String _stylesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2">'
      '<font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><name val="Calibri"/></font>'
      '</fonts>'
      '<fills count="2">'
      '<fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill>'
      '</fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="2">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
      '</cellXfs>'
      '</styleSheet>';
}
