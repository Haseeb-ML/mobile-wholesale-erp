import 'package:mobile_wholesale_erp/core/utils/money.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';

class PurchaseItem {
  final int? id;
  final int? purchaseId;
  final int productId;
  final String sku;
  final String productName;
  final String? colorSpec;
  final PackUnit packUnit;
  final int packQty;
  final int piecesPerPack;
  final int totalPieces;
  final int unitRatePaisa; // Purchase cost per piece
  final int lineDiscountPaisa;
  final int netTotalPaisa;

  PurchaseItem({
    this.id,
    this.purchaseId,
    required this.productId,
    required this.sku,
    required this.productName,
    this.colorSpec,
    required this.packUnit,
    required this.packQty,
    required this.piecesPerPack,
    required this.totalPieces,
    required this.unitRatePaisa,
    this.lineDiscountPaisa = 0,
    required this.netTotalPaisa,
  });

  Money get unitRate => Money(unitRatePaisa);
  Money get lineDiscount => Money(lineDiscountPaisa);
  Money get netTotal => Money(netTotalPaisa);

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

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (purchaseId != null) 'purchase_id': purchaseId,
      'product_id': productId,
      'sku': sku,
      'product_name': productName,
      'color_spec': colorSpec,
      'pack_unit': packUnit.name,
      'pack_qty': packQty,
      'pieces_per_pack': piecesPerPack,
      'total_pieces': totalPieces,
      'unit_rate_paisa': unitRatePaisa,
      'line_discount_paisa': lineDiscountPaisa,
      'net_total_paisa': netTotalPaisa,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int?,
      productId: map['product_id'] as int,
      sku: map['sku'] as String,
      productName: map['product_name'] as String,
      colorSpec: map['color_spec'] as String?,
      packUnit: PackUnit.values.firstWhere(
        (e) => e.name == map['pack_unit'],
        orElse: () => PackUnit.piece,
      ),
      packQty: map['pack_qty'] as int,
      piecesPerPack: map['pieces_per_pack'] as int,
      totalPieces: map['total_pieces'] as int,
      unitRatePaisa: (map['unit_rate_paisa'] as int?) ?? 0,
      lineDiscountPaisa: (map['line_discount_paisa'] as int?) ?? 0,
      netTotalPaisa: (map['net_total_paisa'] as int?) ?? 0,
    );
  }
}
