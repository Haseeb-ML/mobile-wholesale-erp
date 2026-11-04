import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/models/stock_adjustment.dart';

class CatalogProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _stockFilter = 'all'; // 'all', 'low', 'out'
  bool _isGridView = true;

  List<Product> get products {
    return _products.where((p) {
      if (!p.isActive) return false;

      // Category filter
      if (_selectedCategory != 'All' && p.category != _selectedCategory) {
        return false;
      }

      // Stock status filter
      if (_stockFilter == 'low' && !p.isLowStock) return false;
      if (_stockFilter == 'out' && !p.isOutOfStock) return false;

      // Text query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchSku = p.sku.toLowerCase().contains(q);
        final matchBarcode = p.barcode?.toLowerCase().contains(q) ?? false;
        final matchModel = p.compatibleModel?.toLowerCase().contains(q) ?? false;
        final matchCategory = p.category.toLowerCase().contains(q);
        return matchName || matchSku || matchBarcode || matchModel || matchCategory;
      }
      return true;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get stockFilter => _stockFilter;
  bool get isGridView => _isGridView;

  List<String> get categories {
    final set = {'All'};
    for (final p in _products) {
      if (p.isActive) set.add(p.category);
    }
    return set.toList();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void setStockFilter(String filter) {
    _stockFilter = filter;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('products', orderBy: 'name ASC');
      _products = rows.map((e) => Product.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProduct(Product product, {int openingPieces = 0, int openingCostPaisa = 0}) async {
    final db = await DatabaseHelper.instance.database;

    if (product.id == null) {
      // New Product
      final id = await db.insert('products', product.toMap());
      if (openingPieces > 0) {
        // Record opening stock movement
        await db.update(
          'products',
          {'current_stock_pieces': openingPieces, 'cost_price_paisa': openingCostPaisa},
          where: 'id = ?',
          whereArgs: [id],
        );

        await db.insert('inventory_movements', {
          'product_id': id,
          'sku': product.sku,
          'product_name': product.name,
          'movement_type': 'opening',
          'qty_pieces': openingPieces,
          'unit_cost_paisa': openingCostPaisa,
          'total_cost_paisa': openingPieces * openingCostPaisa,
          'date': DateTime.now().toIso8601String().split('T').first,
          'reason': 'Opening Stock Balance',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } else {
      // Edit existing product
      await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
    }
    await loadProducts();
  }

  Future<void> adjustStockCount(StockAdjustment adjustment) async {
    await AccountingService.instance.adjustStock(adjustment);
    await loadProducts();
  }

  Future<void> archiveProduct(int productId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('products', {'is_active': 0}, where: 'id = ?', whereArgs: [productId]);
    await loadProducts();
  }
}
