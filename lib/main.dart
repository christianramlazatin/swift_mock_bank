import 'package:flutter/material.dart';

import 'api/biller_api_service.dart';
import 'api/bpi_api_service.dart';
import 'data/bank_repository.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'profile_page.dart';

void main() {
  runApp(const SwiftBankApp());
}

class SwiftBankApp extends StatefulWidget {
  const SwiftBankApp({super.key, this.repository});

  final BankRepository? repository;

  @override
  State<SwiftBankApp> createState() => _SwiftBankAppState();
}

class _SwiftBankAppState extends State<SwiftBankApp> {
  late final BpiApiService _apiService;
  late final BillerApiService _billerApiService;
  BankRepository? _repository;

  @override
  void initState() {
    super.initState();

    _apiService = BpiApiService(baseUrl: 'http://127.0.0.1:8001');
    _billerApiService = BillerApiService(baseUrl: 'http://127.0.0.1:8001');

    _repository = widget.repository;
  }

  @override
  void dispose() {
    _apiService.dispose();
    _billerApiService.dispose();
    super.dispose();
  }

  void _handleLogin({required String accountNumber, required String password}) {
    final String identifier = _buildIdentifier(accountNumber);

    setState(() {
      _repository = BankRepository(
        apiService: _apiService,
        billerApiService: _billerApiService,
        accountId: identifier,
        userId: identifier,
      );
    });
  }

  void _handleLogout() {
    setState(() {
      _repository = null;
    });
  }

  String _buildIdentifier(String accountNumber) {
    final String normalizedAccountNumber = accountNumber.trim().toUpperCase();

    if (normalizedAccountNumber.startsWith('BPI')) {
      return normalizedAccountNumber;
    }

    return 'BPI$normalizedAccountNumber';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD32F2F),
        primary: const Color(0xFFD32F2F),
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BPI',
      theme: baseTheme,
      initialRoute: LoginPage.routeName,
      routes: <String, WidgetBuilder>{
        LoginPage.routeName: (_) => LoginPage(onSubmit: _handleLogin),
        HomePage.routeName: (_) {
          final BankRepository? repository = _repository;
          if (repository == null) {
            return LoginPage(onSubmit: _handleLogin);
          }
          return HomePage(repository: repository, onLogout: _handleLogout);
        },
        ProfilePage.routeName: (_) {
          final BankRepository? repository = _repository;
          if (repository == null) {
            return LoginPage(onSubmit: _handleLogin);
          }
          return ProfilePage(repository: repository);
        },
      },
    );
  }
}
