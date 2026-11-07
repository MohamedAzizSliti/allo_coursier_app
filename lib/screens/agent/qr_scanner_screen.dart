import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../scan/parcel_scanner_screen.dart';

/// Office scanner (admin / agent).
class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AlloApi.instance.getStoredRole(),
      builder: (context, snapshot) {
        final role = snapshot.data ?? 'agent';
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return ParcelScannerScreen(role: role);
      },
    );
  }
}
