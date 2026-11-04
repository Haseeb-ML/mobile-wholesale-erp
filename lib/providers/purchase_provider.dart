import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/core/utils/money.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/models/purchase.dart';
import 'package:mobile_wholesale_erp/models/purchase_item.dart';

class PurchaseProvider extends ChangeNotifier {
  List<Purchase> _purchases = [];
  bool _isLoading = false;

  // New Purchase state
  Party? _selectedSupplier;
  String _refNumber = '';
  final List<PurchaseItem> _cartItems = [];
  int _freightPaisa = 0;
  int _discountPaisa = 0;
  int _paidAmountPaisa = 0;
  String _paymentMethod = 'credit'; // 'cash', 'bank', 'credit'
  String _notes = '';
  bool _isPosting = false;

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;

  Party? get selectedSupplier => _selectedSupplier;
  String get refNumber => _refNumber;
  List<PurchaseItem> get cartItems => List.unmodifiable(_cartItems);
  int get freightPaisa => _freightPaisa;
  int get discountPaisa => _discountPaisa;
  int get paidAmountPaisa => _paidAmountPaisa;
  String get paymentMethod => _paymentMethod;
  String get notes => _notes;
  bool get isPosting => _isPosting;

  int get subtotalPaisa => _cartItems.fold(0, (sum, i) => sum + i.netTotalPaisa);
  int get grandTotalPaisa => (subtotalPaisa - _discountPaisa + _freightPaisa).clamp(0, double.infinity).toInt();
  int get duePaisa => (grandTotalPaisa - _paidAmountPaisa).clamp(0, double.infinity).toInt();

  Money get grandTotal => Money(grandTotalPaisa);
  Money get subtotal => Money(subtotalPaisa);
  Money get due => Money(duePaisa);
  Money get freight => Money(freightPaisa);
  Money get discount => Money(discountPaisa);
  Money get paidAmount => Money(paidAmountPaisa);

  void selectSupplier(Party? s) {
    _selectedSupplier = s;
    notifyListeners();
  }

  void setRefNumber(String r) {
    _refNumber = r;
  }

  void setFreight(int paisa) {
    _freightPaisa = paisa;
    notifyListeners();
  }

  void setDiscount(int paisa) {
    _discountPaisa = paisa;
    notifyListeners();
  }

  void setPaidAmount(int paisa) {
    _paidAmountPaisa = paisa.clamp(0, grandTotalPaisa);
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    if (method == 'cash' || method == 'bank') {
      _paidAmountPaisa = grandTotalPaisa;
    } else {
      _paidAmountPaisa = 0;
    }
    notifyListeners();
  }

  void setNotes(String n) {
    _notes = n;
  }

  void addOrUpdateItem({
    required Product product,
    required PackUnit packUnit,
    required int packQty,
    required int unitCostPerPiecePaisa,
  }) {
    final piecesPerPack = packUnit == PackUnit.piece
        ? 1
        : packUnit == PackUnit.dozen
            ? 12
            : product.piecesPerBox;

    final totalPieces = packQty * piecesPerPack;
    final netTotal = totalPieces * unitCostPerPiecePaisa;

    final existingIndex = _cartItems.indexWhere((i) => i.productId == product.id && i.packUnit == packUnit);

    final newItem = PurchaseItem(
      productId: product.id!,
      sku: product.sku,
      productName: product.name,
      colorSpec: product.colorSpec,
      packUnit: packUnit,
      packQty: packQty,
      piecesPerPack: piecesPerPack,
      totalPieces: totalPieces,
      unitRatePaisa: unitCostPerPiecePaisa,
      netTotalPaisa: netTotal,
    );

    if (existingIndex >= 0) {
      if (packQty <= 0) {
        _cartItems.removeAt(existingIndex);
      } else {
        _cartItems[existingIndex] = newItem;
      }
    } else if (packQty > 0) {
      _cartItems.add(newItem);
    }

    if (_paymentMethod == 'cash' || _paymentMethod == 'bank') {
      _paidAmountPaisa = grandTotalPaisa;
    }
    notifyListeners();
  }

  void clearForm() {
    _selectedSupplier = null;
    _refNumber = '';
    _cartItems.clear();
    _freightPaisa = 0;
    _discountPaisa = 0;
    _paidAmountPaisa = 0;
    _paymentMethod = 'credit';
    _notes = '';
    _isPosting = false;
    notifyListeners();
  }

  Future<void> loadPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('purchases', orderBy: 'date DESC, id DESC');
      _purchases = rows.map((e) => Purchase.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error loading purchases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> postPurchaseBill() async {
    if (_selectedSupplier == null) throw Exception('Please select a supplier.');
    if (_cartItems.isEmpty) throw Exception('Add at least one item to purchase.');

    _isPosting = true;
    notifyListeners();

    try {
      final ref = _refNumber.isNotEmpty
          ? _refNumber
          : 'PUR-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, "0")}-${DateTime.now().millisecondsSinceEpoch % 10000}';

      final purchase = Purchase(
        refNumber: ref,
        date: DateTime.now().toIso8601String().split('T').first,
        supplierId: _selectedSupplier!.id!,
        supplierName: _selectedSupplier!.name,
        status: PurchaseStatus.received,
        paymentStatus: duePaisa == 0
            ? PaymentStatus.paid
            : (_paidAmountPaisa > 0 ? PaymentStatus.partial : PaymentStatus.unpaid),
        subtotalPaisa: subtotalPaisa,
        discountPaisa: _discountPaisa,
        freightPaisa: _freightPaisa,
        grandTotalPaisa: grandTotalPaisa,
        paidPaisa: _paidAmountPaisa,
        duePaisa: duePaisa,
        paymentMethod: _paymentMethod,
        notes: _notes.isNotEmpty ? _notes : null,
        createdAt: DateTime.now().toIso8601String(),
        items: List.from(_cartItems),
      );

      await AccountingService.instance.postPurchase(purchase);
      clearForm();
      await loadPurchases();
    } finally {
      _isPosting = false;
      notifyListeners();
    }
  }
}
