import 'package:mobile_wholesale_erp/core/utils/money.dart';

class Product {
  final int? id;
  final String sku;
  final String? barcode;
  final String name;
  final String category;
  final String? brand;
  final String? compatibleModel;
  final String? colorSpec;
  final String? imagePath; // Local relative file path or asset path
  final int piecesPerBox; // Custom box/carton size for this SKU
  final int costPricePaisa; // Moving average cost per piece
  final int wholesalePricePaisa; // Standard wholesale price per piece
  final int minSellingPricePaisa; // Price floor per piece
  final int reorderLevel; // Stock threshold
  final int? tierMinQty; // Min quantity for tier price (in pieces)
  final int? tierPricePaisa; // Wholesale rate for tier quantity
  final int currentStockPieces; // Current available pieces
  final int damagedStockPieces; // Damaged/quarantined pieces
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Product({
    this.id,
    required this.sku,
    this.barcode,
    required this.name,
    required this.category,
    this.brand,
    this.compatibleModel,
    this.colorSpec,
    this.imagePath,
    this.piecesPerBox = 50,
    required this.costPricePaisa,
    required this.wholesalePricePaisa,
    required this.minSellingPricePaisa,
    this.reorderLevel = 10,
    this.tierMinQty,
    this.tierPricePaisa,
    this.currentStockPieces = 0,
    this.damagedStockPieces = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Money get costPrice => Money(costPricePaisa);
  Money get wholesalePrice => Money(wholesalePricePaisa);
  Money get minSellingPrice => Money(minSellingPricePaisa);
  Money? get tierPrice => tierPricePaisa != null ? Money(tierPricePaisa!) : null;

  // Money per dozen
  Money get wholesalePriceDozen => wholesalePrice * 12;
  // Money per box
  Money get wholesalePriceBox => wholesalePrice * piecesPerBox;

  bool get isLowStock => currentStockPieces <= reorderLevel && currentStockPieces > 0;
  bool get isOutOfStock => currentStockPieces <= 0;

  /// Effective price per piece given a total quantity in pieces
  int getEffectivePricePaisa(int totalPieces) {
    if (tierMinQty != null && tierPricePaisa != null && totalPieces >= tierMinQty!) {
      return tierPricePaisa!;
    }
    return wholesalePricePaisa;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'category': category,
      'brand': brand,
      'compatible_model': compatibleModel,
      'color_spec': colorSpec,
      'image_path': imagePath,
      'pieces_per_box': piecesPerBox,
      'cost_price_paisa': costPricePaisa,
      'wholesale_price_paisa': wholesalePricePaisa,
      'min_selling_price_paisa': minSellingPricePaisa,
      'reorder_level': reorderLevel,
      'tier_min_qty': tierMinQty,
      'tier_price_paisa': tierPricePaisa,
      'current_stock_pieces': currentStockPieces,
      'damaged_stock_pieces': damagedStockPieces,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      sku: map['sku'] as String,
      barcode: map['barcode'] as String?,
      name: map['name'] as String,
      category: map['category'] as String,
      brand: map['brand'] as String?,
      compatibleModel: map['compatible_model'] as String?,
      colorSpec: map['color_spec'] as String?,
      imagePath: map['image_path'] as String?,
      piecesPerBox: (map['pieces_per_box'] as int?) ?? 50,
      costPricePaisa: (map['cost_price_paisa'] as int?) ?? 0,
      wholesalePricePaisa: (map['wholesale_price_paisa'] as int?) ?? 0,
      minSellingPricePaisa: (map['min_selling_price_paisa'] as int?) ?? 0,
      reorderLevel: (map['reorder_level'] as int?) ?? 10,
      tierMinQty: map['tier_min_qty'] as int?,
      tierPricePaisa: map['tier_price_paisa'] as int?,
      currentStockPieces: (map['current_stock_pieces'] as int?) ?? 0,
      damagedStockPieces: (map['damaged_stock_pieces'] as int?) ?? 0,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Product copyWith({
    int? id,
    String? sku,
    String? barcode,
    String? name,
    String? category,
    String? brand,
    String? compatibleModel,
    String? colorSpec,
    String? imagePath,
    int? piecesPerBox,
    int? costPricePaisa,
    int? wholesalePricePaisa,
    int? minSellingPricePaisa,
    int? reorderLevel,
    int? tierMinQty,
    int? tierPricePaisa,
    int? currentStockPieces,
    int? damagedStockPieces,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      compatibleModel: compatibleModel ?? this.compatibleModel,
      colorSpec: colorSpec ?? this.colorSpec,
      imagePath: imagePath ?? this.imagePath,
      piecesPerBox: piecesPerBox ?? this.piecesPerBox,
      costPricePaisa: costPricePaisa ?? this.costPricePaisa,
      wholesalePricePaisa: wholesalePricePaisa ?? this.wholesalePricePaisa,
      minSellingPricePaisa: minSellingPricePaisa ?? this.minSellingPricePaisa,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      tierMinQty: tierMinQty ?? this.tierMinQty,
      tierPricePaisa: tierPricePaisa ?? this.tierPricePaisa,
      currentStockPieces: currentStockPieces ?? this.currentStockPieces,
      damagedStockPieces: damagedStockPieces ?? this.damagedStockPieces,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
