import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/core/utils/money.dart';
import 'package:mobile_wholesale_erp/models/account.dart';
import 'package:mobile_wholesale_erp/models/product.dart';

class ProfitLossReport {
  final int totalSalesPaisa;
  final int totalSalesReturnsPaisa;
  final int netSalesPaisa; // totalSales - returns
  final int cogsPaisa;
  final int grossProfitPaisa; // netSales - cogs
  final int totalExpensesPaisa;
  final int netProfitPaisa; // grossProfit - totalExpenses

  ProfitLossReport({
    required this.totalSalesPaisa,
    required this.totalSalesReturnsPaisa,
    required this.netSalesPaisa,
    required this.cogsPaisa,
    required this.grossProfitPaisa,
    required this.totalExpensesPaisa,
    required this.netProfitPaisa,
  });

  Money get totalSales => Money(totalSalesPaisa);
  Money get totalSalesReturns => Money(totalSalesReturnsPaisa);
  Money get netSales => Money(netSalesPaisa);
  Money get cogs => Money(cogsPaisa);
  Money get grossProfit => Money(grossProfitPaisa);
  Money get totalExpenses => Money(totalExpensesPaisa);
  Money get netProfit => Money(netProfitPaisa);
}

class StockValuationSummary {
  final int totalItems;
  final int totalPiecesOnHand;
  final int totalDamagedPieces;
  final int totalInventoryValuationPaisa;

  StockValuationSummary({
    required this.totalItems,
    required this.totalPiecesOnHand,
    required this.totalDamagedPieces,
    required this.totalInventoryValuationPaisa,
  });

  Money get totalValuation => Money(totalInventoryValuationPaisa);
}

class ReportProvider extends ChangeNotifier {
  bool _isLoading = false;

  ProfitLossReport _profitLoss = ProfitLossReport(
    totalSalesPaisa: 0,
    totalSalesReturnsPaisa: 0,
    netSalesPaisa: 0,
    cogsPaisa: 0,
    grossProfitPaisa: 0,
    totalExpensesPaisa: 0,
    netProfitPaisa: 0,
  );

  StockValuationSummary _stockValuation = StockValuationSummary(
    totalItems: 0,
    totalPiecesOnHand: 0,
    totalDamagedPieces: 0,
    totalInventoryValuationPaisa: 0,
  );

  List<Product> _stockReportItems = [];
  List<AccountTransaction> _cashbookTransactions = [];

  bool get isLoading => _isLoading;
  ProfitLossReport get profitLoss => _profitLoss;
  StockValuationSummary get stockValuation => _stockValuation;
  List<Product> get stockReportItems => _stockReportItems;
  List<AccountTransaction> get cashbookTransactions => _cashbookTransactions;

  Future<void> loadProfitLoss() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Total Sales
      final salesRes = await db.rawQuery(
        'SELECT SUM(grand_total_paisa - tax_paisa) as sales, SUM(total_cost_paisa) as cogs FROM invoices WHERE status = ?',
        ['posted'],
      );
      final rawSales = (salesRes.first['sales'] as int?) ?? 0;
      final cogs = (salesRes.first['cogs'] as int?) ?? 0;

      // 2. Total Sales Returns
      final returnRes = await db.rawQuery(
        'SELECT SUM(total_credit_paisa) as returns FROM return_orders WHERE return_type = ?',
        ['salesReturn'],
      );
      final rawReturns = (returnRes.first['returns'] as int?) ?? 0;

      final netSales = rawSales - rawReturns;
      final grossProfit = netSales - cogs;

      // 3. Expenses
      final expRes = await db.rawQuery('SELECT SUM(amount_paisa) as total_expenses FROM expenses');
      final totalExpenses = (expRes.first['total_expenses'] as int?) ?? 0;

      final netProfit = grossProfit - totalExpenses;

      _profitLoss = ProfitLossReport(
        totalSalesPaisa: rawSales,
        totalSalesReturnsPaisa: rawReturns,
        netSalesPaisa: netSales,
        cogsPaisa: cogs,
        grossProfitPaisa: grossProfit,
        totalExpensesPaisa: totalExpenses,
        netProfitPaisa: netProfit,
      );
    } catch (e) {
      debugPrint('Error loading P&L: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStockValuationReport() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('products', where: 'is_active = 1', orderBy: 'category ASC, name ASC');
      _stockReportItems = rows.map((e) => Product.fromMap(e)).toList();

      int totalPieces = 0;
      int totalDamaged = 0;
      int totalValuationPaisa = 0;

      for (final p in _stockReportItems) {
        totalPieces += p.currentStockPieces;
        totalDamaged += p.damagedStockPieces;
        totalValuationPaisa += (p.currentStockPieces * p.costPricePaisa);
      }

      _stockValuation = StockValuationSummary(
        totalItems: _stockReportItems.length,
        totalPiecesOnHand: totalPieces,
        totalDamagedPieces: totalDamaged,
        totalInventoryValuationPaisa: totalValuationPaisa,
      );
    } catch (e) {
      debugPrint('Error loading stock valuation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCashbookTransactions(String accountId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'account_transactions',
        where: 'account_id = ?',
        whereArgs: [accountId],
        orderBy: 'date DESC, id DESC',
      );
      _cashbookTransactions = rows.map((e) => AccountTransaction.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error loading cashbook: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export Stock Valuation as CSV file
  Future<void> exportStockCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('SKU,Product Name,Category,Pieces per Box,Cost (PKR),Wholesale (PKR),Available Stock (Pcs),Inventory Valuation (PKR)');

    for (final p in _stockReportItems) {
      final valPkr = (p.currentStockPieces * p.costPricePaisa) / 100.0;
      buffer.writeln('"${p.sku}","${p.name}","${p.category}",${p.piecesPerBox},${p.costPrice.toPkr},${p.wholesalePrice.toPkr},${p.currentStockPieces},$valPkr');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final csvPath = p.join(appDocDir.path, 'stock_valuation_${DateTime.now().millisecondsSinceEpoch}.csv');
    final file = File(csvPath);
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(csvPath)],
      subject: 'Stock Valuation Report (CSV)',
    );
  }
}
