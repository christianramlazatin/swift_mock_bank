import 'package:flutter/material.dart';

import 'data/bank_repository.dart';
import 'models.dart';
import 'utils/app_formatters.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.repository,
    super.key,
  });

  static const String routeName = '/profile';

  final BankRepository repository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.repository.getProfileData();
  }

  void _reload() {
    setState(() {
      _profileFuture = widget.repository.getProfileData();
    });
  }

  Future<void> _pullToRefresh() async {
    _reload();
    try {
      await _profileFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileData>(
      future: _profileFuture,
      builder: (BuildContext context, AsyncSnapshot<ProfileData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              title: const Text('Customer Profile'),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Unable to load profile data.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final ProfileData data = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            title: const Text('Customer Profile'),
          ),
          body: RefreshIndicator(
            onRefresh: _pullToRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _CustomerHeaderCard(customer: data.customer),
                      const SizedBox(height: 16),
                      _CustomerDetailCard(customer: data.customer),
                      const SizedBox(height: 16),
                      _LinkedAccountsCard(accounts: data.accounts),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomerHeaderCard extends StatelessWidget {
  const _CustomerHeaderCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFFFF3E0),
              child: Text(
                '👤',
                style: TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(customer.email),
                ],
              ),
            ),
            Chip(
              label: const Text('Verified'),
              avatar: const Icon(Icons.verified, size: 18),
              backgroundColor: Colors.green.shade100,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDetailCard extends StatelessWidget {
  const _CustomerDetailCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Customer Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _DetailRow(label: 'Phone', value: customer.phone),
            _DetailRow(label: 'Address', value: customer.address),
            _DetailRow(label: 'Age', value: '${customer.age}'),
          ],
        ),
      ),
    );
  }
}

class _LinkedAccountsCard extends StatelessWidget {
  const _LinkedAccountsCard({required this.accounts});

  final List<BankAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final double listHeight = (accounts.length * 72.0).clamp(120.0, 320.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Linked Accounts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: listHeight,
              child: ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (BuildContext context, int index) {
                  final BankAccount account = accounts[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(account.nickname),
                    subtitle: Text(
                      '${account.accountType.label} • ${account.accountNumber}',
                    ),
                    trailing: Text(
                      AppFormatters.currency(account.balance),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
