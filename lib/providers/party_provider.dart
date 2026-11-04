import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/models/party.dart';

class PartyProvider extends ChangeNotifier {
  List<Party> _customers = [];
  List<Party> _suppliers = [];
  List<PartyLedgerEntry> _activeLedgerEntries = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Party> get customers {
    if (_searchQuery.isEmpty) return _customers;
    final q = _searchQuery.toLowerCase();
    return _customers.where((c) =>
      c.name.toLowerCase().contains(q) ||
      c.phone.contains(q) ||
      (c.city?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  List<Party> get suppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    final q = _searchQuery.toLowerCase();
    return _suppliers.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.phone.contains(q) ||
      (s.city?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  List<PartyLedgerEntry> get activeLedgerEntries => _activeLedgerEntries;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> loadParties() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final custRows = await db.query('parties', where: 'type = ? AND is_active = 1', whereArgs: ['customer'], orderBy: 'name ASC');
      _customers = custRows.map((e) => Party.fromMap(e)).toList();

      final suppRows = await db.query('parties', where: 'type = ? AND is_active = 1', whereArgs: ['supplier'], orderBy: 'name ASC');
      _suppliers = suppRows.map((e) => Party.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error loading parties: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveParty(Party party) async {
    final db = await DatabaseHelper.instance.database;

    if (party.id == null) {
      final id = await db.insert('parties', party.toMap());
      if (party.openingBalancePaisa != 0) {
        // Record opening ledger entry
        await db.update('parties', {'current_balance_paisa': party.openingBalancePaisa}, where: 'id = ?', whereArgs: [id]);
        await db.insert('party_ledger', {
          'party_id': id,
          'date': DateTime.now().toIso8601String().split('T').first,
          'type': 'opening',
          'debit_paisa': party.openingBalancePaisa > 0 ? party.openingBalancePaisa : 0,
          'credit_paisa': party.openingBalancePaisa < 0 ? party.openingBalancePaisa.abs() : 0,
          'running_balance_paisa': party.openingBalancePaisa,
          'notes': 'Opening Balance',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } else {
      await db.update('parties', party.toMap(), where: 'id = ?', whereArgs: [party.id]);
    }
    await loadParties();
  }

  Future<void> loadPartyLedger(int partyId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'party_ledger',
      where: 'party_id = ?',
      whereArgs: [partyId],
      orderBy: 'date ASC, id ASC',
    );
    _activeLedgerEntries = rows.map((e) => PartyLedgerEntry.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> receivePayment({
    required int customerId,
    required String customerName,
    required int amountPaisa,
    required String accountType,
    required String date,
    String? refNumber,
    String? notes,
  }) async {
    await AccountingService.instance.receiveCustomerPayment(
      customerId: customerId,
      customerName: customerName,
      amountPaisa: amountPaisa,
      accountType: accountType,
      date: date,
      refNumber: refNumber,
      notes: notes,
    );
    await loadParties();
    await loadPartyLedger(customerId);
  }

  Future<void> makeSupplierPayment({
    required int supplierId,
    required String supplierName,
    required int amountPaisa,
    required String accountType,
    required String date,
    String? refNumber,
    String? notes,
  }) async {
    await AccountingService.instance.paySupplier(
      supplierId: supplierId,
      supplierName: supplierName,
      amountPaisa: amountPaisa,
      accountType: accountType,
      date: date,
      refNumber: refNumber,
      notes: notes,
    );
    await loadParties();
    await loadPartyLedger(supplierId);
  }
}

