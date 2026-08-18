import 'package:flutter/material.dart';

import '../application/transaction_service.dart';
import '../domain/security/sensitive_access_port.dart';

/// Phase 02 placeholder only. Product screens start in later phases.
class TienDayApp extends StatelessWidget {
  const TienDayApp({
    super.key,
    required this.transactionService,
    required this.sensitiveAccess,
  });

  final TransactionService transactionService;
  final SensitiveAccessPort sensitiveAccess;

  @override
  Widget build(BuildContext context) {
    assert(() {
      transactionService.list;
      sensitiveAccess.lock;
      return true;
    }());
    return const MaterialApp(
      title: 'Tiền Đây',
      debugShowCheckedModeBanner: false,
      home: _FoundationPlaceholder(),
    );
  }
}

class _FoundationPlaceholder extends StatelessWidget {
  const _FoundationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Tiền Đây — production foundation'),
      ),
    );
  }
}
