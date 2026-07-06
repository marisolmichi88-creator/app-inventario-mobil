import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/movement_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/warehouse_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class PdfService {
  static Future<void> generateAndPrintMovementsReport(
    List<MovementModel> movements,
    List<ProductModel> products,
  ) async {
    final pdf = pw.Document();

    // Intentar cargar la imagen del logo desde assets SVG y decodificar el base64 del PNG
    pw.MemoryImage? logoImage;
    try {
      final String svgData = await rootBundle.loadString('assets/icon-proenergim.svg');
      final RegExp regExp = RegExp(r'base64,([^"]+)');
      final RegExpMatch? match = regExp.firstMatch(svgData);
      if (match != null) {
        final String base64Str = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
        final Uint8List logoBytes = base64Decode(base64Str);
        logoImage = pw.MemoryImage(logoBytes);
      }
    } catch (e) {
      logoImage = null;
    }

    // Convertir a tabla de datos con header 'Observación'
    final tableHeaders = [
      'Fecha',
      'Producto',
      'Tipo',
      'Cantidad',
      'Observación',
    ];

    final tableData = movements.map((mov) {
      final product = products.firstWhere(
        (p) => p.id == mov.productId,
        orElse: () => products.first,
      );
      DateTime date = DateTime.tryParse(mov.date) ?? DateTime.now();
      String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

      return [
        formattedDate,
        product.name,
        mov.type == 'IN' ? 'Entrada' : 'Salida',
        mov.quantity.toString(),
        mov.notes ?? '',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabecera alineada y con logo
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PROENERGIM',
                      style: const pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Reporte de Movimientos de Inventario',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 45,
                    height: 45,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.blue900, thickness: 1),
            pw.SizedBox(height: 20),

            // Tabla con anchos optimizados
            pw.TableHelper.fromTextArray(
              headers: tableHeaders,
              data: tableData,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellHeight: 30,
              columnWidths: {
                0: const pw.FixedColumnWidth(110), // Fecha
                1: const pw.FixedColumnWidth(150), // Producto
                2: const pw.FixedColumnWidth(65), // Tipo (Entrada/Salida)
                3: const pw.FixedColumnWidth(65), // Cantidad
                4: const pw.FixedColumnWidth(110), // Observación
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
              },
            ),
          ];
        },
        footer: (pw.Context context) {
          final now = DateTime.now();
          final weekdays = [
            'Domingo',
            'Lunes',
            'Martes',
            'Miércoles',
            'Jueves',
            'Viernes',
            'Sábado',
          ];
          final String dayName = weekdays[now.weekday % 7];
          final String formattedDateTime =
              "$dayName, ${DateFormat('dd/MM/yyyy HH:mm').format(now)}";

          return pw.Column(
            children: [
              // Bloque de firma de autorización (siempre en la parte inferior de la página)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 30),
                      pw.Container(width: 150, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Firma',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generado el: $formattedDateTime',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Compartir o Imprimir el documento generado
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Proenergim_Movimientos.pdf',
    );
  }

  static Future<void> generateLabelsPdf(
    List<ProductModel> products, {
    bool isBarcode = false,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final weekdays = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    final String dayName = weekdays[now.weekday % 7];
    final String formattedDateTime =
        "$dayName, ${DateFormat('dd/MM/yyyy HH:mm').format(now)}";

    // Intentar cargar la imagen del logo desde assets SVG y decodificar el base64 del PNG
    pw.MemoryImage? logoImage;
    try {
      final String svgData = await rootBundle.loadString('assets/icon-proenergim.svg');
      final RegExp regExp = RegExp(r'base64,([^"]+)');
      final RegExpMatch? match = regExp.firstMatch(svgData);
      if (match != null) {
        final String base64Str = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
        final Uint8List logoBytes = base64Decode(base64Str);
        logoImage = pw.MemoryImage(logoBytes);
      }
    } catch (e) {
      logoImage = null;
    }



    int crossAxisCount = 3;
    if (products.length == 1) {
      crossAxisCount = 1;
    } else if (products.length == 2) {
      crossAxisCount = 2;
    } else if (products.length == 3) {
      crossAxisCount = 1;
    } else if (products.length == 4 || products.length == 5) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    // Configurar dimensiones de los stickers según la cantidad de columnas y el total
    double cardHeight = 110;
    double cardWidth = 140;
    double barcodeHeight = 32;
    double barcodeWidth = 100;
    double qrSize = 42;
    double nameFontSize = 9;

    if (products.length == 1) {
      cardHeight = 220;
      cardWidth = 320;
      barcodeHeight = 80;
      barcodeWidth = 240;
      qrSize = 120;
      nameFontSize = 16;
    } else if (crossAxisCount == 1) {
      // Para 3 productos en una sola columna
      cardHeight = 150;
      cardWidth = 220;
      barcodeHeight = 50;
      barcodeWidth = 160;
      qrSize = 75;
      nameFontSize = 11;
    } else if (crossAxisCount == 2) {
      cardHeight = 135;
      cardWidth = 175;
      barcodeHeight = 40;
      barcodeWidth = 135;
      qrSize = 55;
      nameFontSize = 11;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          // Construir los stickers
          final List<pw.Widget> items = products.map<pw.Widget>((prod) {
            final double logoSize = products.length == 1 ? 30 : 16;
            final double spacing = products.length == 1 ? 8 : 4;

            return pw.Container(
              height: cardHeight,
              width: cardWidth,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (logoImage != null) ...[
                    pw.Container(
                      width: logoSize,
                      height: logoSize,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(height: spacing),
                  ],
                  pw.Text(
                    prod.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: nameFontSize,
                    ),
                    maxLines: 1,
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: spacing),
                  pw.SizedBox(
                    height: isBarcode ? barcodeHeight : qrSize,
                    width: isBarcode ? barcodeWidth : qrSize,
                    child: pw.BarcodeWidget(
                      color: PdfColors.black,
                      barcode: isBarcode
                          ? pw.Barcode.code128()
                          : pw.Barcode.qrCode(),
                      data: prod.code,
                      drawText: false,
                    ),
                  ),
                  pw.SizedBox(height: spacing),
                  pw.Text(
                    'SKU: ${prod.code}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          }).toList();

          // Dividir en filas para la cuadrícula
          final List<pw.Widget> gridRows = [];
          for (int i = 0; i < items.length; i += crossAxisCount) {
            final end = (i + crossAxisCount < items.length)
                ? i + crossAxisCount
                : items.length;
            final rowItems = items.sublist(i, end);

            // Rellenar la fila si faltan elementos para mantener la proporción de columnas
            while (rowItems.length < crossAxisCount) {
              rowItems.add(
                pw.Opacity(opacity: 0.0, child: pw.Container(height: 1)),
              );
            }

            gridRows.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: rowItems
                    .map(
                      (item) => pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          child: pw.Center(child: item),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          }

          return [
            // Cabecera alineada y con logo
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(width: 45), // Espaciador de balance para el logo
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Etiquetas de Inventario',
                        style: const pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'PROENERGIM',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 45,
                    height: 45,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    width: 45,
                    height: 45,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue900,
                      shape: pw.BoxShape.circle,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'PE',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.blue900, thickness: 1),
            pw.SizedBox(height: 20),

            // Cuadrícula de stickers
            ...gridRows,
          ];
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generado el: $formattedDateTime',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Etiquetas_Proenergim.pdf',
    );
  }

  // Carga el logo desde el SVG (base64 embebido) de forma segura.
  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final String svgData =
          await rootBundle.loadString('assets/icon-proenergim.svg');
      final RegExp regExp = RegExp(r'base64,([^"]+)');
      final RegExpMatch? match = regExp.firstMatch(svgData);
      if (match != null) {
        final String base64Str =
            match.group(1)!.replaceAll(RegExp(r'\s+'), '');
        return pw.MemoryImage(base64Decode(base64Str));
      }
    } catch (_) {}
    return null;
  }

  static String _nowStamp() {
    final now = DateTime.now();
    const weekdays = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    final dayName = weekdays[now.weekday % 7];
    return "$dayName, ${DateFormat('dd/MM/yyyy HH:mm').format(now)}";
  }

  /// HU21 - Reporte del estado actual del inventario (stock) en PDF.
  static Future<void> generateInventoryReport(
    List<ProductModel> products,
    List<CategoryModel> categories,
  ) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogo();

    final headers = ['Código', 'Producto', 'Categoría', 'Stock', 'Mín', 'Precio'];
    final data = products.map((p) {
      final categoryName = categories
              .where((c) => c.id == p.categoryId)
              .map((c) => c.name)
              .firstOrNull ??
          'Sin categoría';
      final symbol = p.currency == 'USD' ? '\$' : 'S/.';
      return [
        p.code,
        p.name,
        categoryName,
        p.stock.toString(),
        p.minStock.toString(),
        '$symbol ${p.price.toStringAsFixed(2)}',
      ];
    }).toList();

    final totalProducts = products.length;
    final lowStock = products.where((p) => p.stock <= p.minStock).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _reportHeader(
            logoImage,
            'Reporte de Inventario Actual',
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _summaryChip('Productos', '$totalProducts', PdfColors.blue800),
              pw.SizedBox(width: 12),
              _summaryChip('Stock Crítico', '$lowStock', PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 26,
            columnWidths: {
              0: const pw.FixedColumnWidth(70),
              1: const pw.FlexColumnWidth(2.2),
              2: const pw.FlexColumnWidth(1.4),
              3: const pw.FixedColumnWidth(45),
              4: const pw.FixedColumnWidth(40),
              5: const pw.FixedColumnWidth(70),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.centerRight,
            },
          ),
        ],
        footer: (context) => _reportFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_Inventario_Proenergim.pdf',
    );
  }

  /// HU24 - Reporte de auditoría de movimientos (esquema inalterable, solo lectura).
  static Future<void> generateAuditReport(
    List<MovementModel> movements,
    List<ProductModel> products,
    List<WarehouseModel> warehouses,
    List<ProjectModel> projects,
    List<UserModel> users, {
    required String periodLabel,
  }) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogo();

    final headers = [
      'Fecha',
      'Producto',
      'Tipo',
      'Cant.',
      'Almacén',
      'Proyecto',
      'Usuario',
    ];

    final data = movements.map((mov) {
      final productName = products
              .where((p) => p.id == mov.productId)
              .map((p) => p.name)
              .firstOrNull ??
          'Desconocido';
      final warehouseName = warehouses
              .where((w) => w.id == mov.warehouseId)
              .map((w) => w.name)
              .firstOrNull ??
          '';
      final projectName = projects
              .where((p) => p.id == mov.projectId)
              .map((p) => p.name)
              .firstOrNull ??
          '';
      final userName = users
              .where((u) => u.id == mov.userId)
              .map((u) => u.name)
              .firstOrNull ??
          '';
      final date = DateTime.tryParse(mov.date);
      return [
        date != null ? DateFormat('dd/MM/yy HH:mm').format(date) : mov.date,
        productName,
        mov.type == 'IN' ? 'Entrada' : 'Salida',
        mov.quantity.toString(),
        warehouseName,
        projectName,
        userName,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _reportHeader(logoImage, 'Reporte de Auditoría de Movimientos'),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Periodo: $periodLabel',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  'DOCUMENTO SOLO LECTURA - NO EDITABLE',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.red800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Total de registros compilados: ${movements.length}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 24,
            columnWidths: {
              0: const pw.FixedColumnWidth(62),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FixedColumnWidth(45),
              3: const pw.FixedColumnWidth(32),
              4: const pw.FlexColumnWidth(1.1),
              5: const pw.FlexColumnWidth(1.1),
              6: const pw.FlexColumnWidth(1.1),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerLeft,
              6: pw.Alignment.centerLeft,
            },
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Este reporte fue generado automáticamente y compila todas las entradas y '
            'salidas del periodo sin permitir modificaciones. Su contenido refleja el '
            'estado inalterable de los movimientos registrados en el sistema.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
        footer: (context) => _reportFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_Auditoria_Proenergim.pdf',
    );
  }

  // ---------- Helpers de diseño compartidos por los reportes nuevos ----------

  static pw.Widget _reportHeader(pw.MemoryImage? logo, String subtitle) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PROENERGIM',
                  style: const pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            if (logo != null)
              pw.Container(
                width: 45,
                height: 45,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.blue900, thickness: 1),
      ],
    );
  }

  static pw.Widget _summaryChip(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _reportFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado el: ${_nowStamp()}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  /// HU23 - Reporte del consumo de materiales de un proyecto (productos,
  /// cantidades y costos) en PDF.
  static Future<void> generateProjectReport(
    ProjectModel project,
    List<MovementModel> movements,
    List<ProductModel> products,
  ) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogo();

    // Solo salidas (OUT) asociadas al proyecto
    final projectMovements =
        movements.where((m) => m.projectId == project.id && m.type == 'OUT');

    double total = 0.0;
    final data = projectMovements.map((mov) {
      final product = products
              .where((p) => p.id == mov.productId)
              .firstOrNull;
      final name = product?.name ?? 'Desconocido';
      final price = product?.price ?? 0.0;
      final cost = price * mov.quantity;
      total += cost;
      final date = DateTime.tryParse(mov.date);
      return [
        date != null ? DateFormat('dd/MM/yyyy').format(date) : mov.date,
        name,
        mov.quantity.toString(),
        price.toStringAsFixed(2),
        cost.toStringAsFixed(2),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _reportHeader(logoImage, 'Reporte de Consumo por Proyecto'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Proyecto: ${project.name}',
            style: const pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          if (project.client?.isNotEmpty == true) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Cliente: ${project.client}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
            ),
          ],
          if (project.description?.isNotEmpty == true) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              project.description!,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Producto', 'Cant.', 'P. Unit.', 'Costo'],
            data: data,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 26,
            columnWidths: {
              0: const pw.FixedColumnWidth(70),
              1: const pw.FlexColumnWidth(2.2),
              2: const pw.FixedColumnWidth(40),
              3: const pw.FixedColumnWidth(60),
              4: const pw.FixedColumnWidth(70),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Costo total del proyecto: ${total.toStringAsFixed(2)}',
              style: const pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
        ],
        footer: (context) => _reportFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Reporte_Proyecto_Proenergim.pdf',
    );
  }
}
