import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'application/app_settings_service.dart';
import 'application/finance_service.dart';
import 'application/session_sensitive_access.dart';
import 'application/transaction_catalog_service.dart';
import 'application/transaction_service.dart';
import 'application/view_month_service.dart';
import 'data/datasources/finance_local_datasource.dart';
import 'data/datasources/recurring_transaction_local_datasource.dart';
import 'data/datasources/transaction_local_datasource.dart';
import 'data/db/app_database.dart';
import 'data/repositories/app_settings_repository_impl.dart';
import 'data/repositories/finance_repository_impl.dart';
import 'data/repositories/transaction_catalog_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'data/repositories/view_month_repository_impl.dart';
import 'presentation/app.dart';
import 'presentation/catalog/transaction_catalog_controller.dart';
import 'presentation/settings/app_settings_controller.dart';
import 'presentation/view_month/view_month_controller.dart';

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
      recurring: RecurringTransactionsLocalDataSource(database),
    ),
    transactionService,
    idFactory: uuid.v4,
    clock: DateTime.now,
  );
  final settingsController = AppSettingsController(
    AppSettingsService(AppSettingsRepositoryImpl(prefs)),
  );
  final catalogController = TransactionCatalogController(
    TransactionCatalogService(
      TransactionCatalogRepositoryImpl(prefs),
      idFactory: uuid.v4,
    ),
  );
  final viewMonthController = ViewMonthController(
    ViewMonthService(ViewMonthRepositoryImpl(prefs)),
    clock: DateTime.now,
  );
  await Future.wait([
    settingsController.load(),
    catalogController.load(),
    viewMonthController.load(),
  ]);

  runApp(
    TienDayApp(
      transactionService: transactionService,
      financeService: financeService,
      sensitiveAccess: SessionSensitiveAccess(
        repository: PinRepositoryImpl(prefs),
        saltFactory: uuid.v4,
      ),
      settingsController: settingsController,
      catalogController: catalogController,
      viewMonthController: viewMonthController,
    ),
  );
}
