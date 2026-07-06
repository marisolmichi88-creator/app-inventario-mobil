import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/movement_model.dart';
import '../../data/models/product_model.dart';
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
}
