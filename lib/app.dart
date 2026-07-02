import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/overview/overview_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/providers/data_provider.dart';
import 'shared/providers/theme_provider.dart';

class FinestApp extends StatelessWidget {
  const FinestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Finest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      locale: const Locale('it', 'IT'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) {
      // Clear data when logged out
      if (_lastUserId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<DataProvider>().clear();
        });
        _lastUserId = null;
      }
      return const AuthScreen();
    }

    // Load data when user logs in
    if (_lastUserId != auth.user!.id) {
      _lastUserId = auth.user!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DataProvider>().loadAll(auth.user!.id);
      });
    }

    return const _MainShell();
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    OverviewScreen(),
    TransactionsScreen(),
    SubscriptionsScreen(),
    CategoriesScreen(),
    GoalsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 8),
            ),
          ),
        ),
        child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Panoramica',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Transazioni',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_rounded),
            label: 'Abbonamenti',
          ),
          NavigationDestination(
            icon: Icon(Icons.label_outline),
            label: 'Categorie',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_rounded),
            label: 'Obiettivi',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Impostazioni',
          ),
        ],
      ),
      ),
    );
  }
}
