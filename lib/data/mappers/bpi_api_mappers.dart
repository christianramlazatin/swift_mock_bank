import '../../api/bpi_api_models.dart';
import '../../models.dart';

class BpiApiMappers {
  static Customer mapCustomerFromEnvelope(Object? payload) {
    final Map<String, dynamic> map = _asMap(_unwrapData(payload));
    final String name = 'Christian Lazatin';

    return Customer(
      name: name,
      email: 'christian.lazatin@bpi.com.ph',
      address: 'Taguig City, Metro Manila, Philippines',
      phone: '+63 917 123 4567',
      age: _asInt(map['age']) ?? 30,
    );
  }

  static BankAccount mapAccountFromBalanceResponse(
    Object? payload, {
    required String accountId,
  }) {
    final Map<String, dynamic> map = _asMap(_unwrapData(payload));
    final double balance = mapBalanceResponse(payload, accountId: accountId);
    final String resolvedId =
        _pickString(map, <String>['account_id', 'accountId']) ?? accountId;

    return BankAccount(
      accountId: resolvedId,
      nickname: 'Christian Lazatin Account',
      accountType: _mapAccountType(
        _pickString(map, <String>['account_type', 'type']),
      ),
      accountNumber: _maskAccountNumber(resolvedId),
      balance: balance,
    );
  }

  static double mapBalanceResponse(
    Object? payload, {
    required String accountId,
  }) {
    final dynamic normalized = _unwrapData(payload);

    if (normalized is num) {
      return normalized.toDouble();
    }

    if (normalized is Map<String, dynamic>) {
      final double? directBalance = _asDouble(normalized['balance']);
      if (directBalance != null) {
        return directBalance;
      }

      final double? availableBalance = _asDouble(normalized['available_balance']);
      if (availableBalance != null) {
        return availableBalance;
      }

      final double? amount = _asDouble(normalized['amount']);
      if (amount != null) {
        return amount;
      }

      final dynamic account = normalized['account'];
      if (account is Map<String, dynamic>) {
        final double? accountBalance = _asDouble(account['balance']);
        if (accountBalance != null) {
          return accountBalance;
        }
      }
    }

    throw StateError('Unable to map balance response for account: $accountId');
  }

  static List<BankTransaction> mapTransactionsResponse(Object? payload) {
    final dynamic normalized = _unwrapData(payload);
    final List<dynamic> rows = _extractTransactionRows(normalized);

    final List<BankTransaction> transactions = rows
        .whereType<Map<String, dynamic>>()
        .map<BankTransaction>(mapTransaction)
        .toList(growable: false);

    transactions.sort(
      (BankTransaction a, BankTransaction b) => b.date.compareTo(a.date),
    );

    return transactions;
  }

  static BankTransaction mapTransaction(Map<String, dynamic> json) {
    final String title = _pickString(
          json,
          <String>['title', 'description', 'merchant', 'reference'],
        ) ??
        'Transaction';

    final TransactionCategory category = _mapCategory(
      _pickString(json, <String>['category', 'type', 'transaction_type']),
    );

    final DateTime date = _mapDate(
      json['date'] ?? json['timestamp'] ?? json['created_at'],
    );

    final double amount = _normalizeAmount(
      json,
      category: category,
      title: title,
    );

    return BankTransaction(
      title: title,
      category: category,
      date: date,
      amount: amount,
    );
  }

  static BpiTransferResult mapTransferResponse(Object? payload) {
    final Map<String, dynamic> map = _asMap(_unwrapData(payload));

    final bool success = _asBool(map['success']) ?? true;
    final String? referenceId = _pickString(
      map,
      <String>['reference_id', 'referenceId', 'transaction_id', 'id'],
    );
    final String? message = _pickString(
      map,
      <String>['message', 'detail', 'status'],
    );

    return BpiTransferResult(
      success: success,
      referenceId: referenceId,
      message: message,
      raw: map,
    );
  }

  static dynamic _unwrapData(Object? payload) {
    if (payload is Map<String, dynamic> && payload.containsKey('data')) {
      return payload['data'];
    }
    return payload;
  }

  static List<dynamic> _extractTransactionRows(dynamic payload) {
    if (payload is List<dynamic>) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      final dynamic transactions = payload['transactions'];
      if (transactions is List<dynamic>) {
        return transactions;
      }

      final dynamic items = payload['items'];
      if (items is List<dynamic>) {
        return items;
      }

      final dynamic history = payload['history'];
      if (history is List<dynamic>) {
        return history;
      }
    }

