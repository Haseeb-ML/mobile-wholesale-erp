import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/core/services/security_service.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/common/stat_card.dart';
import 'package:mobile_wholesale_erp/ui/screens/cash_bank/add_expense_dialog.dart';
import 'package:mobile_wholesale_erp/ui/screens/parties/party_payment_dialog.dart';
import 'package:mobile_wholesale_erp/ui/screens/purchases/new_purchase_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/sales/new_sale_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final dashboard = context.watch<DashboardProvider>();
    final canViewProfit = SecurityService.instance.canViewCostAndProfit(appState.activeRole);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appState.settings.shopName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Role: ${appState.activeRole.toUpperCase()} • ${appState.settings.phone}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => dashboard.refresh(),
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboard.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo Mode Banner
              if (appState.isDemoMode) _buildDemoBanner(context, appState),

              // Quick Actions Bar
              _buildQuickActions(context),

              const SizedBox(height: 12),

              // Key KPI Metrics Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: context.tr('dashboard_today_sales'),
                            value: dashboard.todayNetSales.format(),
                            icon: Icons.point_of_sale_rounded,
                            iconColor: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            title: context.tr('dashboard_today_receipts'),
                            value: dashboard.todayReceipts.format(),
                            icon: Icons.payments_rounded,
                            iconColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (canViewProfit) ...[
                          Expanded(
                            child: StatCard(
                              title: context.tr('dashboard_gross_profit'),
                              value: dashboard.periodGrossProfit.format(),
                              icon: Icons.trending_up_rounded,
                              iconColor: AppColors.highlightAmberDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: StatCard(
                            title: context.tr('dashboard_cash_balance'),
                            value: dashboard.totalCashAndBank.format(),
                            subtitle: 'Cash: ${dashboard.cashBalance.format()} | Bank: ${dashboard.bankBalance.format()}',
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: context.tr('dashboard_customer_due'),
                            value: dashboard.customerOutstanding.format(),
                            subtitle: 'Receivables from dealers',
                            icon: Icons.group_rounded,
                            iconColor: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            title: context.tr('dashboard_supplier_due'),
                            value: dashboard.supplierOutstanding.format(),
                            subtitle: 'Payables to suppliers',
                            icon: Icons.inventory_2_rounded,
                            iconColor: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 7-Day Sales Trend Chart
              _buildSalesChartCard(context, dashboard),

              const SizedBox(height: 16),

              // Recent Invoices
              _buildRecentInvoices(context, dashboard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoBanner(BuildContext context, AppState appState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.demoBannerBg,
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.demoBannerText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('demo_mode_banner'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.demoBannerText,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Demo Data?'),
                  content: const Text('This will reset all demo accessories, customer ledgers, and transactions back to the original seed state.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset Demo')),
                  ],
                ),
              );
              if (confirmed == true) {
                await appState.resetDemoData();
                if (context.mounted) {
                  await context.read<DashboardProvider>().refresh();
                }
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              foregroundColor: AppColors.demoBannerText,
            ),
            child: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('dashboard_quick_actions'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.headingNavy,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickActionButton(
                context,
                icon: Icons.add_shopping_cart_rounded,
                label: context.tr('action_new_sale'),
                color: AppColors.primaryTeal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewSaleScreen())),
              ),
              _quickActionButton(
                context,
                icon: Icons.receipt_long_rounded,
                label: context.tr('action_new_purchase'),
                color: AppColors.info,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewPurchaseScreen())),
              ),
              _quickActionButton(
                context,
                icon: Icons.call_received_rounded,
                label: context.tr('action_receive_payment'),
                color: AppColors.success,
                onTap: () => PartyPaymentDialog.show(context, isCustomerReceipt: true),
              ),
              _quickActionButton(
                context,
                icon: Icons.call_made_rounded,
                label: context.tr('action_pay_supplier'),
                color: AppColors.warning,
                onTap: () => PartyPaymentDialog.show(context, isCustomerReceipt: false),
              ),
              _quickActionButton(
                context,
                icon: Icons.money_off_rounded,
                label: context.tr('action_add_expense'),
                color: AppColors.highlightAmberDark,
                onTap: () => AddExpenseDialog.show(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.headingNavy,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChartCard(BuildContext context, DashboardProvider dashboard) {
    final trend = dashboard.salesTrend;
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxSalePaisa = trend.fold<int>(1, (max, e) => e.salesPaisa > max ? e.salesPaisa : max);
    final maxSalePkr = (maxSalePaisa / 100.0);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('dashboard_sales_trend'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.headingNavy),
              ),
              const Text('PKR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxSalePkr * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = trend[group.x.toInt()];
                      return BarTooltipItem(
                        '${item.dateLabel}\nPKR ${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text(
                          val >= 1000 ? '${(val / 1000).toStringAsFixed(0)}K' : val.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < trend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(trend[idx].dateLabel, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.dividerLight, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: trend.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final pkr = item.salesPaisa / 100.0;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: pkr,
                        color: AppColors.primaryTeal,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices(BuildContext context, DashboardProvider dashboard) {
    final list = dashboard.recentInvoices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('dashboard_recent_sales'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.headingNavy),
              ),
              Text(
                '${list.length} Invoices',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No sales posted yet.', style: TextStyle(color: AppColors.textMuted))),
          )
        else
          ...list.map((inv) {
            return CustomCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_rounded, size: 20, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.customerName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.headingNavy),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${inv.invoiceNumber} • ${inv.date}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        inv.grandTotal.format(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.headingNavy),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: inv.duePaisa == 0 ? AppColors.successLight : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          inv.duePaisa == 0 ? 'PAID' : 'DUE: ${inv.due.format()}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: inv.duePaisa == 0 ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
