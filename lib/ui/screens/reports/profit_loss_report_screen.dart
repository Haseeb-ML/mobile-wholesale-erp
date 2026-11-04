import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/providers/report_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';

class ProfitLossReportScreen extends StatefulWidget {
  const ProfitLossReportScreen({super.key});

  @override
  State<ProfitLossReportScreen> createState() => _ProfitLossReportScreenState();
}

class _ProfitLossReportScreenState extends State<ProfitLossReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadProfitLoss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = context.watch<ReportProvider>();
    final pl = reportProv.profitLoss;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss Statement'),
      ),
      body: reportProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Revenue (Wholesale)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                  const SizedBox(height: 8),
                  CustomCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _item('Gross Sales Revenue', pl.totalSales.format()),
                        if (pl.totalSalesReturnsPaisa > 0)
                          _item('Less: Customer Sales Returns', '- ${pl.totalSalesReturns.format()}'),
                        const Divider(),
                        _item('Net Wholesale Sales', pl.netSales.format(), isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Cost of Goods Sold (COGS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                  const SizedBox(height: 8),
                  CustomCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _item('Cost of Goods Sold (Moving Avg)', pl.cogs.format()),
                        const Divider(),
                        _item(
                          'Gross Profit',
                          pl.grossProfit.format(),
                          isBold: true,
                          color: pl.grossProfitPaisa >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Operating Expenses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                  const SizedBox(height: 8),
                  CustomCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _item('Total Shop Operating Expenses', pl.totalExpenses.format()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Net Profit Bottom Line Card
                  CustomCard(
                    margin: EdgeInsets.zero,
                    color: pl.netProfitPaisa >= 0 ? AppColors.successLight : AppColors.errorLight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PERIOD NET PROFIT',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.headingNavy),
                            ),
                            Text(
                              pl.netProfitPaisa >= 0 ? 'Net Operating Surplus' : 'Net Operating Loss',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        Text(
                          pl.netProfit.format(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: pl.netProfitPaisa >= 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Basis of Accounting:\n• Moving weighted-average cost snapshotted at time of sale.\n• Gross Profit = Net Sales - COGS.\n• Net Profit = Gross Profit - Shop Operating Expenses.\n• Purchase inventory and cash receipts/payments do not alter profit.',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _item(String label, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
