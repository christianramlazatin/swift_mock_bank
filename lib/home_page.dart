import 'package:flutter/material.dart';
import 'data/bank_repository.dart';
import 'login_page.dart';
import 'models.dart';
import 'profile_page.dart';
import 'utils/app_formatters.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.repository, required this.onLogout, super.key});

  static const String routeName = '/home';

  final BankRepository repository;
  final VoidCallback onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.repository.getDashboardData();
  }

  void _reload() {
    setState(() {
      _dashboardFuture = widget.repository.getDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _dashboardFuture,
      builder: (BuildContext context, AsyncSnapshot<DashboardData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        if (snapshot.hasError) {
          return _ErrorScaffold(
            message: 'Unable to load dashboard data right now.',
            onRetry: _reload,
          );
        }

        if (!snapshot.hasData) {
          return _ErrorScaffold(
            message: 'No dashboard data available.',
            onRetry: _reload,
          );
        }

        final DashboardData data = snapshot.data!;

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact = constraints.maxWidth < 980;

            if (isCompact) {
              return _MobileHomeScaffold(
                customer: data.customer,
                accounts: data.accounts,
                billers: data.billers,
                transactions: data.transactions,
                totalBalance: data.totalBalance,
                onRefresh: _reload,
                onProfileTap: _openProfileOptions,
                onOpenProfile: _openProfilePage,
              );
            }

            return _DesktopHomeScaffold(
              customer: data.customer,
              accounts: data.accounts,
              billers: data.billers,
              transactions: data.transactions,
              totalBalance: data.totalBalance,
              onRefresh: _reload,
              onProfileTap: _openProfileOptions,
              onOpenProfile: _openProfilePage,
            );
          },
        );
      },
    );
  }

  void _openProfilePage() {
    Navigator.pushNamed(context, ProfilePage.routeName);
  }

  Future<void> _openProfileOptions() async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View Profile'),
                onTap: () => Navigator.pop(context, 'profile'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () => Navigator.pop(context, 'logout'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == 'profile') {
      Navigator.pushNamed(context, ProfilePage.routeName);
      return;
    }

    if (action == 'logout') {
      _logout();
    }
  }

  void _logout() {
    widget.onLogout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.routeName,
      (Route<dynamic> route) => false,
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopHomeScaffold extends StatelessWidget {
  const _DesktopHomeScaffold({
    required this.customer,
    required this.accounts,
    required this.billers,
    required this.transactions,
    required this.totalBalance,
    required this.onRefresh,
    required this.onProfileTap,
    required this.onOpenProfile,
  });

  final Customer customer;
  final List<BankAccount> accounts;
  final List<Biller> billers;
  final List<BankTransaction> transactions;
  final double totalBalance;
  final VoidCallback onRefresh;
  final VoidCallback onProfileTap;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          _DashboardSidebar(customer: customer, onProfileTap: onProfileTap),
          Expanded(
            child: _DashboardContent(
              customer: customer,
              accounts: accounts,
              billers: billers,
              transactions: transactions,
              totalBalance: totalBalance,
              isCompact: false,
              onRefresh: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHomeScaffold extends StatelessWidget {
  const _MobileHomeScaffold({
    required this.customer,
    required this.accounts,
    required this.billers,
    required this.transactions,
    required this.totalBalance,
    required this.onRefresh,
    required this.onProfileTap,
    required this.onOpenProfile,
  });

  final Customer customer;
  final List<BankAccount> accounts;
  final List<Biller> billers;
  final List<BankTransaction> transactions;
  final double totalBalance;
  final VoidCallback onRefresh;
  final VoidCallback onProfileTap;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swift Bank'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: _DrawerContent(customer: customer, onProfileTap: onProfileTap),
        ),
      ),
      body: _DashboardContent(
        customer: customer,
        accounts: accounts,
        billers: billers,
        transactions: transactions,
        totalBalance: totalBalance,
        isCompact: true,
        onRefresh: onRefresh,
      ),
    );
  }
}

