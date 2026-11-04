import 'package:mobile_wholesale_erp/core/utils/money.dart';

enum MovementType {
  opening,
  purchase,
  sale,
  saleReturnSaleable,
  saleReturnDamaged,
  purchaseReturn,
  adjustment,
  damagedWriteoff,
}

class InventoryMovement {
  final int? id;
  final int productId;
  final String sku;
  final String productName;
  final MovementType movementType;
  final int qtyPieces; // positive for additions, negative for reductions
  final int unitCostPaisa; // Moving avg cost or purchase cost at movement time
  final int totalCostPaisa; // qtyPieces.abs() * unitCostPaisa
  final int? refId; // invoice_id, purchase_id, return_id, or adjustment_id
  final String? refNumber;
  final String date;
  final String? reason;
  final String createdAt;

  InventoryMovement({
    this.id,
    required this.productId,
    required this.sku,
    required this.productName,
    required this.movementType,
    required this.qtyPieces,
    required this.unitCostPaisa,
    required this.totalCostPaisa,
    this.refId,
    this.refNumber,
    required this.date,
    this.reason,
    required this.createdAt,
  });

  Money get unitCost => Money(unitCostPaisa);
  Money get totalCost => Money(totalCostPaisa);

  String get typeLabel {
    switch (movementType) {
      case MovementType.opening:
        return 'Opening Stock';
      case MovementType.purchase:
        return 'Purchase Inward';
      case MovementType.sale:
        return 'Wholesale Sale';
      case MovementType.saleReturnSaleable:
        return 'Customer Return (Saleable)';
      case MovementType.saleReturnDamaged:
        return 'Customer Return (Damaged)';
      case MovementType.purchaseReturn:
        return 'Purchase Return Outward';
      case MovementType.adjustment:
        return 'Stock Count Adjustment';
      case MovementType.damagedWriteoff:
        return 'Damaged Stock Disposal';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'sku': sku,
      'product_name': productName,
      'movement_type': movementType.name,
      'qty_pieces': qtyPieces,
      'unit_cost_paisa': unitCostPaisa,
      'total_cost_paisa': totalCostPaisa,
      'ref_id': refId,
      'ref_number': refNumber,
      'date': date,
      'reason': reason,
      'created_at': createdAt,
    };
  }

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      sku: map['sku'] as String,
      productName: map['product_name'] as String,
      movementType: MovementType.values.firstWhere(
        (e) => e.name == map['movement_type'],
        orElse: () => MovementType.sale,
      ),
      qtyPieces: map['qty_pieces'] as int,
      unitCostPaisa: (map['unit_cost_paisa'] as int?) ?? 0,
      totalCostPaisa: (map['total_cost_paisa'] as int?) ?? 0,
      refId: map['ref_id'] as int?,
      refNumber: map['ref_number'] as String?,
      date: map['date'] as String,
      reason: map['reason'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
