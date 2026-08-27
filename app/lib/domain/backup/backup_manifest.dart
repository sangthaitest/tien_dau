import 'dart:convert';

import '../failures/app_failure.dart';

/// Portable Tiền đâu nè backup format (not a SQLite dump).
class BackupFormat {
  static const name = 'TienDauNeBackup';
  static const version = 1;
  static const fileExtension = 'tdn';
  static const lastBackupAtKey = 'last_backup_at';

  static const excludedPrefKeys = <String>{
    'pin_hash',
    'pin_salt',
    lastBackupAtKey,
    'profile_avatar_path',
  };

  static bool hasValidExtension(String path) {
    return path.toLowerCase().endsWith('.$fileExtension');
  }

  /// Example: `TienDauNe_Backup_2026-08-27_1435.tdn`
  static String fileNameFor(DateTime local) {
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return 'TienDauNe_Backup_$y-$m-${d}_$hh$mm.$fileExtension';
  }
}

class BackupSummary {
  const BackupSummary({
    required this.transactionCount,
    required this.categoryCount,
    required this.incomeCount,
    required this.recurringCount,
    this.includesFinance = true,
  });

  final int transactionCount;
  final int categoryCount;
  final int incomeCount;
  final int recurringCount;
  final bool includesFinance;

  Map<String, Object?> toJson() => {
        'transactionCount': transactionCount,
        'categoryCount': categoryCount,
        'incomeCount': incomeCount,
        'recurringCount': recurringCount,
        'includesFinance': includesFinance,
      };

  static BackupSummary parse(Object? raw) {
    if (raw is! Map) {
      throw const BackupFailure('Thống kê bản sao lưu không hợp lệ.');
    }
    final map = Map<String, dynamic>.from(raw);
    final transactionCount = _asInt(map['transactionCount']);
    final categoryCount = _asInt(map['categoryCount']);
    final incomeCount = _asInt(map['incomeCount']);
    final recurringCount = _asInt(map['recurringCount']);
    if (transactionCount == null ||
        categoryCount == null ||
        incomeCount == null ||
        recurringCount == null ||
        transactionCount < 0 ||
        categoryCount < 0 ||
        incomeCount < 0 ||
        recurringCount < 0) {
      throw const BackupFailure('Thống kê bản sao lưu không hợp lệ.');
    }
    return BackupSummary(
      transactionCount: transactionCount,
      categoryCount: categoryCount,
      incomeCount: incomeCount,
      recurringCount: recurringCount,
      includesFinance: map['includesFinance'] != false,
    );
  }
}

/// Versioned portable document written to `.tdn`.
class BackupDocument {
  const BackupDocument({
    required this.backupVersion,
    required this.createdAt,
    required this.appVersion,
    required this.platform,
    required this.summary,
    required this.transactions,
    required this.categories,
    required this.recurring,
    required this.savingsGoals,
    required this.prefs,
  });

  final int backupVersion;
  final DateTime createdAt;
  final String appVersion;
  final String platform;
  final BackupSummary summary;
  final List<Map<String, Object?>> transactions;
  final Map<String, Object?> categories;
  final List<Map<String, Object?>> recurring;
  final List<Map<String, Object?>> savingsGoals;
  final Map<String, String> prefs;

  Map<String, Object?> toJson() => {
        'format': BackupFormat.name,
        'backupVersion': backupVersion,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'appVersion': appVersion,
        'platform': platform,
        'summary': summary.toJson(),
        'financial': {
          'savingsGoals': savingsGoals,
          'recurring': recurring,
          'budgetMonth': prefs['budget_month'],
          'budgetLimit': prefs['budget_limit'],
        },
        'transactions': transactions,
        'categories': categories,
        'settings': {
          for (final entry in prefs.entries)
            if (entry.key != 'budget_month' && entry.key != 'budget_limit')
              entry.key: entry.value,
        },
      };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static BackupDocument parseBytes(List<int> bytes) {
    Object? raw;
    try {
      raw = jsonDecode(utf8.decode(bytes));
    } catch (error) {
      throw BackupFailure(
        'File không phải bản sao lưu hợp lệ của Tiền đâu nè hoặc file đã bị hỏng.',
        cause: error,
      );
    }
    return parse(raw);
  }

