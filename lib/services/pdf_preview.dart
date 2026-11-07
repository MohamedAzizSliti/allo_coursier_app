import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config/office_contact.dart';
import '../models/commande_model.dart';
import 'auth_service.dart';
import 'pdf_assets.dart';

const _brown = PdfColor.fromInt(0xFF6D4C41);
const _muted = PdfColor.fromInt(0xFF6D5F57);
const _ink = PdfColor.fromInt(0xFF3E2723);
const _tableBorder = PdfColor.fromInt(0xFFD9C7A7);
const _tableHeader = PdfColor.fromInt(0xFFEDE0C8);

/// Single-order PDF — same fields as web `single-order-pdf.tsx`, on A4.
/// Fetches fresh expéditeur contact like web `usePrintOrder`.
Future<void> showPdfPreview(CommandeModel order) async {
  try {
    final logoFuture = loadPdfLogoBytes();
    final qrFuture = _qrPngBytes(order.id);
    String? expediteurPhone;
    String expediteurName = order.expediteurName;
    if (order.expediteurId.trim().isNotEmpty) {
      try {
        final user = await UserApiService().getUser(order.expediteurId);
        final phone = user.phone?.trim();
        if (phone != null && phone.isNotEmpty) expediteurPhone = phone;
        if (user.name.trim().isNotEmpty) expediteurName = user.name.trim();
      } catch (_) {
        // Fall back to order fields when the profile lookup fails.
      }
    }

    final logoBytes = await logoFuture;
    final qrBytes = await qrFuture;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final dayFmt = DateFormat('dd/MM/yyyy');

    String fmtDateTime(String? raw) {
      if (raw == null || raw.trim().isEmpty) return '—';
      final parsed = DateTime.tryParse(raw);
      return parsed == null ? raw : dateFmt.format(parsed.toLocal());
    }

    String fmtDate(String? raw) {
      if (raw == null || raw.trim().isEmpty) return '—';
      final parsed = DateTime.tryParse(raw);
      return parsed == null ? raw : dayFmt.format(parsed.toLocal());
    }

    final pdf = pw.Document(
      title: 'Commande ${order.id}',
      author: OfficeContact.name,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoBytes != null)
                    pw.Image(
                      pw.MemoryImage(logoBytes),
                      width: 64,
                      height: 64,
                    ),
                  if (logoBytes != null) pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          OfficeContact.name,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: _brown,
                          ),
                        ),
                        pw.Text(
                          OfficeContact.pdfPhone,
                          style: const pw.TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (qrBytes != null)
                    pw.Image(pw.MemoryImage(qrBytes), width: 90, height: 90),
                ],
              ),
              pw.SizedBox(height: 14),
              _field('Commande N°', order.id),
              _field('Date', fmtDateTime(order.date)),
              _field('Livraison prévue', fmtDate(order.deliveryDate)),
              _section('Client'),
              _field('Nom', order.clientNom),
              _field('Téléphone', order.clientTelephone),
              _field('Adresse', order.clientAdresse),
              _field(
                'Ville / Gouvernorat',
                '${order.clientVille}, ${order.clientGouvernorat}',
              ),
              _section('Produit'),
              _field('Nom', order.produitNom),
              _field('Fragile', order.produitFragile ? 'Oui' : 'Non'),
              _field(
                'Ouvrir avant paiement',
                order.produitOuvrirAvantPaiement ? 'Oui' : 'Non',
              ),
              if (order.produitList.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                _productTable(order.produitList),
              ],
              _field(
                'Frais de livraison',
                '${order.fraisLivraison.toStringAsFixed(2)} TND',
              ),
              _field(
                'Prix total',
                '${order.produitPrixTotal.toStringAsFixed(2)} TND',
              ),
              _section('Expéditeur'),
              _field('Nom', expediteurName),
              _field('Téléphone', expediteurPhone ?? '—'),
              pw.Spacer(),
              pw.Text(
                OfficeContact.address,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  } catch (e) {
    debugPrint('Error generating PDF: $e');
  }
}

pw.Widget _field(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: _ink,
              fontSize: 10,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(color: _ink, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _section(String title) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
    padding: const pw.EdgeInsets.all(4),
    color: _brown,
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
    ),
  );
}

pw.Widget _productTable(List<Map<String, dynamic>> products) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _tableBorder, width: 1),
    ),
    child: pw.Column(
      children: [
        pw.Container(
          color: _tableHeader,
          child: pw.Row(
            children: [
              _th('Produit'),
              _th('Quantité (kg)'),
              _th('Prix/Kg'),
            ],
          ),
        ),
        for (final p in products)
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: _tableBorder, width: 1),
              ),
            ),
            child: pw.Row(
              children: [
                _td('${p['name'] ?? ''}'),
                _td('${p['quantity'] ?? ''}'),
                _td(
                  ((p['pricePerKilo'] as num?)?.toDouble() ?? 0)
                      .toStringAsFixed(2),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

pw.Widget _th(String text) {
  return pw.Expanded(
    child: pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    ),
  );
}

pw.Widget _td(String text) {
  return pw.Expanded(
    child: pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    ),
  );
}

Future<Uint8List?> _qrPngBytes(String data) async {
  final qrImageData = await QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: true,
  ).toImageData(256);
  if (qrImageData == null) return null;
  final image = await decodeImageFromList(qrImageData.buffer.asUint8List());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes?.buffer.asUint8List();
}
