import 'package:flutter/widgets.dart';

import 'transaction_catalog_controller.dart';

class TransactionCatalogScope
    extends InheritedNotifier<TransactionCatalogController> {
  const TransactionCatalogScope({
    super.key,
    required TransactionCatalogController controller,
    required super.child,
  }) : super(notifier: controller);

  static TransactionCatalogController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<TransactionCatalogScope>();
    assert(scope != null, 'TransactionCatalogScope is missing.');
    return scope!.notifier!;
  }

  static TransactionCatalogController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TransactionCatalogScope>()
        ?.notifier;
  }
}
