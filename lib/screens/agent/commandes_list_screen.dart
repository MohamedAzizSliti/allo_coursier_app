import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'paged_orders_view.dart';

/// Today's / all commandes list (dashboard "Colis" card).
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, this.shipment = 'Tous', this.todayOnly = false});

  final String shipment;
  final bool todayOnly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(todayOnly ? context.s.parcelsToday : context.s.orderTracking),
      ),
      body: PagedOrdersView(initialShipment: shipment, todayOnly: todayOnly),
    );
  }
}
