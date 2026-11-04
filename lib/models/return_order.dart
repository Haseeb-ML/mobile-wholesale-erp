import 'package:mobile_wholesale_erp/core/utils/money.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';

enum ReturnType { salesReturn, purchaseReturn }

class ReturnItem {
  final int? id;
  final int? returnOrderId;
  final int productId;
  final String sku;
  final String productName;
  final PackUnit packUnit;
  final int packQty;
  final int piecesPerPack;
  final int totalPieces;
  final bool isSaleable; // If true, returned to available stock; if false, goes to damaged bucket
  final int unitCreditRatePaisa;
  final int netCreditPaisa;
  final int costPerPiecePaisa; // Valuation cost for stock movement

  ReturnItem({
    this.id,
    this.returnOrderId,
    required this.productId,
    required this.sku,
    required this.productName,
    required this.packUnit,
    required this.packQty,
    required this.piecesPerPack,
    required this.totalPieces,
    this.isSaleable = true,
    required this.unitCreditRatePaisa,
    required this.netCreditPaisa,
    required this.costPerPiecePaisa,
  });

  Money get unitCreditRate => Money(unitCreditRatePaisa);
  Money get netCredit => Money(netCreditPaisa);
  Money get costPerPiece => Money(costPerPiecePaisa);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (returnOrderId != null) 'return_order_id': returnOrderId,
      'product_id': productId,
      'sku': sku,
      'product_name': productName,
      'pack_unit': packUnit.name,
      'pack_qty': packQty,
      'pieces_per_pack': piecesPerPack,
      'total_pieces': totalPieces,
      'is_saleable': isSaleable ? 1 : 0,
      'unit_credit_rate_paisa': unitCreditRatePaisa,
      'net_credit_paisa': netCreditPaisa,
      'cost_per_piece_paisa': costPerPiecePaisa,
    };
  }

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      id: map['id'] as int?,
      returnOrderId: map['return_order_id'] as int?,
      productId: map['product_id'] as int,
      sku: map['sku'] as String,
      productName: map['product_name'] as String,
      packUnit: PackUnit.values.firstWhere(
        (e) => e.name == map['pack_unit'],
        orElse: () => PackUnit.piece,
      ),
      packQty: map['pack_qty'] as int,
      piecesPerPack: map['pieces_per_pack'] as int,
      totalPieces: map['total_pieces'] as int,
      isSaleable: (map['is_saleable'] as int?) != 0,
      unitCreditRatePaisa: (map['unit_credit_rate_paisa'] as int?) ?? 0,
      netCreditPaisa: (map['net_credit_paisa'] as int?) ?? 0,
      costPerPiecePaisa: (map['cost_per_piece_paisa'] as int?) ?? 0,
    );
  }

  ReturnItem copyWith({
    int? id,
    int? returnOrderId,
    int? productId,
    String? sku,
    String? productName,
    PackUnit? packUnit,
    int? packQty,
    int? piecesPerPack,
    int? totalPieces,
    bool? isSaleable,
    int? unitCreditRatePaisa,
    int? netCreditPaisa,
    int? costPerPiecePaisa,
  }) {
    return ReturnItem(
      id: id ?? this.id,
      returnOrderId: returnOrderId ?? this.returnOrderId,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      productName: productName ?? this.productName,
      packUnit: packUnit ?? this.packUnit,
      packQty: packQty ?? this.packQty,
      piecesPerPack: piecesPerPack ?? this.piecesPerPack,
      totalPieces: totalPieces ?? this.totalPieces,
      isSaleable: isSaleable ?? this.isSaleable,
      unitCreditRatePaisa: unitCreditRatePaisa ?? this.unitCreditRatePaisa,
      netCreditPaisa: netCreditPaisa ?? this.netCreditPaisa,
      costPerPiecePaisa: costPerPiecePaisa ?? this.costPerPiecePaisa,
    );
  }
}

class ReturnOrder {
  final int? id;
  final ReturnType returnType;
  final String returnNumber; // e.g. "SRTN-202611-0001" or "PRTN-202611-0001"
  final int originalDocumentId; // original invoice_id or purchase_id
  final String originalDocumentNumber;
  final int partyId;
  final String partyName;
  final String date;
  final int totalCreditPaisa;
  final int refundedCashPaisa; // If actual cash was refunded to party immediately
  final String? notes;
  final String createdAt;
  final List<ReturnItem> items;

  ReturnOrder({
    this.id,
    required this.returnType,
    required this.returnNumber,
    required this.originalDocumentId,
    required this.originalDocumentNumber,
    required this.partyId,
    required this.partyName,
    required this.date,
    required this.totalCreditPaisa,
    this.refundedCashPaisa = 0,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  Money get totalCredit => Money(totalCreditPaisa);
  Money get refundedCash => Money(refundedCashPaisa);

  bool get isSalesReturn => returnType == ReturnType.salesReturn;
  bool get isPurchaseReturn => returnType == ReturnType.purchaseReturn;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'return_type': returnType.name,
      'return_number': returnNumber,
      'original_document_id': originalDocumentId,
      'original_document_number': originalDocumentNumber,
      'party_id': partyId,
      'party_name': partyName,
      'date': date,
      'total_credit_paisa': totalCreditPaisa,
      'refunded_cash_paisa': refundedCashPaisa,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory ReturnOrder.fromMap(Map<String, dynamic> map, {List<ReturnItem> items = const []}) {
    return ReturnOrder(
      id: map['id'] as int?,
      returnType: (map['return_type'] == 'purchaseReturn')
          ? ReturnType.purchaseReturn
          : ReturnType.salesReturn,
      returnNumber: map['return_number'] as String,
      originalDocumentId: map['original_document_id'] as int,
      originalDocumentNumber: map['original_document_number'] as String,
      partyId: map['party_id'] as int,
      partyName: map['party_name'] as String,
      date: map['date'] as String,
      totalCreditPaisa: (map['total_credit_paisa'] as int?) ?? 0,
      refundedCashPaisa: (map['refunded_cash_paisa'] as int?) ?? 0,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      items: items,
    );
  }
}
