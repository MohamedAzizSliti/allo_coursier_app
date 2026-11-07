import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../config/office_contact.dart';
import '../../domain/circuit_sheet.dart';
import '../../models/commande_model.dart';
import '../../services/pdf_assets.dart';

/// Landscape circuit sheet — layout matches web `circuit-pdf.tsx`.
Future<void> printAndShowPDF({
  required List<CommandeModel> orders,
  required String livreurName,
  required String vehicleLabel,
  required DateTime date,
  required String bonLivraison,
}) async {
  final sorted = sortCircuitOrders(orders);
  final pdf = pw.Document(
    title: bonLivraison,
    author: OfficeContact.name,
  );

  final logoBytes = await loadPdfLogoBytes();

  const ink = PdfColors.black;
  const line = 0.7;
  final dayLabel = DateFormat('yyyy-MM-dd').format(date);

  pw.Widget cell(
    String text, {
    required double flex,
    bool header = false,
  }) {
    return pw.Expanded(
      flex: (flex * 100).round(),
      child: pw.Container(
        constraints: const pw.BoxConstraints(minHeight: 32),
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: pw.BorderSide(width: line, color: ink),
            bottom: pw.BorderSide(width: line, color: ink),
          ),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: header ? 10 : 11,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(16, 18, 16, 36),
      header: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoBytes != null)
                  pw.Image(pw.MemoryImage(logoBytes), width: 56, height: 56),
                if (logoBytes != null) pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        OfficeContact.name,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        OfficeContact.address,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      bonLivraison,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${sorted.length} Colis',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Livreur : $livreurName',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Véhicule : $vehicleLabel',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Date : $dayLabel',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(width: line, color: ink),
                  left: pw.BorderSide(width: line, color: ink),
                ),
              ),
              child: pw.Row(
                children: [
                  for (final column in kCircuitColumns)
                    cell(
                      column.label,
                      flex: kCircuitColumnFlex[column.key] ?? 1,
                      header: true,
                    ),
                ],
              ),
            ),
          ],
        );
      },
      footer: (context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page: ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 11),
          ),
        );
      },
      build: (context) {
        return [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(width: line, color: ink),
              ),
            ),
            child: pw.Column(
              children: [
                for (final order in sorted)
                  pw.Row(
                    children: [
                      for (final column in kCircuitColumns)
                        cell(
                          circuitCell(order, column.key),
                          flex: kCircuitColumnFlex[column.key] ?? 1,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ];
      },
    ),
  );

  final bytes = await pdf.save();
  // Share only — layoutPdf first often fails/cancels on Android with no
  // printer configured, which made the first generate look broken.
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'circuit-$bonLivraison.pdf',
  );
}
