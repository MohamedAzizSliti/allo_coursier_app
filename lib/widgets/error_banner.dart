import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(message),
        trailing: onRetry == null
            ? null
            : TextButton(onPressed: onRetry, child: Text(context.s.retry)),
      ),
    );
  }
}
