import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/models/expense.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/models/purchase.dart';
import 'package:mobile_wholesale_erp/models/return_order.dart';
import 'package:mobile_wholesale_erp/models/stock_adjustment.dart';

class InsufficientStockException implements Exception {
  final String sku;
  final String name;
  final int available;
  final int requested;

  InsufficientStockException(this.sku, this.name, this.available, this.requested);

  @override
  String toString() => 'Insufficient stock for $name ($sku). Available: $available, Requested: $requested';
}

class InsufficientFundsException implements Exception {
  final String account;
  final int currentBalancePaisa;
  final int requestedPaisa;

  InsufficientFundsException(this.account, this.currentBalancePaisa, this.requestedPaisa);

  @override
  String toString() => 'Insufficient balance in $account. Available: PKR ${(currentBalancePaisa / 100).toStringAsFixed(2)}, Required: PKR ${(requestedPaisa / 100).toStringAsFixed(2)}';
}

class AccountingService {
  static final AccountingService instance = AccountingService._internal();
  AccountingService._internal();

  DatabaseHelper get _dbHelper => DatabaseHelper.instance;

  Future<int> _ensureAccountBalance(dynamic executor, String accountId, {int delta = 0}) async {
    final rows = await executor.query('financial_accounts', where: 'id = ?', whereArgs: [accountId]);
    if (rows.isEmpty) {
      final name = accountId == 'bank' ? 'Bank Account (Meezan/HBL)' : 'Cash in Shop';
      await executor.rawInsert(
        'INSERT OR IGNORE INTO financial_accounts (id, name, type, balance_paisa) VALUES (?, ?, ?, 0)',
        [accountId, name, accountId],
      );
    }
    if (delta != 0) {
      await executor.rawUpdate(
        'UPDATE financial_accounts SET balance_paisa = balance_paisa + ? WHERE id = ?',
        [delta, accountId],
      );
    }
    final updated = await executor.query('financial_accounts', where: 'id = ?', whereArgs: [accountId]);
    return updated.isNotEmpty ? ((updated.first['balance_paisa'] as int?) ?? 0) : 0;
  }