    return const <dynamic>[];
  }

  static double _normalizeAmount(
    Map<String, dynamic> json, {
    required TransactionCategory category,
    required String title,
  }) {
    final double raw = _asDouble(
          json['amount'] ??
              json['value'] ??
              json['transaction_amount'] ??
              json['total'],
        ) ??
        0;

    final String? direction = _pickString(
      json,
      <String>[
        'direction',
        'debit_credit',
        'entry_type',
        'transaction_type',
        'transactionType',
        'dr_cr',
        'dc_indicator',
      ],
    );

    final bool? isCreditFlag = _asBool(json['is_credit'] ?? json['credit']);
    final bool? isDebitFlag = _asBool(json['is_debit'] ?? json['debit']);
    final String normalizedDirection = (direction ?? '').trim().toLowerCase();

    if (_isDebitDirection(normalizedDirection) || isDebitFlag == true) {
      return -raw.abs();
    }

    if (_isCreditDirection(normalizedDirection) || isCreditFlag == true) {
      return raw.abs();
    }

    if (raw < 0) {
      return -raw.abs();
    }

    if (raw > 0) {
      if (category == TransactionCategory.income) {
        return raw.abs();
      }

      if (category == TransactionCategory.bills) {
        return -raw.abs();
      }

      if (category == TransactionCategory.transfer) {
        return _looksIncomingTransfer(json, title: title)
            ? raw.abs()
            : -raw.abs();
      }
    }

    return raw;
  }

  static bool _isDebitDirection(String value) {
    if (value.contains('debit') || value.contains('outflow')) {
      return true;
    }
    final List<String> tokens = value.split(RegExp(r'[^a-z0-9]+'));
    return tokens.contains('dr') ||
        tokens.contains('d') ||
        tokens.contains('deb') ||
        tokens.contains('out');
  }

  static bool _isCreditDirection(String value) {
    if (value.contains('credit') || value.contains('inflow')) {
      return true;
    }
    final List<String> tokens = value.split(RegExp(r'[^a-z0-9]+'));
    return tokens.contains('cr') ||
        tokens.contains('c') ||
        tokens.contains('cred') ||
        tokens.contains('in');
  }

  static bool _looksIncomingTransfer(
    Map<String, dynamic> json, {
    required String title,
  }) {
    final String context =
        '$title '
        '${_pickString(json, <String>['description', 'remarks', 'notes']) ?? ''} '
        '${_pickString(json, <String>['merchant', 'reference']) ?? ''}'
            .toLowerCase();

    if (context.contains('transfer from') ||
        context.contains('received') ||
        context.contains('incoming') ||
        context.contains('inbound') ||
        context.contains('credit from')) {
      return true;
    }

    if (context.contains('transfer to') ||
        context.contains('sent') ||
        context.contains('outgoing') ||
        context.contains('payment to')) {
      return false;
    }

    return false;
  }

  static AccountType _mapAccountType(String? raw) {
    final String value = (raw ?? '').toLowerCase();
    if (value.contains('saving')) {
      return AccountType.savings;
    }
    return AccountType.checking;
  }

  static TransactionCategory _mapCategory(String? raw) {
    final String value = (raw ?? '').toLowerCase();

    if (value.contains('income') || value.contains('salary')) {
      return TransactionCategory.income;
    }
    if (value.contains('food') || value.contains('grocery')) {
      return TransactionCategory.food;
    }
    if (value.contains('bill') || value.contains('utility')) {
      return TransactionCategory.bills;
    }
    if (value.contains('dining') || value.contains('restaurant')) {
      return TransactionCategory.dining;
    }
    if (value.contains('transfer')) {
      return TransactionCategory.transfer;
    }

    return TransactionCategory.transfer;
  }

  static DateTime _mapDate(Object? raw) {
    if (raw is DateTime) {
      return raw;
    }

    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }

    if (raw is String) {
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }

  static String _maskAccountNumber(String accountId) {
    final String digits = accountId.replaceAll(RegExp(r'[^0-9]'), '');
    final String suffix = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : accountId;
    return '**** $suffix';
  }

  static String? _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      final Object? value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
          return true;
        case 'false':
        case '0':
        case 'no':
          return false;
      }
    }
    return null;
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return <String, dynamic>{};
  }
}
