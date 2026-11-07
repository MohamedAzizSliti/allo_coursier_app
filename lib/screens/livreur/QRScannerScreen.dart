import 'package:flutter/material.dart';

import '../scan/parcel_scanner_screen.dart';

/// Driver scanner.
class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ParcelScannerScreen(role: 'delivery_person');
  }
}
