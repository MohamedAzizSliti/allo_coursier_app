import 'package:flutter/material.dart';

import 'paged_orders_view.dart';

/// All commandes screen (agent dashboard bottom nav).
class CommandessScreen extends StatelessWidget {
  const CommandessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PagedOrdersView(initialShipment: 'En cours'),
    );
  }
}
