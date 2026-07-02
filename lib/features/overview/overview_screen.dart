import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/utils/currency_formatter.dart';
import 'widgets/monthly_chart.dart';
import 'widgets/recent_transactions_widget.dart';
import 'widgets/recent_subscriptions_widget.dart';
import 'widgets/goals_summary_widget.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgMain : AppColors.lightBgMain;
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy', 'it_IT').format(now);
    final monthBalance = data.currentMonthIncome -
        data.currentMonthExpenses -
        data.currentMonthSavings;

    return Scaffold(
      backgroundColor: bgColor,
      body: data.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {},
              child: CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    pinned: true,
                    expandedHeight: 0,
                    title: Text('Panoramica'),
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
                      fontWeight: FontWeight.w700,
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
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w700,
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
