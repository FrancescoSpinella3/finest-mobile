import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/utils/currency_formatter.dart';
import '../auth/auth_provider.dart';
import '../settings/settings_screen.dart';
import 'widgets/monthly_chart.dart';
import 'widgets/recent_transactions_widget.dart';
import 'widgets/recent_subscriptions_widget.dart';
import 'widgets/goals_summary_widget.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgMain : AppColors.lightBgMain;
    final now = DateTime.now();
    final rawMonthLabel = DateFormat('MMMM yyyy', 'it_IT').format(now);
    final monthLabel =
        rawMonthLabel[0].toUpperCase() + rawMonthLabel.substring(1);
    final monthBalance = data.currentMonthIncome -
        data.currentMonthExpenses -
        data.currentMonthSavings;

    final profile = auth.profile;
    final firstName = profile?['name']?.toString() ?? '';
    final lastName = profile?['lastName']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final avatarUrl = profile?['profileImage']?.toString();
    final initials = firstName.isNotEmpty
        ? (firstName[0] + (lastName.isNotEmpty ? lastName[0] : ''))
            .toUpperCase()
        : 'U';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      endDrawer: _SideDrawer(
        fullName: fullName.isNotEmpty ? fullName : 'Utente',
        email: auth.user?.email ?? '',
        initials: initials,
        avatarUrl: avatarUrl,
      ),
      body: data.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {},
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 72,
                    titleSpacing: 16,
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bentornato, ${firstName.isNotEmpty ? firstName : 'Utente'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Panoramica',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    actions: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.only(left: 12, right: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBgCard : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: AppColors.mainBlue,
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Text(
                                        initials,
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Net Worth Card ──────────────────────────────────
                        _NetWorthCard(data: data),
                        const SizedBox(height: 16),

                        // ── Monthly Summary ─────────────────────────────────
                        _SectionTitle(title: monthLabel),
                        const SizedBox(height: 10),
                        _MonthlySummaryRow(
                          income: data.currentMonthIncome,
                          expenses: data.currentMonthExpenses,
                          savings: data.currentMonthSavings,
                          balance: monthBalance,
                        ),
                        const SizedBox(height: 16),

                        // ── 6-Month Chart ───────────────────────────────────
                        const _SectionTitle(title: 'Ultimi 6 mesi'),
                        const SizedBox(height: 10),
                        MonthlyChart(monthlyData: data.monthlyData),
                        const SizedBox(height: 16),

                        // ── Recent Transactions ─────────────────────────────
                        const _SectionTitle(title: 'Transazioni recenti'),
                        const SizedBox(height: 10),
                        RecentTransactionsWidget(
                          transactions: data.transactions.toList()
                            ..sort((a, b) => b.date.compareTo(a.date)),
                          categories: data.categories,
                        ),
                        const SizedBox(height: 16),

                        // ── Goals Summary ───────────────────────────────────
                        const _SectionTitle(title: 'Obiettivi'),
                        const SizedBox(height: 10),
                        GoalsSummaryWidget(
                          goals: data.goals,
                          computeProgress: data.computeGoalProgress,
                        ),
                        const SizedBox(height: 16),

                        // ── Recent Subscriptions ────────────────────────────
                        const _SectionTitle(title: 'Abbonamenti recenti'),
                        const SizedBox(height: 10),
                        RecentSubscriptionsWidget(
                          subscriptions: data.subscriptions,
                          categories: data.categories,
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SideDrawer extends StatelessWidget {
  final String fullName;
  final String email;
  final String initials;
  final String? avatarUrl;

  const _SideDrawer({
    required this.fullName,
    required this.email,
    required this.initials,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? AppColors.darkBgContainer : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.mainBlue,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? Text(
                            initials,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined,
                  color: AppColors.mainBlue),
              title: const Text('Impostazioni'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  final DataProvider data;
  const _NetWorthCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071A4A), AppColors.secondBlue, Color(0xFF7EC8FF)],
          stops: [0.0, 0.75, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _FinanceTexturePainter()),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PATRIMONIO NETTO',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(data.netWorth),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          label: 'Entrate',
                          value: formatCurrencyCompact(data.totalIncome),
                          color: const Color(0xFF6EE7B7),
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          label: 'Uscite',
                          value: formatCurrencyCompact(data.totalExpenses),
                          color: const Color(0xFFFCA5A5),
                          icon: Icons.trending_down_rounded,
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          label: 'Risparmi',
                          value: formatCurrencyCompact(data.totalSavings),
                          color: const Color(0xFFFDE68A),
                          icon: Icons.savings_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FinanceTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(size.width * 0.08, size.height * 0.92),
      Offset(size.width * 0.20, size.height * 0.80),
      Offset(size.width * 0.32, size.height * 0.84),
      Offset(size.width * 0.44, size.height * 0.66),
      Offset(size.width * 0.55, size.height * 0.70),
      Offset(size.width * 0.66, size.height * 0.54),
      Offset(size.width * 0.77, size.height * 0.48),
      Offset(size.width * 0.88, size.height * 0.38),
      Offset(size.width * 1.02, size.height * 0.28),
    ];

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MonthlySummaryRow extends StatelessWidget {
  final double income;
  final double expenses;
  final double savings;
  final double balance;

  const _MonthlySummaryRow({
    required this.income,
    required this.expenses,
    required this.savings,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color.fromARGB(255, 28, 32, 44)
        : AppColors.lightBgContainer;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _MonthlyItem(
                  label: 'Entrate',
                  value: income,
                  color: AppColors.incomeColor),
              _MonthlyItem(
                  label: 'Uscite',
                  value: expenses,
                  color: AppColors.expenseColor),
              _MonthlyItem(
                  label: 'Risparmi',
                  value: savings,
                  color: AppColors.savingColor),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo mensile',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                formatCurrency(balance),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color:
                      balance >= 0 ? AppColors.incomeColor : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MonthlyItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrencyCompact(value),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
