import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/models/account.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/screens/cash_bank/add_expense_dialog.dart';
import 'package:mobile_wholesale_erp/ui/screens/cash_bank/transfer_dialog.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<AccountTransaction> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('account_transactions', orderBy: 'date DESC, id DESC', limit: 50);
      _recentTransactions = rows.map((e) => AccountTransaction.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error loading account transactions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash & Bank Accounts'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cash in Shop Card
            CustomCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primaryTealLight, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.money_rounded, color: AppColors.primaryTeal),
                          ),
                          const SizedBox(width: 10),
                          const Text('Cash in Shop (Counter)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        dashboard.cashBalance.format(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.headingNavy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Meezan Bank Account Card
            CustomCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.account_balance_rounded, color: AppColors.info),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Meezan Bank Limited', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('A/C: 0101-0102030405', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        dashboard.bankBalance.format(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.headingNavy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => TransferDialog.show(context).then((_) => _loadTransactions()),
                    icon: const Icon(Icons.sync_alt_rounded),
                    label: const Text('Transfer Funds'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => AddExpenseDialog.show(context).then((_) => _loadTransactions()),
                    icon: const Icon(Icons.money_off_rounded),
                    label: const Text('Record Expense'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Movement List
            const Text('Recent Money Movements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_recentTransactions.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No transactions yet.')))
            else
              ..._recentTransactions.map((t) {
                final isIn = t.debitPaisa > 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isIn ? AppColors.successLight : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isIn ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 16,
                          color: isIn ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.notes ?? t.type.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('${t.accountId.toUpperCase()} • ${t.date}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isIn ? '+ ${t.debit.format()}' : '- ${t.credit.format()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isIn ? AppColors.success : AppColors.error,
                            ),
                          ),
                          Text('Bal: ${t.runningBalance.format()}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
