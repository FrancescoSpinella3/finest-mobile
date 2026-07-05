import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/overview/overview_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    OverviewScreen(),
    TransactionsScreen(),
    SubscriptionsScreen(),
    GoalsScreen(),
    CategoriesScreen(),
  ];

  static const List<_NavItem> _items = [
    _NavItem(Icons.grid_view_outlined, 'Home'),
    _NavItem(Icons.swap_horiz_rounded, 'Transazioni'),
    _NavItem(Icons.credit_card_rounded, 'Abbonamenti'),
    _NavItem(Icons.track_changes_rounded, 'Obiettivi'),
    _NavItem(Icons.sell_outlined, 'Categorie'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgBar : AppColors.lightBgBar,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_items.length, (i) {
                final selected = i == _currentIndex;
                final item = _items[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: selected
                        ? const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10)
                        : const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.mainBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i == 0)
                          _RoundedGridIcon(
                            size: 20,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          )
                        else
                          Icon(
                            item.icon,
                            size: 26,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedGridIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _RoundedGridIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RoundedGridPainter(color: color),
    );
  }
}

class _RoundedGridPainter extends CustomPainter {
  final Color color;

  _RoundedGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12;
    final gap = size.width * 0.20;
    final boxSize = (size.width - gap) / 2;
    final radius = Radius.circular(boxSize * 0.35);

    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        final rect = Rect.fromLTWH(
          col * (boxSize + gap),
          row * (boxSize + gap),
          boxSize,
          boxSize,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoundedGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