  static BackupDocument parse(Object? raw) => migrateToCurrent(raw);

  /// Future backup versions migrate here before validation.
  static BackupDocument migrateToCurrent(Object? raw) {
    if (raw is! Map) {
      throw const BackupFailure(
        'File không phải bản sao lưu hợp lệ của Tiền đâu nè hoặc file đã bị hỏng.',
      );
    }
    final map = Map<String, dynamic>.from(raw);
    final format = map['format'];
    final version = _asInt(map['backupVersion']);
    if (format != BackupFormat.name) {
      throw const BackupFailure(
        'File không phải bản sao lưu hợp lệ của Tiền đâu nè hoặc file đã bị hỏng.',
      );
    }
    if (version == null || version < 1) {
      throw const BackupFailure(
        'File này được tạo bởi phiên bản Tiền đâu nè không được hỗ trợ.',
      );
    }
    if (version > BackupFormat.version) {
      throw const BackupFailure(
        'File này được tạo bởi phiên bản Tiền đâu nè không được hỗ trợ.',
      );
    }
    // v1 is current; future versions would transform [map] here.
    return _parseV1(map);
  }

  static BackupDocument _parseV1(Map<String, dynamic> map) {
    final appVersion = map['appVersion'];
    final platform = map['platform'];
    final createdAtRaw = map['createdAt'];
    if (appVersion is! String ||
        appVersion.isEmpty ||
        platform is! String ||
        platform.isEmpty ||
        createdAtRaw is! String) {
      throw const BackupFailure(
        'File không phải bản sao lưu hợp lệ của Tiền đâu nè hoặc file đã bị hỏng.',
      );
    }
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      throw const BackupFailure(
        'File không phải bản sao lưu hợp lệ của Tiền đâu nè hoặc file đã bị hỏng.',
      );
    }

    final declaredSummary = BackupSummary.parse(map['summary']);
    final transactions = _asObjectList(map['transactions'], 'transactions');
    final financial = map['financial'];
    if (financial is! Map) {
      throw const BackupFailure('Thiếu dữ liệu Tài chính trong bản sao lưu.');
    }
    final savingsGoals =
        _asObjectList(financial['savingsGoals'], 'savingsGoals');
    final recurring = _asObjectList(financial['recurring'], 'recurring');

    final categoriesRaw = map['categories'];
    if (categoriesRaw is! Map) {
      throw const BackupFailure('Dữ liệu danh mục trong bản sao lưu không hợp lệ.');
    }
    final categories = <String, Object?>{
      for (final entry in categoriesRaw.entries)
        entry.key.toString(): entry.value as Object?,
    };

    final prefs = <String, String>{};
    final settings = map['settings'];
    if (settings is Map) {
      for (final entry in settings.entries) {
        final key = entry.key.toString();
        if (BackupFormat.excludedPrefKeys.contains(key)) continue;
        final value = entry.value;
        if (value == null) continue;
        prefs[key] = value is String ? value : jsonEncode(value);
      }
    }
    final budgetMonth = financial['budgetMonth'];
    final budgetLimit = financial['budgetLimit'];
    if (budgetMonth is String && budgetMonth.isNotEmpty) {
      prefs['budget_month'] = budgetMonth;
    }
    if (budgetLimit != null && '$budgetLimit'.isNotEmpty) {
      prefs['budget_limit'] = budgetLimit.toString();
    }
    if (!prefs.containsKey('transaction_catalog_v1')) {
      prefs['transaction_catalog_v1'] = jsonEncode(categories);
    }

    _validateTransactions(transactions);
    _validateRecurring(recurring);
    _validateGoals(savingsGoals);

    final incomeCount =
        recurring.where((row) => row['kind']?.toString() == 'income').length;
    final expenseRecurringCount = recurring
        .where((row) => row['kind']?.toString() != 'income')
        .length;
    final categoryCount = _categoryCount(categories);

