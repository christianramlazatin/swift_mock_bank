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
                onLogout: _logout,
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
              onOpenProfile: onOpenProfile,
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
    required this.onLogout,
  });

  final Customer customer;
  final List<BankAccount> accounts;
  final List<Biller> billers;
  final List<BankTransaction> transactions;
  final double totalBalance;
  final VoidCallback onRefresh;
  final VoidCallback onProfileTap;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GCash'),
        backgroundColor: const Color(0xFF0057D9),
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            onPressed: onOpenProfile,
            tooltip: 'Open profile',
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: _DrawerContent(
            customer: customer,
            onProfileTap: onProfileTap,
            onLogoutTap: onLogout,
          ),
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
        onOpenProfile: onOpenProfile,
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
      color: const Color(0xFF0057D9),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 36),
          Semantics(
            label: 'GCash brand logo',
            image: true,
            child: Image.asset('assets/bank_logo.png', height: 58),
          ),
          const SizedBox(height: 12),
          const Text(
            'GCash',
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
          const _SidebarItem(icon: Icons.credit_card_outlined, title: 'Cards'),
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
  const _DrawerContent({
    required this.customer,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  final Customer customer;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

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
          icon: Icons.dashboard_outlined,
          title: 'Dashboard',
          onTap: () => Navigator.pop(context),
        ),
        _DrawerItem(
          icon: Icons.credit_card_outlined,
          title: 'Cards',
          onTap: () => Navigator.pop(context),
        ),
        _DrawerItem(
          icon: Icons.swap_horiz_outlined,
          title: 'Transfers',
          onTap: () => Navigator.pop(context),
        ),
        _DrawerItem(
          icon: Icons.shield_outlined,
          title: 'Security',
          onTap: () => Navigator.pop(context),
        ),
        _DrawerItem(
          icon: Icons.logout,
          title: 'Logout',
          onTap: () {
            Navigator.pop(context);
            onLogoutTap();
          },
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
    required this.onOpenProfile,
  });

  final Customer customer;
  final List<BankAccount> accounts;
  final List<Biller> billers;
  final List<BankTransaction> transactions;
  final double totalBalance;
  final bool isCompact;
  final VoidCallback onRefresh;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 0 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _WalletHero(
                balance: totalBalance,
                onRefresh: onRefresh,
                onOpenProfile: onOpenProfile,
              ),
              const SizedBox(height: 16),
              _QuickActionsGrid(
                onActionTap: (String actionName) =>
                    _showFeatureSnack(context, actionName),
              ),
              const SizedBox(height: 12),
              _FlatSection(
                title: 'Accounts',
                child: _AccountsList(accounts: accounts),
              ),
              const SizedBox(height: 12),
              _FlatSection(
                title: 'Recent Activity',
                child: _RecentActivityList(transactions: transactions),
              ),
              const SizedBox(height: 12),
              _FlatSection(
                title: 'Billers',
                child: _BillersList(billers: billers),
              ),
            ],
          ),
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

class _WalletHero extends StatelessWidget {
  const _WalletHero({
    required this.balance,
    required this.onRefresh,
    required this.onOpenProfile,
  });

  final double balance;
  final VoidCallback onRefresh;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(color: Color(0xFF0057D9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onOpenProfile,
                tooltip: 'Open profile',
                icon: const Icon(Icons.person_outline, color: Colors.white),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'Refresh dashboard data',
                icon: const Icon(Icons.refresh_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  AppFormatters.currency(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cash In is ready for API wiring in this POC.',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  foregroundColor: Colors.white,
                ),
                child: const Icon(Icons.add_outlined, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.onActionTap});

  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    const List<({String label, IconData icon})> actions =
        <({String label, IconData icon})>[
          (label: 'Cash In', icon: Icons.add_card_outlined),
          (label: 'Send Money', icon: Icons.send_outlined),
          (label: 'Save', icon: Icons.savings_outlined),
          (label: 'Buy Load', icon: Icons.sim_card_outlined),
          (label: 'Rewards', icon: Icons.card_giftcard_outlined),
          (label: 'Credit', icon: Icons.credit_score_outlined),
          (label: 'Pay Bills', icon: Icons.receipt_long_outlined),
          (label: 'Bank Transfer', icon: Icons.account_balance_outlined),
        ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: GridView.builder(
        itemCount: actions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.05,
        ),
        itemBuilder: (BuildContext context, int index) {
          final ({String label, IconData icon}) action = actions[index];

          return InkWell(
            onTap: () => onActionTap(action.label),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(action.icon, color: const Color(0xFF0057D9), size: 30),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3D4048),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlatSection extends StatelessWidget {
  const _FlatSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF353943),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.accounts});

  final List<BankAccount> accounts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: accounts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final BankAccount account = accounts[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: const Icon(
            Icons.account_balance_wallet_outlined,
            color: Color(0xFF0057D9),
          ),
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
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.transactions});

  final List<BankTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: transactions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final BankTransaction tx = transactions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: const Icon(
            Icons.receipt_long_outlined,
            color: Color(0xFF0057D9),
          ),
          title: Text(tx.title),
          subtitle: Text(
            '${tx.category.label} • ${AppFormatters.shortDate(tx.date)}',
          ),
          trailing: Text(
            '${tx.isCredit ? '+' : '-'}${AppFormatters.currency(tx.amount.abs())}',
            style: TextStyle(
              color: tx.isCredit
                  ? const Color(0xFF0F9D58)
                  : const Color(0xFFB3261E),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _BillersList extends StatelessWidget {
  const _BillersList({required this.billers});

  final List<Biller> billers;

  @override
  Widget build(BuildContext context) {
    final List<Biller> visible = billers.take(6).toList(growable: false);

    return ListView.separated(
      itemCount: visible.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Biller biller = visible[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: const Icon(
            Icons.receipt_long_outlined,
            color: Color(0xFF0057D9),
          ),
          title: Text(biller.name),
          subtitle: Text('Code: ${biller.code}'),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${biller.name} is ready for bill payment wiring.',
                ),
              ),
            );
          },
        );
      },
    );
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
