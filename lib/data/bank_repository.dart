import 'dart:developer' as developer;

import '../api/biller_api_service.dart';
import '../api/bpi_api_service.dart';
import 'mappers/biller_api_mappers.dart';
import 'mappers/bpi_api_mappers.dart';
import '../models.dart';

class DashboardData {
  const DashboardData({
    required this.customer,
    required this.accounts,
    required this.transactions,
    required this.billers,
  });

  final Customer customer;
  final List<BankAccount> accounts;
  final List<BankTransaction> transactions;
  final List<Biller> billers;

  double get totalBalance => accounts.fold<double>(
    0,
    (double total, BankAccount account) => total + account.balance,
  );
}

class ProfileData {
  const ProfileData({required this.customer, required this.accounts});

  final Customer customer;
  final List<BankAccount> accounts;
}

class BankRepository {
  const BankRepository({
    required this.apiService,
    required this.billerApiService,
    this.accountId = 'GCASH001',
    this.userId = 'GCASH001',
  });

  final BpiApiService apiService;
  final BillerApiService billerApiService;
  final String accountId;
  final String userId;

  Future<DashboardData> getDashboardData() async {
    Map<String, dynamic>? balancePayload;
    Map<String, dynamic>? transactionsPayload;
    Map<String, dynamic>? billersPayload;

    try {
      balancePayload = await apiService.getBalanceRaw(accountId: accountId);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch balance for accountId=$accountId',
        name: 'BankRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      transactionsPayload = await apiService.getTransactionHistoryRaw(
        userId: userId,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch transactions for userId=$userId',
        name: 'BankRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      billersPayload = await billerApiService.getSupportedBillersRaw();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch supported billers',
        name: 'BankRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final Customer customer = _resolveCustomer(
      balancePayload: balancePayload,
      transactionsPayload: transactionsPayload,
    );

    final List<BankAccount> accounts = _resolveAccounts(balancePayload);
    final List<BankTransaction> transactions = _resolveTransactions(
      transactionsPayload,
    );
    final List<Biller> billers = _resolveBillers(billersPayload);

    return DashboardData(
      customer: customer,
      accounts: accounts,
      transactions: transactions,
      billers: billers,
    );
  }

  Future<ProfileData> getProfileData() async {
    final DashboardData dashboard = await getDashboardData();
    return ProfileData(
      customer: dashboard.customer,
      accounts: dashboard.accounts,
    );
  }

  Customer _resolveCustomer({
    required Map<String, dynamic>? balancePayload,
    required Map<String, dynamic>? transactionsPayload,
  }) {
    if (balancePayload != null) {
      return BpiApiMappers.mapCustomerFromEnvelope(balancePayload);
    }

    if (transactionsPayload != null) {
      return BpiApiMappers.mapCustomerFromEnvelope(transactionsPayload);
    }

    return const Customer(
      name: 'Christian',
      email: 'juan.delacruz@gcash.com',
      address: 'Makati City, Metro Manila, Philippines',
      phone: '+63 917 000 0000',
      age: 30,
    );
  }

  List<BankAccount> _resolveAccounts(Map<String, dynamic>? balancePayload) {
    if (balancePayload == null) {
      return <BankAccount>[
        BankAccount(
          accountId: accountId,
          nickname: 'Pangunahing Account',
          accountType: AccountType.checking,
          accountNumber: _maskAccountNumber(accountId),
          balance: 0,
        ),
      ];
    }

    try {
      return <BankAccount>[
        BpiApiMappers.mapAccountFromBalanceResponse(
          balancePayload,
          accountId: accountId,
        ),
      ];
    } catch (error, stackTrace) {
      developer.log(
        'Failed to map account from balance response for accountId=$accountId',
        name: 'BankRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return <BankAccount>[
        BankAccount(
          accountId: accountId,
          nickname: 'Pangunahing Account',
          accountType: AccountType.checking,
          accountNumber: _maskAccountNumber(accountId),
          balance: 0,
        ),
      ];
    }
  }

  List<BankTransaction> _resolveTransactions(
    Map<String, dynamic>? transactionsPayload,
  ) {
    if (transactionsPayload == null) {
      return const <BankTransaction>[];
    }

    try {
      return BpiApiMappers.mapTransactionsResponse(transactionsPayload);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to map transactions response for userId=$userId',
        name: 'BankRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return const <BankTransaction>[];
    }
  }

  List<Biller> _resolveBillers(Map<String, dynamic>? payload) {
    if (payload == null) {
      return _fallbackBillers();
    }

    try {
      final List<Biller> mapped = BillerApiMappers.mapSupportedBillers(payload);
      if (mapped.isEmpty) {
        return _fallbackBillers();
      }
      return mapped;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to map supported billers payload',
        name: 'BankRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _fallbackBillers();
    }
  }

  List<Biller> _fallbackBillers() {
    return const <Biller>[
      Biller(code: 'MAYNILAD', name: 'Maynilad Water Services'),
      Biller(code: 'MERALCO', name: 'Manila Electric Company'),
      Biller(code: 'GLOBE', name: 'Globe Telecom'),
      Biller(code: 'CONVERGE', name: 'Converge ICT'),
      Biller(code: 'SSS', name: 'Social Security System'),
      Biller(code: 'PAGIBIG', name: 'Home Development Mutual Fund'),
    ];
  }

  String _maskAccountNumber(String id) {
    final String digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    final String suffix = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : id;
    return '**** $suffix';
  }
}
