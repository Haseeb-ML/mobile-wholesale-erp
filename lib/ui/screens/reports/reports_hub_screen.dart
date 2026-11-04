import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/core/services/security_service.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/screens/reports/profit_loss_report_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/reports/stock_valuation_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/sales/invoice_history_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/stock/stock_movement_screen.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final canViewProfit = SecurityService.instance.canViewCostAndProfit(appState.activeRole);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('reports_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (canViewProfit) ...[
            _reportTile(
              context,
              icon: Icons.analytics_outlined,
              iconColor: AppColors.primaryTeal,
              title: context.tr('rep_profit_loss'),
              subtitle: 'Gross Profit, Operating Expenses & Period Net Profit',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfitLossReportScreen())),
            ),
            _reportTile(
              context,
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.info,
              title: context.tr('rep_stock_val'),
              subtitle: 'On-hand quantities, moving avg cost & total valuation (CSV export)',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockValuationScreen())),
            ),
          ],
          _reportTile(
            context,
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.highlightAmberDark,
            title: context.tr('rep_sales_summary'),
            subtitle: 'Complete invoice ledger, payment statuses & customer records',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen())),
          ),
          _reportTile(
            context,
            icon: Icons.history_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Inventory Movement Audit Ledger',
            subtitle: 'Dated trace of purchases, sales, returns, adjustments & damages',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockMovementScreen())),
          ),
        ],
      ),
    );
  }

  Widget _reportTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight),
        ],
      ),
    );
  }
}
