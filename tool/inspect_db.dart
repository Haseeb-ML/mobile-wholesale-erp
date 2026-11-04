import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  final dbPath = r'C:\Users\M HASEEB\AppData\Roaming\com.mobilewholesale.erp\mobile_wholesale_erp\databases\erp_demo.db';
  print('Checking db at: $dbPath');
  if (!File(dbPath).existsSync()) {
    print('File does not exist: $dbPath');
    return;
  }
  final db = await databaseFactoryFfi.openDatabase(dbPath);
  final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  print('Tables: ${tables.map((t) => t['name']).toList()}');
  for (var table in ['shop_settings', 'financial_accounts', 'products', 'parties', 'invoices', 'invoice_items']) {
    try {
      final rows = await db.rawQuery('SELECT count(*) as count FROM $table');
      print('$table count: ${rows.first["count"]}');
    } catch (e) {
      print('Error on $table: $e');
    }
  }

  // Check financial_accounts rows
  try {
    final accs = await db.rawQuery('SELECT * FROM financial_accounts');
    print('financial_accounts: $accs');
  } catch (e) {
    print('Error financial_accounts: $e');
  }

  // Check recent invoices
  try {
    final invs = await db.rawQuery('SELECT * FROM invoices ORDER BY id DESC LIMIT 5');
    print('recent invoices: $invs');
  } catch (e) {
    print('Error invoices: $e');
  }

  await db.close();
}

