import 'package:flutter/services.dart';

/// Shared PDF asset helpers (logo).
Future<Uint8List?> loadPdfLogoBytes() async {
  try {
    final data = await rootBundle.load('assets/images/logo.png');
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