    if (declaredSummary.transactionCount != transactions.length ||
        declaredSummary.incomeCount != incomeCount ||
        declaredSummary.recurringCount != expenseRecurringCount ||
        declaredSummary.categoryCount != categoryCount) {
      throw const BackupFailure(
        'Thống kê bản sao lưu không khớp với dữ liệu bên trong.',
      );
    }

    return BackupDocument(
      backupVersion: BackupFormat.version,
      createdAt: createdAt.toUtc(),
      appVersion: appVersion,
      platform: platform,
      summary: BackupSummary(
        transactionCount: transactions.length,
        categoryCount: categoryCount,
        incomeCount: incomeCount,
        recurringCount: expenseRecurringCount,
        includesFinance: true,
      ),
      transactions: transactions,
      categories: categories,
      recurring: recurring,
      savingsGoals: savingsGoals,
      prefs: prefs,
    );
  }
}

class BackupPreview {
  const BackupPreview({
    required this.document,
    required this.path,
  });

  final BackupDocument document;
  final String path;

  BackupSummary get summary => document.summary;
  DateTime get createdAt => document.createdAt;
  String get appVersion => document.appVersion;
}

List<Map<String, Object?>> _asObjectList(Object? raw, String label) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw BackupFailure('Dữ liệu $label trong bản sao lưu không hợp lệ.');
  }
  final out = <Map<String, Object?>>[];
  for (final item in raw) {
    if (item is! Map) {
      throw BackupFailure('Dữ liệu $label trong bản sao lưu không hợp lệ.');
    }
    out.add({
      for (final entry in item.entries)
        entry.key.toString(): entry.value as Object?,
    });
  }
  return out;
}

void _validateTransactions(List<Map<String, Object?>> rows) {
  const required = {
    'id',
    'amount',
    'type',
    'category_id',
    'occurred_date',
    'payment_source_id',
    'payment_source_name',
    'payment_method',
    'created_at',
    'updated_at',
  };
  final ids = <String>{};
  for (final row in rows) {
    for (final key in required) {
      final value = row[key];
      if (value == null || (value is String && value.isEmpty)) {
        throw const BackupFailure(
          'Giao dịch trong bản sao lưu bị thiếu trường bắt buộc.',
        );
      }
    }
    final id = row['id']?.toString();
    if (id == null || !ids.add(id)) {
      throw const BackupFailure('Giao dịch trong bản sao lưu có id không hợp lệ.');
    }
    if (_asInt(row['amount']) == null) {
      throw const BackupFailure('Số tiền giao dịch trong bản sao lưu không hợp lệ.');
    }
  }
}

void _validateRecurring(List<Map<String, Object?>> rows) {
  const required = {
    'id',
    'name',
    'kind',
    'amount',
    'frequency',
    'direction',
    'start_date',
    'created_at',
    'updated_at',
  };
  final ids = <String>{};
  for (final row in rows) {
    for (final key in required) {
      final value = row[key];
      if (value == null || (value is String && value.isEmpty)) {
        throw const BackupFailure(
          'Khoản định kỳ/thu nhập trong bản sao lưu bị thiếu trường bắt buộc.',
        );
      }
    }
    final id = row['id']?.toString();
    if (id == null || !ids.add(id)) {
      throw const BackupFailure(
        'Khoản định kỳ/thu nhập trong bản sao lưu có id không hợp lệ.',
      );
    }
  }
}

void _validateGoals(List<Map<String, Object?>> rows) {
  const required = {
    'id',
    'name',
    'target_amount',
    'current_amount',
    'created_at',
    'updated_at',
  };
  final ids = <String>{};
  for (final row in rows) {
    for (final key in required) {
      if (row[key] == null) {
        throw const BackupFailure(
          'Mục tiêu tiết kiệm trong bản sao lưu bị thiếu trường bắt buộc.',
        );
      }
    }
    final id = row['id']?.toString();
    if (id == null || !ids.add(id)) {
      throw const BackupFailure(
        'Mục tiêu tiết kiệm trong bản sao lưu có id không hợp lệ.',
      );
    }
  }
}

int _categoryCount(Map<String, Object?> categories) {
  final list = categories['categories'];
  if (list is List) return list.length;
  return 0;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