  // -------------------------------------------------------------
  // 1. POSTING SALES INVOICES (ATOMIC)
  // -------------------------------------------------------------
  Future<int> postSaleInvoice(Invoice invoice, {String userRole = 'owner'}) async {
    final db = await _dbHelper.database;

    return await db.transaction<int>((txn) async {
      // 1. Group requested pieces by product ID to prevent multi-line stock bypass
      final Map<int, int> productPiecesRequested = {};
      for (final item in invoice.items) {
        productPiecesRequested[item.productId] =
            (productPiecesRequested[item.productId] ?? 0) + item.totalPieces;
      }

      // 2. Validate stock availability and lock current moving average cost
      final Map<int, Product> productSnapshots = {};
      for (final entry in productPiecesRequested.entries) {
        final prodRows = await txn.query('products', where: 'id = ?', whereArgs: [entry.key]);
        if (prodRows.isEmpty) {
          throw Exception('Product ID ${entry.key} not found.');
        }
        final prod = Product.fromMap(prodRows.first);
        if (prod.currentStockPieces < entry.value) {
          throw InsufficientStockException(
            prod.sku,
            prod.name,
            prod.currentStockPieces,
            entry.value,
          );
        }
        productSnapshots[entry.key] = prod;
      }

      // 3. Calculate total COGS based on snapshotted moving-average costs
      int totalCostPaisa = 0;
      final List<InvoiceItem> finalItems = [];
      for (final item in invoice.items) {
        final prod = productSnapshots[item.productId]!;
        final lineCostPaisa = item.totalPieces * prod.costPricePaisa;
        totalCostPaisa += lineCostPaisa;
        finalItems.add(item.copyWith(
          costPerPiecePaisa: prod.costPricePaisa,
          totalCostPaisa: lineCostPaisa,
        ));
      }

      // 4. Insert Invoice record
      final invoiceMap = invoice.copyWith(totalCostPaisa: totalCostPaisa).toMap();
      final invoiceId = await txn.insert('invoices', invoiceMap);

      // 5. Insert Invoice Items and update stock
      for (final item in finalItems) {
        await txn.insert('invoice_items', item.copyWith(invoiceId: invoiceId).toMap());

        // Decrement stock
        await txn.rawUpdate(
          'UPDATE products SET current_stock_pieces = current_stock_pieces - ?, updated_at = ? WHERE id = ?',
          [item.totalPieces, DateTime.now().toIso8601String(), item.productId],
        );

        // Record stock movement
        await txn.insert('inventory_movements', {
          'product_id': item.productId,
          'sku': item.sku,
          'product_name': item.productName,
          'movement_type': 'sale',
          'qty_pieces': -item.totalPieces,
          'unit_cost_paisa': item.costPerPiecePaisa,
          'total_cost_paisa': item.totalCostPaisa,
          'ref_id': invoiceId,
          'ref_number': invoice.invoiceNumber,
          'date': invoice.date,
          'reason': 'Wholesale sale to ${invoice.customerName}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 6. Update Customer Ledger if linked to a registered customer
      if (invoice.customerId != null) {
        final partyRows = await txn.query('parties', where: 'id = ?', whereArgs: [invoice.customerId]);
        if (partyRows.isNotEmpty) {
          final party = Party.fromMap(partyRows.first);
          final newBalance = party.currentBalancePaisa + invoice.duePaisa;

          await txn.update(
            'parties',
            {'current_balance_paisa': newBalance, 'updated_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [invoice.customerId],
          );

          await txn.insert('party_ledger', {
            'party_id': invoice.customerId,
            'date': invoice.date,
            'type': 'invoice',
            'ref_id': invoiceId,
            'ref_number': invoice.invoiceNumber,
            'debit_paisa': invoice.grandTotalPaisa,
            'credit_paisa': invoice.paidPaisa,
            'running_balance_paisa': newBalance,
            'notes': 'Invoice ${invoice.invoiceNumber}',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // 7. Update Cash/Bank account if immediate payment received
      if (invoice.paidPaisa > 0) {
        final accountId = invoice.paymentMethod == 'bank' ? 'bank' : 'cash';
        final currentAccBal = await _ensureAccountBalance(txn, accountId, delta: invoice.paidPaisa);

        await txn.insert('account_transactions', {
          'account_id': accountId,
          'date': invoice.date,
          'type': 'sale_paid',
          'ref_id': invoiceId,
          'ref_number': invoice.invoiceNumber,
          'debit_paisa': invoice.paidPaisa,
          'credit_paisa': 0,
          'running_balance_paisa': currentAccBal,
          'notes': 'Payment for invoice ${invoice.invoiceNumber} (${invoice.customerName})',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return invoiceId;
    });
  }

  // -------------------------------------------------------------
  // 2. POSTING PURCHASES (ATOMIC MOVING AVERAGE COST RECALCULATION)
  // -------------------------------------------------------------
  Future<int> postPurchase(Purchase purchase) async {
    final db = await _dbHelper.database;

    return await db.transaction<int>((txn) async {
      // 1. Insert Purchase Header
      final purchaseId = await txn.insert('purchases', purchase.toMap());

      // 2. Process each item: recalculate moving weighted-average cost & increment stock
      for (final item in purchase.items) {
        await txn.insert('purchase_items', {
          'purchase_id': purchaseId,
          'product_id': item.productId,
          'sku': item.sku,
          'product_name': item.productName,
          'color_spec': item.colorSpec,
          'pack_unit': item.packUnit.name,
          'pack_qty': item.packQty,
          'pieces_per_pack': item.piecesPerPack,
          'total_pieces': item.totalPieces,
          'unit_rate_paisa': item.unitRatePaisa,
          'line_discount_paisa': item.lineDiscountPaisa,
          'net_total_paisa': item.netTotalPaisa,
        });

        // Get current stock & cost of product
        final prodRows = await txn.query('products', where: 'id = ?', whereArgs: [item.productId]);
        if (prodRows.isNotEmpty) {
          final prod = Product.fromMap(prodRows.first);
          final currentStock = prod.currentStockPieces;
          final currentCostPaisa = prod.costPricePaisa;

          int newAvgCostPaisa;
          if (currentStock <= 0) {
            newAvgCostPaisa = item.unitRatePaisa;
          } else {
            final totalOldVal = currentStock * currentCostPaisa;
            final totalNewVal = item.totalPieces * item.unitRatePaisa;
            newAvgCostPaisa = ((totalOldVal + totalNewVal) / (currentStock + item.totalPieces)).round();
          }

          // Update stock and cost
          await txn.update(
            'products',
            {
              'current_stock_pieces': currentStock + item.totalPieces,
              'cost_price_paisa': newAvgCostPaisa,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          // Record inward inventory movement
          await txn.insert('inventory_movements', {
            'product_id': item.productId,
            'sku': item.sku,
            'product_name': item.productName,
            'movement_type': 'purchase',
            'qty_pieces': item.totalPieces,
            'unit_cost_paisa': item.unitRatePaisa,
            'total_cost_paisa': item.netTotalPaisa,
            'ref_id': purchaseId,
            'ref_number': purchase.refNumber,
            'date': purchase.date,
            'reason': 'Purchase received from ${purchase.supplierName}',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // 3. Update Supplier Ledger
      final supplierRows = await txn.query('parties', where: 'id = ?', whereArgs: [purchase.supplierId]);
      if (supplierRows.isNotEmpty) {
        final supplier = Party.fromMap(supplierRows.first);
        final newBalance = supplier.currentBalancePaisa + purchase.duePaisa;

        await txn.update(
          'parties',
          {'current_balance_paisa': newBalance, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [purchase.supplierId],
        );

        await txn.insert('party_ledger', {
          'party_id': purchase.supplierId,
          'date': purchase.date,
          'type': 'purchase_bill',
          'ref_id': purchaseId,
          'ref_number': purchase.refNumber,
          'debit_paisa': purchase.paidPaisa,
          'credit_paisa': purchase.grandTotalPaisa,
          'running_balance_paisa': newBalance,
          'notes': 'Purchase Bill ${purchase.refNumber}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 4. Update Cash/Bank if payment was made at purchase time
      if (purchase.paidPaisa > 0) {
        final accountId = purchase.paymentMethod == 'bank' ? 'bank' : 'cash';
        final currentBal = await _ensureAccountBalance(txn, accountId);

        if (accountId == 'cash' && currentBal < purchase.paidPaisa) {
          throw InsufficientFundsException('Cash in Shop', currentBal, purchase.paidPaisa);
        }

        final newAccBal = await _ensureAccountBalance(txn, accountId, delta: -purchase.paidPaisa);

        await txn.insert('account_transactions', {
          'account_id': accountId,
          'date': purchase.date,
          'type': 'purchase_paid',
          'ref_id': purchaseId,
          'ref_number': purchase.refNumber,
          'debit_paisa': 0,
          'credit_paisa': purchase.paidPaisa,
          'running_balance_paisa': newAccBal,
          'notes': 'Payment for purchase bill ${purchase.refNumber}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return purchaseId;
    });
  }

  // -------------------------------------------------------------
  // 3. RECEIVING CUSTOMER PAYMENT (ALLOCATED TO UNPAID INVOICES)
  // -------------------------------------------------------------
  Future<void> receiveCustomerPayment({
    required int customerId,
    required String customerName,
    required int amountPaisa,
    required String accountType, // 'cash' or 'bank'
    required String date,
    String? refNumber,
    String? notes,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Debit account
      final currentAccBal = await _ensureAccountBalance(txn, accountType, delta: amountPaisa);

      // 2. Reduce Customer balance
      final partyRows = await txn.query('parties', where: 'id = ?', whereArgs: [customerId]);
      final party = Party.fromMap(partyRows.first);
      final newBalance = party.currentBalancePaisa - amountPaisa;

      await txn.update(
        'parties',
        {'current_balance_paisa': newBalance, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      final receiptNo = 'RCT-${DateTime.now().millisecondsSinceEpoch % 1000000}';

      // 3. Insert Payment record
      final paymentId = await txn.insert('party_payments', {
        'payment_type': 'customerReceipt',
        'receipt_number': receiptNo,
        'date': date,
        'party_id': customerId,
        'party_name': customerName,
        'amount_paisa': amountPaisa,
        'account_type': accountType,
        'ref_number': refNumber,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 4. Insert Ledger entry
      await txn.insert('party_ledger', {
        'party_id': customerId,
        'date': date,
        'type': 'receipt',
        'ref_id': paymentId,
        'ref_number': receiptNo,
        'debit_paisa': 0,
        'credit_paisa': amountPaisa,
        'running_balance_paisa': newBalance,
        'notes': notes ?? 'Payment received ($accountType)',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 5. Insert account transaction
      await txn.insert('account_transactions', {
        'account_id': accountType,
        'date': date,
        'type': 'customer_receipt',
        'ref_id': paymentId,
        'ref_number': receiptNo,
        'debit_paisa': amountPaisa,
        'credit_paisa': 0,
        'running_balance_paisa': currentAccBal,
        'notes': 'Receipt from $customerName ($receiptNo)',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 6. Allocate against unpaid/partial invoices (oldest first)
      int unallocated = amountPaisa;
      final unpaidInvoices = await txn.query(
        'invoices',
        where: 'customer_id = ? AND payment_status != ? AND status = ?',
        whereArgs: [customerId, 'paid', 'posted'],
        orderBy: 'date ASC, id ASC',
      );

      for (final invRow in unpaidInvoices) {
        if (unallocated <= 0) break;
        final invId = invRow['id'] as int;
        final due = (invRow['due_paisa'] as int?) ?? 0;
        final paid = (invRow['paid_paisa'] as int?) ?? 0;

        final allocate = due <= unallocated ? due : unallocated;
        final newPaid = paid + allocate;
        final newDue = due - allocate;
        final newStatus = newDue == 0 ? 'paid' : 'partial';

        await txn.update(
          'invoices',
          {'paid_paisa': newPaid, 'due_paisa': newDue, 'payment_status': newStatus},
          where: 'id = ?',
          whereArgs: [invId],
        );
        unallocated -= allocate;
      }
    });
  }

  // -------------------------------------------------------------
  // 4. PAYING SUPPLIER
  // -------------------------------------------------------------
  Future<void> paySupplier({
    required int supplierId,
    required String supplierName,
    required int amountPaisa,
    required String accountType,
    required String date,
    String? refNumber,
    String? notes,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Check account balance
      final currentAccBal = await _ensureAccountBalance(txn, accountType);

      if (accountType == 'cash' && currentAccBal < amountPaisa) {
        throw InsufficientFundsException('Cash in Shop', currentAccBal, amountPaisa);
      }

      // 2. Credit account
      final newAccBal = await _ensureAccountBalance(txn, accountType, delta: -amountPaisa);

      // 3. Deduct supplier payable
      final partyRows = await txn.query('parties', where: 'id = ?', whereArgs: [supplierId]);
      final supplier = Party.fromMap(partyRows.first);
      final newBalance = supplier.currentBalancePaisa - amountPaisa;

      await txn.update(
        'parties',
        {'current_balance_paisa': newBalance, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [supplierId],
      );

      final payNo = 'PAY-${DateTime.now().millisecondsSinceEpoch % 1000000}';

      final paymentId = await txn.insert('party_payments', {
        'payment_type': 'supplierPayment',
        'receipt_number': payNo,
        'date': date,
        'party_id': supplierId,
        'party_name': supplierName,
        'amount_paisa': amountPaisa,
        'account_type': accountType,
        'ref_number': refNumber,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      await txn.insert('party_ledger', {
        'party_id': supplierId,
        'date': date,
        'type': 'payment',
        'ref_id': paymentId,
        'ref_number': payNo,
        'debit_paisa': amountPaisa,
        'credit_paisa': 0,
        'running_balance_paisa': newBalance,
        'notes': notes ?? 'Payment made to supplier ($accountType)',
        'created_at': DateTime.now().toIso8601String(),
      });

      await txn.insert('account_transactions', {
        'account_id': accountType,
        'date': date,
        'type': 'supplier_payment',
        'ref_id': paymentId,
        'ref_number': payNo,
        'debit_paisa': 0,
        'credit_paisa': amountPaisa,
        'running_balance_paisa': newAccBal,
        'notes': 'Payment to $supplierName ($payNo)',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Allocate against unpaid purchases
      int unallocated = amountPaisa;
      final unpaidPurchases = await txn.query(
        'purchases',
        where: 'supplier_id = ? AND payment_status != ? AND status = ?',
        whereArgs: [supplierId, 'paid', 'received'],
        orderBy: 'date ASC, id ASC',
      );

      for (final purRow in unpaidPurchases) {
        if (unallocated <= 0) break;
        final purId = purRow['id'] as int;
        final due = (purRow['due_paisa'] as int?) ?? 0;
        final paid = (purRow['paid_paisa'] as int?) ?? 0;

        final allocate = due <= unallocated ? due : unallocated;
        final newPaid = paid + allocate;
        final newDue = due - allocate;
        final newStatus = newDue == 0 ? 'paid' : 'partial';

        await txn.update(
          'purchases',
          {'paid_paisa': newPaid, 'due_paisa': newDue, 'payment_status': newStatus},
          where: 'id = ?',
          whereArgs: [purId],
        );
        unallocated -= allocate;
      }
    });
  }

  // -------------------------------------------------------------
  // 5. EXPENSES
  // -------------------------------------------------------------
  Future<void> recordExpense(Expense expense) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final currentAccBal = await _ensureAccountBalance(txn, expense.accountId);

      if (expense.accountId == 'cash' && currentAccBal < expense.amountPaisa) {
        throw InsufficientFundsException('Cash in Shop', currentAccBal, expense.amountPaisa);
      }

      final newAccBal = await _ensureAccountBalance(txn, expense.accountId, delta: -expense.amountPaisa);

      final expId = await txn.insert('expenses', expense.toMap());

      await txn.insert('account_transactions', {
        'account_id': expense.accountId,
        'date': expense.date,
        'type': 'expense',
        'ref_id': expId,
        'ref_number': 'EXP-$expId',
        'debit_paisa': 0,
        'credit_paisa': expense.amountPaisa,
        'running_balance_paisa': newAccBal,
        'notes': '${expense.category}: ${expense.notes ?? ""}',
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // -------------------------------------------------------------
  // 6. INTERNAL TRANSFERS (CASH <-> BANK)
  // -------------------------------------------------------------
  Future<void> transferFunds({
    required String fromAccountId,
    required String toAccountId,
    required int amountPaisa,
    required String date,
    String? notes,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final fromBal = await _ensureAccountBalance(txn, fromAccountId);

      if (fromBal < amountPaisa) {
        throw InsufficientFundsException(fromAccountId == 'cash' ? 'Cash' : 'Bank', fromBal, amountPaisa);
      }

      final newFromBal = await _ensureAccountBalance(txn, fromAccountId, delta: -amountPaisa);
      final newToBal = await _ensureAccountBalance(txn, toAccountId, delta: amountPaisa);

      final transferRef = 'TRF-${DateTime.now().millisecondsSinceEpoch % 1000000}';

      // Outward entry
      await txn.insert('account_transactions', {
        'account_id': fromAccountId,
        'date': date,
        'type': 'transfer_out',
        'ref_number': transferRef,
        'debit_paisa': 0,
        'credit_paisa': amountPaisa,
        'running_balance_paisa': newFromBal,
        'notes': 'Transfer to $toAccountId: ${notes ?? ""}',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Inward entry
      await txn.insert('account_transactions', {
        'account_id': toAccountId,
        'date': date,
        'type': 'transfer_in',
        'ref_number': transferRef,
        'debit_paisa': amountPaisa,
        'credit_paisa': 0,
        'running_balance_paisa': newToBal,
        'notes': 'Transfer from $fromAccountId: ${notes ?? ""}',
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // -------------------------------------------------------------
  // 7. STOCK ADJUSTMENT (COUNT AUDIT)
  // -------------------------------------------------------------
  Future<void> adjustStock(StockAdjustment adjustment) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'products',
        {
          'current_stock_pieces': adjustment.newQtyPieces,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [adjustment.productId],
      );

      final adjId = await txn.insert('stock_adjustments', adjustment.toMap());

      await txn.insert('inventory_movements', {
        'product_id': adjustment.productId,
        'sku': adjustment.sku,
        'product_name': adjustment.productName,
        'movement_type': 'adjustment',
        'qty_pieces': adjustment.diffQtyPieces,
        'unit_cost_paisa': adjustment.costPerPiecePaisa,
        'total_cost_paisa': adjustment.totalCostImpactPaisa.abs(),
        'ref_id': adjId,
        'ref_number': 'ADJ-$adjId',
        'date': adjustment.date,
        'reason': adjustment.reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      await txn.insert('audit_logs', {
        'timestamp': DateTime.now().toIso8601String(),
        'user_role': adjustment.createdBy,
        'action': 'STOCK_ADJUSTMENT',
        'entity': 'Product',
        'entity_id': adjustment.sku,
        'details': 'Adjusted stock from ${adjustment.oldQtyPieces} to ${adjustment.newQtyPieces} pieces (${adjustment.reason})',
      });
    });
  }

  // -------------------------------------------------------------
  // 8. SALES RETURN (PARTIAL OR FULL, SALEABLE VS DAMAGED)
  // -------------------------------------------------------------
  Future<int> processSalesReturn(ReturnOrder returnOrder) async {
    final db = await _dbHelper.database;

    return await db.transaction<int>((txn) async {
      final returnId = await txn.insert('return_orders', returnOrder.toMap());

      for (final item in returnOrder.items) {
        await txn.insert('return_items', item.copyWith(returnOrderId: returnId).toMap());

        if (item.isSaleable) {
          // Add back to available sellable stock
          await txn.rawUpdate(
            'UPDATE products SET current_stock_pieces = current_stock_pieces + ?, updated_at = ? WHERE id = ?',
            [item.totalPieces, DateTime.now().toIso8601String(), item.productId],
          );

          await txn.insert('inventory_movements', {
            'product_id': item.productId,
            'sku': item.sku,
            'product_name': item.productName,
            'movement_type': 'saleReturnSaleable',
            'qty_pieces': item.totalPieces,
            'unit_cost_paisa': item.costPerPiecePaisa,
            'total_cost_paisa': item.totalPieces * item.costPerPiecePaisa,
            'ref_id': returnId,
            'ref_number': returnOrder.returnNumber,
            'date': returnOrder.date,
            'reason': 'Customer return (Saleable condition)',
            'created_at': DateTime.now().toIso8601String(),
          });
        } else {
          // Add to damaged quarantined stock
          await txn.rawUpdate(
            'UPDATE products SET damaged_stock_pieces = damaged_stock_pieces + ?, updated_at = ? WHERE id = ?',
            [item.totalPieces, DateTime.now().toIso8601String(), item.productId],
          );

          await txn.insert('inventory_movements', {
            'product_id': item.productId,
            'sku': item.sku,
            'product_name': item.productName,
            'movement_type': 'saleReturnDamaged',
            'qty_pieces': item.totalPieces,
            'unit_cost_paisa': item.costPerPiecePaisa,
            'total_cost_paisa': item.totalPieces * item.costPerPiecePaisa,
            'ref_id': returnId,
            'ref_number': returnOrder.returnNumber,
            'date': returnOrder.date,
            'reason': 'Customer return (Damaged/Faulty)',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // Update customer balance: credit customer
      final partyRows = await txn.query('parties', where: 'id = ?', whereArgs: [returnOrder.partyId]);
      if (partyRows.isNotEmpty) {
        final party = Party.fromMap(partyRows.first);
        final newBal = party.currentBalancePaisa - returnOrder.totalCreditPaisa;

        await txn.update(
          'parties',
          {'current_balance_paisa': newBal, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [returnOrder.partyId],
        );

        await txn.insert('party_ledger', {
          'party_id': returnOrder.partyId,
          'date': returnOrder.date,
          'type': 'credit_note',
          'ref_id': returnId,
          'ref_number': returnOrder.returnNumber,
          'debit_paisa': 0,
          'credit_paisa': returnOrder.totalCreditPaisa,
          'running_balance_paisa': newBal,
          'notes': 'Credit note for return against ${returnOrder.originalDocumentNumber}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // If immediate cash refund was paid to customer
      if (returnOrder.refundedCashPaisa > 0) {
        final currentBal = await _ensureAccountBalance(txn, 'cash', delta: -returnOrder.refundedCashPaisa);

        await txn.insert('account_transactions', {
          'account_id': 'cash',
          'date': returnOrder.date,
          'type': 'expense',
          'ref_id': returnId,
          'ref_number': returnOrder.returnNumber,
          'debit_paisa': 0,
          'credit_paisa': returnOrder.refundedCashPaisa,
          'running_balance_paisa': currentBal,
          'notes': 'Cash refund for sales return ${returnOrder.returnNumber}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return returnId;
    });
  }

  // -------------------------------------------------------------
  // 9. CANCEL / REVERSE INVOICE (OWNER ONLY)
  // -------------------------------------------------------------
  Future<void> cancelInvoice(int invoiceId, {String userRole = 'owner'}) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final invRows = await txn.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
      if (invRows.isEmpty) throw Exception('Invoice not found');
      final invoice = Invoice.fromMap(invRows.first);

      if (invoice.status == InvoiceStatus.cancelled) {
        throw Exception('Invoice is already cancelled.');
      }

      // Fetch items
      final itemRows = await txn.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      final items = itemRows.map((e) => InvoiceItem.fromMap(e)).toList();

      // 1. Restore stock
      for (final item in items) {
        await txn.rawUpdate(
          'UPDATE products SET current_stock_pieces = current_stock_pieces + ?, updated_at = ? WHERE id = ?',
          [item.totalPieces, DateTime.now().toIso8601String(), item.productId],
        );

        await txn.insert('inventory_movements', {
          'product_id': item.productId,
          'sku': item.sku,
          'product_name': item.productName,
          'movement_type': 'adjustment',
          'qty_pieces': item.totalPieces,
          'unit_cost_paisa': item.costPerPiecePaisa,
          'total_cost_paisa': item.totalCostPaisa,
          'ref_id': invoiceId,
          'ref_number': invoice.invoiceNumber,
          'date': DateTime.now().toIso8601String().split('T').first,
          'reason': 'Invoice ${invoice.invoiceNumber} Cancelled / Reversed',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 2. Reverse customer balance
      if (invoice.customerId != null) {
        final partyRows = await txn.query('parties', where: 'id = ?', whereArgs: [invoice.customerId]);
        if (partyRows.isNotEmpty) {
          final party = Party.fromMap(partyRows.first);
          final newBal = party.currentBalancePaisa - invoice.duePaisa;

          await txn.update(
            'parties',
            {'current_balance_paisa': newBal, 'updated_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [invoice.customerId],
          );

          await txn.insert('party_ledger', {
            'party_id': invoice.customerId,
            'date': DateTime.now().toIso8601String().split('T').first,
            'type': 'credit_note',
            'ref_id': invoiceId,
            'ref_number': invoice.invoiceNumber,
            'debit_paisa': 0,
            'credit_paisa': invoice.duePaisa,
            'running_balance_paisa': newBal,
            'notes': 'Invoice Cancellation Reversal ${invoice.invoiceNumber}',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // 3. Reverse cash/bank if payment was made
      if (invoice.paidPaisa > 0) {
        final accountId = invoice.paymentMethod == 'bank' ? 'bank' : 'cash';
        final currentBal = await _ensureAccountBalance(txn, accountId, delta: -invoice.paidPaisa);

        await txn.insert('account_transactions', {
          'account_id': accountId,
          'date': DateTime.now().toIso8601String().split('T').first,
          'type': 'expense',
          'ref_id': invoiceId,
          'ref_number': invoice.invoiceNumber,
          'debit_paisa': 0,
          'credit_paisa': invoice.paidPaisa,
          'running_balance_paisa': currentBal,
          'notes': 'Reversal of payment for cancelled invoice ${invoice.invoiceNumber}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 4. Mark invoice cancelled
      await txn.update('invoices', {'status': 'cancelled'}, where: 'id = ?', whereArgs: [invoiceId]);

      // 5. Audit Log
      await txn.insert('audit_logs', {
        'timestamp': DateTime.now().toIso8601String(),
        'user_role': userRole,
        'action': 'INVOICE_CANCEL',
        'entity': 'Invoice',
        'entity_id': invoice.invoiceNumber,
        'details': 'Cancelled invoice ${invoice.invoiceNumber} for ${invoice.customerName} (Total: PKR ${(invoice.grandTotalPaisa / 100).toStringAsFixed(2)})',
      });
    });
  }
}
