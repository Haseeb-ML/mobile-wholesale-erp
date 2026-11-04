import 'package:mobile_wholesale_erp/core/utils/money.dart';

class StockAdjustment {
  final int? id;
  final int productId;
  final String sku;
  final String productName;
  final int oldQtyPieces;
  final int newQtyPieces;
  final int diffQtyPieces; // newQty - oldQty
  final int costPerPiecePaisa;
  final int totalCostImpactPaisa;
  final String reason; // 'Physical Count Audit', 'Damaged Stock Found', 'Supplier Bonus', etc.
  final String date;
  final String createdBy;
  final String createdAt;

  StockAdjustment({
    this.id,
    required this.productId,
    required this.sku,
    required this.productName,
    required this.oldQtyPieces,
    required this.newQtyPieces,
    required this.diffQtyPieces,
    required this.costPerPiecePaisa,
    required this.totalCostImpactPaisa,
    required this.reason,
    required this.date,
    this.createdBy = 'Owner',
    required this.createdAt,
  });

  Money get costPerPiece => Money(costPerPiecePaisa);
  Money get totalCostImpact => Money(totalCostImpactPaisa);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'sku': sku,
      'product_name': productName,
      'old_qty_pieces': oldQtyPieces,
      'new_qty_pieces': newQtyPieces,
      'diff_qty_pieces': diffQtyPieces,
      'cost_per_piece_paisa': costPerPiecePaisa,
      'total_cost_impact_paisa': totalCostImpactPaisa,
      'reason': reason,
      'date': date,
      'created_by': createdBy,
      'created_at': createdAt,
    };
  }

  factory StockAdjustment.fromMap(Map<String, dynamic> map) {
    return StockAdjustment(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      sku: map['sku'] as String,
      productName: map['product_name'] as String,
      oldQtyPieces: map['old_qty_pieces'] as int,
      newQtyPieces: map['new_qty_pieces'] as int,
      diffQtyPieces: map['diff_qty_pieces'] as int,
      costPerPiecePaisa: (map['cost_per_piece_paisa'] as int?) ?? 0,
      totalCostImpactPaisa: (map['total_cost_impact_paisa'] as int?) ?? 0,
      reason: map['reason'] as String,
      date: map['date'] as String,
      createdBy: map['created_by'] as String? ?? 'Owner',
      createdAt: map['created_at'] as String,
    );
  }
}
