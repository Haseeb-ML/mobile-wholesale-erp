import 'package:mobile_wholesale_erp/core/utils/money.dart';

enum PackUnit { piece, dozen, box }

class InvoiceItem {
  final int? id;
  final int? invoiceId;
  final int productId;
  final String sku;
  final String productName;
  final String? colorSpec;
  final String? imagePath;
  final PackUnit packUnit;
  final int packQty; // Number of packs selected
  final int piecesPerPack; // 1 for piece, 12 for dozen, product.piecesPerBox for box
  final int totalPieces; // packQty * piecesPerPack
  final int unitPricePaisa; // Price per piece in paisa
  final int lineDiscountPaisa; // Discount on this line
  final int netTotalPaisa; // (totalPieces * unitPricePaisa) - lineDiscountPaisa
  final int costPerPiecePaisa; // Snapshotted moving average cost at sale time
  final int totalCostPaisa; // totalPieces * costPerPiecePaisa

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.sku,
    required this.productName,
    this.colorSpec,
    this.imagePath,
    required this.packUnit,
    required this.packQty,
    required this.piecesPerPack,
    required this.totalPieces,
    required this.unitPricePaisa,
    this.lineDiscountPaisa = 0,
    required this.netTotalPaisa,
    required this.costPerPiecePaisa,
    required this.totalCostPaisa,
  });

  Money get unitPrice => Money(unitPricePaisa);
  Money get lineDiscount => Money(lineDiscountPaisa);
  Money get netTotal => Money(netTotalPaisa);
  Money get costPerPiece => Money(costPerPiecePaisa);
  Money get totalCost => Money(totalCostPaisa);
  Money get grossProfit => Money(netTotalPaisa - totalCostPaisa);

  String get packUnitLabel {
    switch (packUnit) {
      case PackUnit.piece:
        return 'Piece';
      case PackUnit.dozen:
        return 'Dozen (12 pcs)';
      case PackUnit.box:
        return 'Box ($piecesPerPack pcs)';
    }
  }

  String get packUnitShort {
    switch (packUnit) {
      case PackUnit.piece:
        return 'pcs';
      case PackUnit.dozen:
        return 'dz';
      case PackUnit.box:
        return 'bx';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'product_id': productId,
      'sku': sku,
      'product_name': productName,
      'color_spec': colorSpec,
      'image_path': imagePath,
      'pack_unit': packUnit.name,
      'pack_qty': packQty,
      'pieces_per_pack': piecesPerPack,
      'total_pieces': totalPieces,
      'unit_price_paisa': unitPricePaisa,
      'line_discount_paisa': lineDiscountPaisa,
      'net_total_paisa': netTotalPaisa,
      'cost_per_piece_paisa': costPerPiecePaisa,
      'total_cost_paisa': totalCostPaisa,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: map['product_id'] as int,
      sku: map['sku'] as String,
      productName: map['product_name'] as String,
      colorSpec: map['color_spec'] as String?,
      imagePath: map['image_path'] as String?,
      packUnit: PackUnit.values.firstWhere(
        (e) => e.name == map['pack_unit'],
        orElse: () => PackUnit.piece,
      ),
      packQty: map['pack_qty'] as int,
      piecesPerPack: map['pieces_per_pack'] as int,
      totalPieces: map['total_pieces'] as int,
      unitPricePaisa: (map['unit_price_paisa'] as int?) ?? 0,
      lineDiscountPaisa: (map['line_discount_paisa'] as int?) ?? 0,
      netTotalPaisa: (map['net_total_paisa'] as int?) ?? 0,
      costPerPiecePaisa: (map['cost_per_piece_paisa'] as int?) ?? 0,
      totalCostPaisa: (map['total_cost_paisa'] as int?) ?? 0,
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    String? sku,
    String? productName,
    String? colorSpec,
    String? imagePath,
    PackUnit? packUnit,
    int? packQty,
    int? piecesPerPack,
    int? totalPieces,
    int? unitPricePaisa,
    int? lineDiscountPaisa,
    int? netTotalPaisa,
    int? costPerPiecePaisa,
    int? totalCostPaisa,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      productName: productName ?? this.productName,
      colorSpec: colorSpec ?? this.colorSpec,
      imagePath: imagePath ?? this.imagePath,
      packUnit: packUnit ?? this.packUnit,
      packQty: packQty ?? this.packQty,
      piecesPerPack: piecesPerPack ?? this.piecesPerPack,
      totalPieces: totalPieces ?? this.totalPieces,
      unitPricePaisa: unitPricePaisa ?? this.unitPricePaisa,
      lineDiscountPaisa: lineDiscountPaisa ?? this.lineDiscountPaisa,
      netTotalPaisa: netTotalPaisa ?? this.netTotalPaisa,
      costPerPiecePaisa: costPerPiecePaisa ?? this.costPerPiecePaisa,
      totalCostPaisa: totalCostPaisa ?? this.totalCostPaisa,
    );
  }
}
