import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/core/utils/money.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';

class DailySalesTrend {
  final String dateLabel;
  final int salesPaisa;

  DailySalesTrend(this.dateLabel, this.salesPaisa);
}

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;

  int _todayNetSalesPaisa = 0;
  int _todayReceiptsPaisa = 0;
  int _periodGrossProfitPaisa = 0;
  int _customerOutstandingPaisa = 0;
  int _supplierOutstandingPaisa = 0;
  int _cashBalancePaisa = 0;
  int _bankBalancePaisa = 0;
  int _lowStockCount = 0;

  List<Invoice> _recentInvoices = [];
  List<DailySalesTrend> _salesTrend = [];

  bool get isLoading => _isLoading;

  Money get todayNetSales => Money(_todayNetSalesPaisa);
  Money get todayReceipts => Money(_todayReceiptsPaisa);
  Money get periodGrossProfit => Money(_periodGrossProfitPaisa);
  Money get customerOutstanding => Money(_customerOutstandingPaisa);
  Money get supplierOutstanding => Money(_supplierOutstandingPaisa);
  Money get cashBalance => Money(_cashBalancePaisa);
  Money get bankBalance => Money(_bankBalancePaisa);
  Money get totalCashAndBank => Money(_cashBalancePaisa + _bankBalancePaisa);
  int get lowStockCount => _lowStockCount;

  List<Invoice> get recentInvoices => _recentInvoices;
  List<DailySalesTrend> get salesTrend => _salesTrend;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().split('T').first;

      // 1. Today's Net Sales
      final todaySalesResult = await db.rawQuery(
        'SELECT SUM(grand_total_paisa - tax_paisa) as net_sales FROM invoices WHERE date = ? AND status = ?',
        [todayStr, 'posted'],
      );
      _todayNetSalesPaisa = (todaySalesResult.first['net_sales'] as int?) ?? 0;

      // 2. Today's Receipts
      final todayReceiptsResult = await db.rawQuery(
        'SELECT SUM(amount_paisa) as total_receipts FROM party_payments WHERE date = ? AND payment_type = ?',
        [todayStr, 'customerReceipt'],
      );
      final salePaidResult = await db.rawQuery(
        'SELECT SUM(paid_paisa) as cash_sales FROM invoices WHERE date = ? AND status = ?',
        [todayStr, 'posted'],
      );
      _todayReceiptsPaisa = ((todayReceiptsResult.first['total_receipts'] as int?) ?? 0) +
          ((salePaidResult.first['cash_sales'] as int?) ?? 0);

      // 3. Gross Profit (Net sales minus COGS)
      final profitResult = await db.rawQuery(
        'SELECT SUM((grand_total_paisa - tax_paisa) - total_cost_paisa) as gross_profit FROM invoices WHERE status = ?',
        ['posted'],
      );
      _periodGrossProfitPaisa = (profitResult.first['gross_profit'] as int?) ?? 0;

      // 4. Customer Outstanding (Total positive balance of customers)
      final custBalResult = await db.rawQuery(
        'SELECT SUM(current_balance_paisa) as outstanding FROM parties WHERE type = ? AND current_balance_paisa > 0 AND is_active = 1',
        ['customer'],
      );
      _customerOutstandingPaisa = (custBalResult.first['outstanding'] as int?) ?? 0;

      // 5. Supplier Outstanding (Total positive balance owed to suppliers)
      final suppBalResult = await db.rawQuery(
        'SELECT SUM(current_balance_paisa) as outstanding FROM parties WHERE type = ? AND current_balance_paisa > 0 AND is_active = 1',
        ['supplier'],
      );
      _supplierOutstandingPaisa = (suppBalResult.first['outstanding'] as int?) ?? 0;

      // 6. Cash and Bank Balances
      final cashRow = await db.query('financial_accounts', where: 'id = ?', whereArgs: ['cash']);
      final bankRow = await db.query('financial_accounts', where: 'id = ?', whereArgs: ['bank']);
      _cashBalancePaisa = cashRow.isNotEmpty ? ((cashRow.first['balance_paisa'] as int?) ?? 0) : 0;
      _bankBalancePaisa = bankRow.isNotEmpty ? ((bankRow.first['balance_paisa'] as int?) ?? 0) : 0;

      // 7. Low Stock Count
      final lowStockResult = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM products WHERE current_stock_pieces <= reorder_level AND is_active = 1',
      );
      _lowStockCount = (lowStockResult.first['cnt'] as int?) ?? 0;

      // 8. Recent 5 Invoices
      final invRows = await db.query(
        'invoices',
        where: 'status = ?',
        whereArgs: ['posted'],
        orderBy: 'date DESC, id DESC',
        limit: 5,
      );
      _recentInvoices = invRows.map((e) => Invoice.fromMap(e)).toList();

      // 9. 7-Day Sales Trend
      final now = DateTime.now();
      final List<DailySalesTrend> trend = [];
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dStr = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final dayLabel = '${d.day}/${d.month}';

        final dayRes = await db.rawQuery(
          'SELECT SUM(grand_total_paisa - tax_paisa) as day_sales FROM invoices WHERE date = ? AND status = ?',
          [dStr, 'posted'],
        );
        final daySales = (dayRes.first['day_sales'] as int?) ?? 0;
        trend.add(DailySalesTrend(dayLabel, daySales));
      }
      _salesTrend = trend;
    } catch (e) {
      debugPrint('Error updating dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