class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar({required this.customer, required this.onProfileTap});

  final Customer customer;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFFD32F2F),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 36),
          Semantics(
            label: 'Swift Bank brand logo',
            image: true,
            child: Image.asset('assets/bank_logo.png', height: 58),
          ),
          const SizedBox(height: 12),
          const Text(
            'BPI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          const _SidebarItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
          ),
          _SidebarItem(icon: Icons.credit_card_outlined, title: 'Cards'),
          const _SidebarItem(
            icon: Icons.swap_horiz_outlined,
            title: 'Transfers',
          ),
          const _SidebarItem(icon: Icons.shield_outlined, title: 'Security'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Tooltip(
              message: 'Open profile options',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onProfileTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: <Widget>[
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Text('👤', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerContent extends StatelessWidget {
  const _DrawerContent({required this.customer, required this.onProfileTap});

  final Customer customer;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: <Widget>[
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFFFF3E0),
            child: Text('👤', style: TextStyle(fontSize: 16)),
          ),
          title: Text(customer.name),
          subtitle: const Text('Tap for options'),
          onTap: () {
            Navigator.pop(context);
            onProfileTap();
          },
        ),
        const Divider(),
        _DrawerItem(
          icon: Icons.dashboard,
          title: 'Dashboard',
          onTap: () => Navigator.pop(context),
        ),
        _DrawerItem(
          icon: Icons.swap_horiz,
          title: 'Transfers',
          onTap: () => Navigator.pop(context),
        ),
        _DrawerItem(
          icon: Icons.shield,
          title: 'Security',
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.customer,
    required this.accounts,
    required this.billers,
    required this.transactions,
    required this.totalBalance,
    required this.isCompact,
    required this.onRefresh,
  });

  final Customer customer;
  final List<BankAccount> accounts;
  final List<Biller> billers;
  final List<BankTransaction> transactions;
  final double totalBalance;
  final bool isCompact;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final String firstName = customer.name.split(' ').first;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DashboardHeader(
                firstName: firstName,
                isCompact: isCompact,
                onRefresh: onRefresh,
              ),
              const SizedBox(height: 18),
              if (isCompact)
                Column(
                  children: <Widget>[
                    _TotalBalanceCard(totalBalance: totalBalance),
                    const SizedBox(height: 18),
                    _AccountsCard(accounts: accounts),
                    const SizedBox(height: 18),
                    _BillersCard(billers: billers),
                    const SizedBox(height: 18),
                    _RecentActivityCard(transactions: transactions),
                  ],
                )
              else
                Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: LayoutBuilder(
                            builder:
                                (
                                  BuildContext context,
                                  BoxConstraints constraints,
                                ) {
                                  final double balanceWidth =
                                      ((constraints.maxWidth - 18) * 0.62)
                                          .clamp(420.0, 620.0)
                                          .toDouble();
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      SizedBox(
                                        width: balanceWidth,
                                        child: _TotalBalanceCard(
                                          totalBalance: totalBalance,
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: _BillersCard(
                                          billers: billers,
                                          compact: true,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _AccountsCard(accounts: accounts)),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _RecentActivityCard(
                            transactions: transactions,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.firstName,
    required this.isCompact,
    required this.onRefresh,
  });

  final String firstName;
  final bool isCompact;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final Widget profileButton = Tooltip(
      message: 'Open customer profile',
      child: FilledButton.icon(
        onPressed: () => Navigator.pushNamed(context, ProfilePage.routeName),
        icon: const Icon(Icons.person_outline),
        label: const Text('View Profile'),
      ),
    );

    final Widget refreshButton = IconButton(
      onPressed: onRefresh,
      tooltip: 'Refresh dashboard data',
      icon: const Icon(Icons.refresh),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Welcome back, $firstName',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              refreshButton,
            ],
          ),
          const SizedBox(height: 12),
          profileButton,
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Welcome back, $firstName',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        refreshButton,
        profileButton,
      ],
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({required this.totalBalance});

  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Total Available Balance',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              AppFormatters.currency(totalBalance),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                Tooltip(
                  message: 'Transfer money between accounts',
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showFeatureSnack(context, 'Transfer Money'),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Transfer'),
                  ),
                ),
                Tooltip(
                  message: 'Pay a utility or merchant bill',
                  child: OutlinedButton.icon(
                    onPressed: () => _showFeatureSnack(context, 'Pay Bills'),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Pay Bills'),
                  ),
                ),
                Tooltip(
                  message: 'Manage payment card controls',
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showFeatureSnack(context, 'Card Controls'),
                    icon: const Icon(Icons.tune),
                    label: const Text('Card Controls'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureSnack(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name is ready for API wiring in this POC.')),
    );
  }
}

class _AccountsCard extends StatelessWidget {
  const _AccountsCard({required this.accounts});

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
            Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
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
                      style: const TextStyle(fontWeight: FontWeight.w700),
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

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.transactions});

  final List<BankTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final List<BankTransaction> sortedTransactions = <BankTransaction>[
      ...transactions,
    ]..sort((BankTransaction a, BankTransaction b) => b.date.compareTo(a.date));
    final double listHeight = (sortedTransactions.length * 86.0).clamp(
      160.0,
      360.0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: listHeight,
              child: ListView.builder(
                itemCount: sortedTransactions.length,
                itemBuilder: (BuildContext context, int index) {
                  final BankTransaction tx = sortedTransactions[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: tx.isCredit
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Icon(
                        tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: tx.isCredit
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    title: Text(tx.title),
                    subtitle: Text(
                      '${tx.category.label} • ${AppFormatters.shortDate(tx.date)}',
                    ),
                    trailing: Text(
                      '${tx.isCredit ? '+' : '-'}${AppFormatters.currency(tx.amount.abs())}',
                      style: TextStyle(
                        color: tx.isCredit
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w700,
                      ),
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

class _BillersCard extends StatelessWidget {
  const _BillersCard({required this.billers, this.compact = false});

  final List<Biller> billers;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final List<Biller> visibleBillers = compact
        ? billers.take(4).toList(growable: false)
        : billers;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Billers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: compact ? 210 : 280,
              child: ListView.separated(
                itemCount: visibleBillers.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final Biller biller = visibleBillers[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _iconForBiller(biller),
                      color: const Color(0xFF0057D9),
                    ),
                    title: Text(biller.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${biller.name} payment flow is ready for wiring.',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForBiller(Biller biller) {
    final String key = '${biller.code} ${biller.name}'.toLowerCase();

    if (key.contains('electric') || key.contains('meralco')) {
      return Icons.bolt_outlined;
    }
    if (key.contains('water') || key.contains('maynilad')) {
      return Icons.water_drop_outlined;
    }
    if (key.contains('telecom') ||
        key.contains('globe') ||
        key.contains('smart') ||
        key.contains('pldt')) {
      return Icons.wifi_outlined;
    }
    if (key.contains('sss') ||
        key.contains('pagibig') ||
        key.contains('government')) {
      return Icons.account_balance_outlined;
    }
    if (key.contains('insurance') || key.contains('health')) {
      return Icons.health_and_safety_outlined;
    }

    return Icons.receipt_long_outlined;
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {},
    );
  }
}
