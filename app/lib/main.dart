import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'application/finance_service.dart';
import 'application/session_sensitive_access.dart';
import 'application/transaction_service.dart';
import 'data/datasources/finance_local_datasource.dart';
import 'data/datasources/transaction_local_datasource.dart';
import 'data/db/app_database.dart';
import 'data/repositories/finance_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.openFile();
  const uuid = Uuid();
  final prefs = PrefsLocalDataSource(database);
  final transactionService = TransactionService(
    TransactionRepositoryImpl(
      local: TransactionLocalDataSource(database),
      idFactory: uuid.v4,
      clock: DateTime.now,
    ),
  );
  final financeService = FinanceService(
    FinanceRepositoryImpl(
      prefs: prefs,
      goals: GoalsLocalDataSource(database),
    ),
    transactionService,
    idFactory: uuid.v4,
    clock: DateTime.now,
  );

  runApp(
    TienDayApp(
      transactionService: transactionService,
      financeService: financeService,
      sensitiveAccess: SessionSensitiveAccess(
        repository: PinRepositoryImpl(prefs),
        saltFactory: uuid.v4,
      ),
    ),
  );
}
