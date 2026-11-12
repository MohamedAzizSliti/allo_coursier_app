import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shared PDF asset helpers (logo + Unicode fonts).
Future<Uint8List?> loadPdfLogoBytes() async {
  try {
    final data = await rootBundle.load('assets/images/logo.png');
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// Open Sans via printing — Helvetica cannot draw em dash / Arabic / accents.
Future<pw.ThemeData> loadPdfTheme() async {
  final base = await PdfGoogleFonts.openSansRegular();
  final bold = await PdfGoogleFonts.openSansBold();
  return pw.ThemeData.withFont(base: base, bold: bold);
}
