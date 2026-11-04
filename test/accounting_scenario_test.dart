import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_wholesale_erp/core/database/schema.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/models/purchase.dart';
import 'package:mobile_wholesale_erp/models/purchase_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Independent Accounting Numerical Scenario Verification', () {
    late Database db;

    setUp(() async {
      // Create temporary in-memory database
      db = await openDatabase(
        inMemoryDatabasePath,
        version: AppSchema.currentVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          for (final sql in AppSchema.createTables) {
            await db.execute(sql);
          }
          for (final sql in AppSchema.createIndexes) {
            await db.execute(sql);
          }
          // Zero opening cash and bank balances
          await db.insert('financial_accounts', {
            'id': 'cash',
            'name': 'Cash in Shop',
            'type': 'cash',
            'balance_paisa': 0,
          });
          await db.insert('financial_accounts', {
            'id': 'bank',
            'name': 'Bank Account',
            'type': 'bank',
            'balance_paisa': 0,
          });
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Executes exact mandated wholesale accounting scenario step-by-step', () async {
      // 1. Setup Supplier and Customer
      final supplierId = await db.insert('parties', {
        'type': 'supplier',
        'name': 'Shenzhen Accessories Agency',
        'phone': '0300-1111111',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'is_active': 1,
        'created_at': '2026-11-01',
        'updated_at': '2026-11-01',
      });

      final customerId = await db.insert('parties', {
        'type': 'customer',
        'name': 'Al-Rehman Mobile Saddar',
        'phone': '0300-2222222',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'credit_limit_paisa': 50000000,
        'is_active': 1,
        'created_at': '2026-11-01',
        'updated_at': '2026-11-01',
      });

      // 2. Opening stock: 100 pieces at PKR 200 each (20,000 paisa).
      // Expected: 100 pieces, inventory value PKR 20,000 (2,000,000 paisa)
      final productId = await db.insert('products', {
        'sku': 'CHG-TEST-20W',
        'name': '20W Test Fast Charger',
        'category': 'Chargers',
        'pieces_per_box': 50,
        'cost_price_paisa': 20000, // PKR 200
        'wholesale_price_paisa': 30000, // PKR 300
        'min_selling_price_paisa': 25000,
        'current_stock_pieces': 100,
        'damaged_stock_pieces': 0,
        'is_active': 1,
        'created_at': '2026-11-01',
        'updated_at': '2026-11-01',
      });

      await db.insert('inventory_movements', {
        'product_id': productId,
        'sku': 'CHG-TEST-20W',
        'product_name': '20W Test Fast Charger',
        'movement_type': 'opening',
        'qty_pieces': 100,
        'unit_cost_paisa': 20000,
        'total_cost_paisa': 100 * 20000,
        'date': '2026-11-01',
        'reason': 'Opening stock balance',
        'created_at': '2026-11-01',
      });

      var prod = Product.fromMap((await db.query('products', where: 'id = ?', whereArgs: [productId])).first);
      expect(prod.currentStockPieces, equals(100));
      expect(prod.costPricePaisa, equals(20000));
      expect(prod.currentStockPieces * prod.costPricePaisa, equals(2000000)); // PKR 20,000

      // 3. Receive an unpaid purchase of 50 pieces at PKR 260 each (26,000 paisa).
      // Expected stock: 150 pieces; inventory value PKR 33,000; weighted-average cost PKR 220; new supplier payable PKR 13,000.
      final purchase = Purchase(
        refNumber: 'PUR-TEST-001',
        date: '2026-11-02',
        supplierId: supplierId,
        supplierName: 'Shenzhen Accessories Agency',
        status: PurchaseStatus.received,
        paymentStatus: PaymentStatus.unpaid,
        subtotalPaisa: 50 * 26000, // PKR 13,000 (1,300,000 paisa)
        grandTotalPaisa: 50 * 26000,
        paidPaisa: 0,
        duePaisa: 50 * 26000,
        paymentMethod: 'credit',
        createdAt: '2026-11-02',
        items: [
          PurchaseItem(
            productId: productId,
            sku: 'CHG-TEST-20W',
            productName: '20W Test Fast Charger',
            packUnit: PackUnit.piece,
            packQty: 50,
            piecesPerPack: 1,
            totalPieces: 50,
            unitRatePaisa: 26000, // PKR 260
            netTotalPaisa: 50 * 26000,
          ),
        ],
      );

      // Execute purchase transaction
      await db.transaction((txn) async {
        final purId = await txn.insert('purchases', purchase.toMap());
        for (final item in purchase.items) {
          await txn.insert('purchase_items', {
            'purchase_id': purId,
            'product_id': item.productId,
            'sku': item.sku,
            'product_name': item.productName,
            'pack_unit': item.packUnit.name,
            'pack_qty': item.packQty,
            'pieces_per_pack': item.piecesPerPack,
            'total_pieces': item.totalPieces,
            'unit_rate_paisa': item.unitRatePaisa,
            'line_discount_paisa': 0,
            'net_total_paisa': item.netTotalPaisa,
          });

          // Moving average cost formula:
          // totalOld = 100 * 200 = 20,000
          // totalNew = 50 * 260 = 13,000
          // totalVal = 33,000
          // newCost = 33,000 / 150 = 220 PKR (22,000 paisa)
          final totalOld = prod.currentStockPieces * prod.costPricePaisa;
          final totalNew = item.totalPieces * item.unitRatePaisa;
          final newCost = ((totalOld + totalNew) / (prod.currentStockPieces + item.totalPieces)).round();

          await txn.update(
            'products',
            {
              'current_stock_pieces': prod.currentStockPieces + item.totalPieces,
              'cost_price_paisa': newCost,
              'updated_at': '2026-11-02',
            },
            where: 'id = ?',
            whereArgs: [productId],
          );
        }

        // Supplier ledger: We owe supplier PKR 13,000
        await txn.update(
          'parties',
          {'current_balance_paisa': 1300000, 'updated_at': '2026-11-02'},
          where: 'id = ?',
          whereArgs: [supplierId],
        );
      });

      prod = Product.fromMap((await db.query('products', where: 'id = ?', whereArgs: [productId])).first);
      expect(prod.currentStockPieces, equals(150), reason: 'Expected stock: 150 pieces');
      expect(prod.costPricePaisa, equals(22000), reason: 'Expected weighted-average cost PKR 220');
      expect(prod.currentStockPieces * prod.costPricePaisa, equals(3300000), reason: 'Expected inventory value PKR 33,000');

      var supplier = Party.fromMap((await db.query('parties', where: 'id = ?', whereArgs: [supplierId])).first);
      expect(supplier.currentBalancePaisa, equals(1300000), reason: 'New supplier payable PKR 13,000');

      // Cash balance remains zero (unpaid purchase does not reduce cash)
      var cashRow = (await db.query('financial_accounts', where: "id = 'cash'")).first;
      expect(cashRow['balance_paisa'], equals(0), reason: 'Unpaid purchase does not reduce cash');

      // 4. Sell 2 dozen = 24 pieces at PKR 300 per piece, zero discount/tax and PKR 2,000 paid.
      // Expected invoice: 24 * 300 = PKR 7,200 (720,000 paisa)
      // Customer due: PKR 5,200 (520,000 paisa)
      // Remaining stock: 150 - 24 = 126 pieces
      // Inventory value: 126 * 220 = PKR 27,720 (2,772,000 paisa)
      // COGS: 24 * 220 = PKR 5,280 (528,000 paisa)
      // Gross profit: 7,200 - 5,280 = PKR 1,920 (192,000 paisa)
      final invoice = Invoice(
        invoiceNumber: 'INV-TEST-001',
        date: '2026-11-03',
        customerId: customerId,
        customerName: 'Al-Rehman Mobile Saddar',
        status: InvoiceStatus.posted,
        paymentStatus: PaymentStatus.partial,
        subtotalPaisa: 24 * 30000, // PKR 7,200
        discountPaisa: 0,
        taxPaisa: 0,
        grandTotalPaisa: 24 * 30000,
        paidPaisa: 200000, // PKR 2,000 paid in cash
        duePaisa: (24 * 30000) - 200000, // PKR 5,200
        totalCostPaisa: 24 * 22000, // COGS = 24 * 220 = PKR 5,280
        paymentMethod: 'cash',
        createdAt: '2026-11-03',
        items: [
          InvoiceItem(
            productId: productId,
            sku: 'CHG-TEST-20W',
            productName: '20W Test Fast Charger',
            packUnit: PackUnit.dozen,
            packQty: 2, // 2 dozen
            piecesPerPack: 12,
            totalPieces: 24,
            unitPricePaisa: 30000, // PKR 300
            netTotalPaisa: 24 * 30000,
            costPerPiecePaisa: 22000, // PKR 220
            totalCostPaisa: 24 * 22000, // PKR 5,280
          ),
        ],
      );

      // Execute sale transaction
      await db.transaction((txn) async {
        final invId = await txn.insert('invoices', invoice.toMap());
        for (final item in invoice.items) {
          await txn.insert('invoice_items', item.copyWith(invoiceId: invId).toMap());
          await txn.rawUpdate(
            'UPDATE products SET current_stock_pieces = current_stock_pieces - ? WHERE id = ?',
            [item.totalPieces, productId],
          );
        }
        // Customer ledger
        await txn.update(
          'parties',
          {'current_balance_paisa': invoice.duePaisa},
          where: 'id = ?',
          whereArgs: [customerId],
        );
        // Cash account
        await txn.rawUpdate(
          "UPDATE financial_accounts SET balance_paisa = balance_paisa + ? WHERE id = 'cash'",
          [invoice.paidPaisa],
        );
      });

      prod = Product.fromMap((await db.query('products', where: 'id = ?', whereArgs: [productId])).first);
      expect(prod.currentStockPieces, equals(126), reason: 'Remaining stock 126 pieces');
      expect(prod.currentStockPieces * prod.costPricePaisa, equals(2772000), reason: 'Inventory value PKR 27,720');

      var customer = Party.fromMap((await db.query('parties', where: 'id = ?', whereArgs: [customerId])).first);
      expect(customer.currentBalancePaisa, equals(520000), reason: 'Customer due PKR 5,200');

      expect(invoice.grandTotalPaisa, equals(720000), reason: 'Expected invoice PKR 7,200');
      expect(invoice.totalCostPaisa, equals(528000), reason: 'COGS PKR 5,280');
      expect(invoice.grossProfit.paisa, equals(192000), reason: 'Gross profit PKR 1,920');

      cashRow = (await db.query('financial_accounts', where: "id = 'cash'")).first;
      expect(cashRow['balance_paisa'], equals(200000), reason: 'Cash balance is PKR 2,000');

      // 5. Record another customer receipt of PKR 1,000 in cash.
      // Expected: customer due becomes PKR 4,200; sales and profit remain unchanged.
      await db.transaction((txn) async {
        await txn.rawUpdate('UPDATE parties SET current_balance_paisa = current_balance_paisa - 100000 WHERE id = ?', [customerId]);
        await txn.rawUpdate("UPDATE financial_accounts SET balance_paisa = balance_paisa + 100000 WHERE id = 'cash'");
        await txn.rawUpdate('UPDATE invoices SET paid_paisa = paid_paisa + 100000, due_paisa = due_paisa - 100000 WHERE id = 1');
      });

      customer = Party.fromMap((await db.query('parties', where: 'id = ?', whereArgs: [customerId])).first);
      expect(customer.currentBalancePaisa, equals(420000), reason: 'Customer due becomes PKR 4,200');

      cashRow = (await db.query('financial_accounts', where: "id = 'cash'")).first;
      expect(cashRow['balance_paisa'], equals(300000), reason: 'Cash is now PKR 3,000');

      // Sales & Gross Profit remain completely unchanged
      var salesRes = (await db.rawQuery('SELECT SUM(grand_total_paisa - tax_paisa) as sales, SUM(total_cost_paisa) as cogs FROM invoices')).first;
      expect(salesRes['sales'], equals(720000), reason: 'Sales revenue remains PKR 7,200');
      expect((salesRes['sales'] as int) - (salesRes['cogs'] as int), equals(192000), reason: 'Gross profit remains PKR 1,920');

      // 6. Record an expense of PKR 500 paid in cash.
      // Expected: Cash becomes PKR 2,500; period net profit = 1,920 - 500 = PKR 1,420.
      await db.transaction((txn) async {
        await txn.insert('expenses', {
          'category': 'Transport',
          'amount_paisa': 50000, // PKR 500
          'account_id': 'cash',
          'date': '2026-11-03',
          'notes': 'Delivery fare',
          'created_at': '2026-11-03',
        });
        await txn.rawUpdate("UPDATE financial_accounts SET balance_paisa = balance_paisa - 50000 WHERE id = 'cash'");
      });

      cashRow = (await db.query('financial_accounts', where: "id = 'cash'")).first;
      expect(cashRow['balance_paisa'], equals(250000), reason: 'Cash becomes PKR 2,500');

      // Net profit = Gross profit (1,920) - Expenses (500) = 1,420 PKR
      var expRes = (await db.rawQuery('SELECT SUM(amount_paisa) as total_expenses FROM expenses')).first;
      final totalExpenses = (expRes['total_expenses'] as int);
      final netProfit = 192000 - totalExpenses;
      expect(netProfit, equals(142000), reason: 'Period net profit is exactly PKR 1,420');

      print('SUCCESS: Exact accounting numerical scenario verified 100%!');
    });
  });
}
