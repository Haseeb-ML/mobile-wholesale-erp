import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/core/utils/money.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/models/product.dart';

class CartProvider extends ChangeNotifier {
  Party? _selectedCustomer; // null = Walk-in cash customer
  final List<InvoiceItem> _items = [];
  int _invoiceDiscountPaisa = 0;
  double _taxPercent = 0.0;
  int _paidAmountPaisa = 0;
  String _paymentMethod = 'cash'; // 'cash', 'bank', 'credit'
  String _notes = '';
  bool _isPosting = false;

  Party? get selectedCustomer => _selectedCustomer;
  List<InvoiceItem> get items => List.unmodifiable(_items);
  int get invoiceDiscountPaisa => _invoiceDiscountPaisa;
  double get taxPercent => _taxPercent;
  int get paidAmountPaisa => _paidAmountPaisa;
  String get paymentMethod => _paymentMethod;
  String get notes => _notes;
  bool get isPosting => _isPosting;

  bool get isEmpty => _items.isEmpty;
  int get totalPieces => _items.fold(0, (sum, i) => sum + i.totalPieces);

  int get subtotalPaisa => _items.fold(0, (sum, i) => sum + i.netTotalPaisa);
  int get discountedSubtotalPaisa => (subtotalPaisa - _invoiceDiscountPaisa).clamp(0, double.infinity).toInt();
  int get taxPaisa => ((discountedSubtotalPaisa * _taxPercent) / 100.0).round();
  int get grandTotalPaisa => discountedSubtotalPaisa + taxPaisa;
  int get remainingDuePaisa => (grandTotalPaisa - _paidAmountPaisa).clamp(0, double.infinity).toInt();

  Money get subtotal => Money(subtotalPaisa);
  Money get invoiceDiscount => Money(_invoiceDiscountPaisa);
  Money get tax => Money(taxPaisa);
  Money get grandTotal => Money(grandTotalPaisa);
  Money get paidAmount => Money(_paidAmountPaisa);
  Money get remainingDue => Money(remainingDuePaisa);

  void selectCustomer(Party? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    if (method == 'cash' || method == 'bank') {
      _paidAmountPaisa = grandTotalPaisa;
    } else if (method == 'credit') {
      _paidAmountPaisa = 0;
    }
    notifyListeners();
  }

  void setPaidAmount(int paisa) {
    _paidAmountPaisa = paisa.clamp(0, grandTotalPaisa);
    notifyListeners();
  }

  void setInvoiceDiscount(int paisa) {
    _invoiceDiscountPaisa = paisa.clamp(0, subtotalPaisa);
    if (_paymentMethod == 'cash' || _paymentMethod == 'bank') {
      _paidAmountPaisa = grandTotalPaisa;
    }
    notifyListeners();
  }

  void setTaxPercent(double percent) {
    _taxPercent = percent;
    if (_paymentMethod == 'cash' || _paymentMethod == 'bank') {
      _paidAmountPaisa = grandTotalPaisa;
    }
    notifyListeners();
  }

  void setNotes(String n) {
    _notes = n;
  }

  void addOrUpdateProduct({
    required Product product,
    required PackUnit packUnit,
    required int packQty,
    int? customPricePerPiecePaisa,
  }) {
    final piecesPerPack = packUnit == PackUnit.piece
        ? 1
        : packUnit == PackUnit.dozen
            ? 12
            : product.piecesPerBox;

    final existingIndex = _items.indexWhere((i) => i.productId == product.id && i.packUnit == packUnit);

    final currentTotalPiecesInCart = _items
        .where((i) => i.productId == product.id && (_items.indexOf(i) != existingIndex))
        .fold(0, (sum, i) => sum + i.totalPieces);

    final newPiecesForThisLine = packQty * piecesPerPack;
    final combinedPieces = currentTotalPiecesInCart + newPiecesForThisLine;

    // Determine unit price per piece (tier price if applicable)
    final effectivePricePaisa = customPricePerPiecePaisa ?? product.getEffectivePricePaisa(combinedPieces);
    final netTotal = newPiecesForThisLine * effectivePricePaisa;

    final newItem = InvoiceItem(
      productId: product.id!,
      sku: product.sku,
      productName: product.name,
      colorSpec: product.colorSpec,
      imagePath: product.imagePath,
      packUnit: packUnit,
      packQty: packQty,
      piecesPerPack: piecesPerPack,
      totalPieces: newPiecesForThisLine,
      unitPricePaisa: effectivePricePaisa,
      netTotalPaisa: netTotal,
      costPerPiecePaisa: product.costPricePaisa,
      totalCostPaisa: newPiecesForThisLine * product.costPricePaisa,
    );

    if (existingIndex >= 0) {
      if (packQty <= 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex] = newItem;
      }
    } else if (packQty > 0) {
      _items.add(newItem);
    }

    if (_paymentMethod == 'cash' || _paymentMethod == 'bank') {
      _paidAmountPaisa = grandTotalPaisa;
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      if (_paymentMethod == 'cash' || _paymentMethod == 'bank') {
        _paidAmountPaisa = grandTotalPaisa;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _invoiceDiscountPaisa = 0;
    _taxPercent = 0.0;
    _paidAmountPaisa = 0;
    _paymentMethod = 'cash';
    _notes = '';
    _isPosting = false;
    notifyListeners();
  }

  /// Checks if customer credit limit will be exceeded by this sale
  bool isCreditLimitExceeded() {
    if (_selectedCustomer == null) return false;
    if (_selectedCustomer!.creditLimitPaisa <= 0) return false; // 0 = unlimited or cash dealer

    final projectedBalance = _selectedCustomer!.currentBalancePaisa + remainingDuePaisa;
    return projectedBalance > _selectedCustomer!.creditLimitPaisa;
  }

  /// Posts the wholesale invoice atomically
  Future<Invoice> postInvoice({String userRole = 'owner'}) async {
    if (_items.isEmpty) throw Exception('Cart is empty.');

    _isPosting = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM invoices');
      final nextNum = (countResult.first['count'] as int? ?? 0) + 1;
      final invNumber = 'INV-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, "0")}-${nextNum.toString().padLeft(4, "0")}';

      final paymentStatus = remainingDuePaisa == 0
          ? PaymentStatus.paid
          : (_paidAmountPaisa > 0 ? PaymentStatus.partial : PaymentStatus.unpaid);

      final invoice = Invoice(
        invoiceNumber: invNumber,
        date: DateTime.now().toIso8601String().split('T').first,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name ?? 'Walk-in Cash Customer',
        customerPhone: _selectedCustomer?.phone,
        status: InvoiceStatus.posted,
        paymentStatus: paymentStatus,
        subtotalPaisa: subtotalPaisa,
        discountPaisa: _invoiceDiscountPaisa,
        taxPaisa: taxPaisa,
        grandTotalPaisa: grandTotalPaisa,
        paidPaisa: _paidAmountPaisa,
        duePaisa: remainingDuePaisa,
        paymentMethod: _paymentMethod,
        notes: _notes.isNotEmpty ? _notes : null,
        createdBy: userRole,
        createdAt: DateTime.now().toIso8601String(),
        items: List.from(_items),
      );

      final invoiceId = await AccountingService.instance.postSaleInvoice(invoice, userRole: userRole);
      final postedInvoice = invoice.copyWith(id: invoiceId);
      clearCart();
      return postedInvoice;
    } finally {
      _isPosting = false;
      notifyListeners();
    }
  }
}

