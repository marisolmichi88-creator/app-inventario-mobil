import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/movement_model.dart';
import '../../data/models/product_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndPrintMovementsReport(
    List<MovementModel> movements,
    List<ProductModel> products,
  ) async {
    final pdf = pw.Document();

    // Using default font for simplicity

    // Convertir a tabla de datos
    final tableHeaders = ['Fecha', 'Producto', 'Tipo', 'Cantidad', 'Nota'];

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
            // Cabecera
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PROENERGIM',
                      style: const pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Reporte Oficial de Movimientos de Inventario',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Tabla
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
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
              },
            ),

            pw.SizedBox(height: 30),
            // Pie de firma
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Firma Autorizada',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ];
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

    // Crear una cuadrícula para pegatinas. Asumimos 3 columnas x 5 filas por hoja.
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          final List<pw.Widget> items = products.map((prod) {
            return pw.Container(
              width: 150,
              height: 120,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    prod.name,
                    style: const pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 4),
                  pw.SizedBox(
                    height: isBarcode ? 40 : 60,
                    width: isBarcode ? 120 : 60,
                    child: pw.BarcodeWidget(
                      color: PdfColors.black,
                      barcode: isBarcode
                          ? pw.Barcode.code128()
                          : pw.Barcode.qrCode(),
                      data: prod.code,
                      drawText: false,
                    ),
                  ),
                  pw.SizedBox(height: 4),
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

          return [
            pw.Text(
              'Etiquetas de Inventario - Proenergim',
              style: const pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Wrap(spacing: 10, runSpacing: 10, children: items),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Etiquetas_Proenergim.pdf',
    );
  }
}
