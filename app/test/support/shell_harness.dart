import 'package:tien_day/application/finance_service.dart';
import 'package:tien_day/application/session_sensitive_access.dart';
import 'package:tien_day/application/transaction_service.dart';
import 'package:tien_day/presentation/home/home_controller.dart';
import 'package:tien_day/presentation/shell/main_shell.dart';

import 'memory_finance_repository.dart';

({MainShell shell, SessionSensitiveAccess access, MemoryFinanceRepository finance}) buildShell({
  required TransactionService transactions,
  required HomeController home,
  DateTime Function()? clock,
  MemoryPinRepository? pinRepo,
  MemoryFinanceRepository? financeRepo,
}) {
  final pins = pinRepo ?? MemoryPinRepository();
  final money = financeRepo ?? MemoryFinanceRepository();
  final now = clock ?? DateTime.now;
  final access = SessionSensitiveAccess(repository: pins, saltFactory: () => 'test-salt');
  final shell = MainShell(
    transactionService: transactions,
    homeController: home,
    financeService: FinanceService(
      money,
      transactions,
      idFactory: () => 'goal-1',
      clock: now,
    ),
    sensitiveAccess: access,
    clock: now,
  );
  return (shell: shell, access: access, finance: money);
}
