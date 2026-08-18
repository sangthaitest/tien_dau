import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'application/transaction_service.dart';
import 'data/datasources/transaction_local_datasource.dart';
import 'data/db/app_database.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/security/sensitive_access_port.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.openFile();
  const uuid = Uuid();
  final repository = TransactionRepositoryImpl(
    local: TransactionLocalDataSource(database),
    idFactory: uuid.v4,
    clock: DateTime.now,
  );
  final service = TransactionService(repository);

  runApp(
    TienDayApp(
      transactionService: service,
      sensitiveAccess: const LockedSensitiveAccess(),
    ),
  );
}
