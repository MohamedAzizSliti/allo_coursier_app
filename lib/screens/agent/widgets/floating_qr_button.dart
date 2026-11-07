import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../qr_scanner_screen.dart';

class FloatingQRButton extends StatelessWidget {
  const FloatingQRButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      elevation: 6,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QRScannerScreen()),
        );
      },
      child: const Icon(Icons.qr_code_scanner, size: 30),
    );
  }
}
