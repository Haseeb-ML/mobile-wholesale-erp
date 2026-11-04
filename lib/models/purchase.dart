import 'package:mobile_wholesale_erp/core/utils/money.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/models/purchase_item.dart';

enum PurchaseStatus { draft, received, cancelled }

class Purchase {
  final int? id;
  final String refNumber; // Supplier bill / ref number or PUR-202611-0001
  final String date;
  final int supplierId;
  final String supplierName;
  final PurchaseStatus status;
  final PaymentStatus paymentStatus;
  final int subtotalPaisa;
  final int discountPaisa;
  final int freightPaisa; // Transport / freight cost allocated
  final int grandTotalPaisa;
  final int paidPaisa;
  final int duePaisa;
  final String paymentMethod; // 'cash', 'bank', 'credit'
  final String? notes;
  final String createdAt;
  final List<PurchaseItem> items;

  Purchase({
    this.id,
    required this.refNumber,
    required this.date,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.paymentStatus,
    required this.subtotalPaisa,
    this.discountPaisa = 0,
    this.freightPaisa = 0,
    required this.grandTotalPaisa,
    this.paidPaisa = 0,
    required this.duePaisa,
    this.paymentMethod = 'credit',
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  Money get subtotal => Money(subtotalPaisa);
  Money get discount => Money(discountPaisa);
  Money get freight => Money(freightPaisa);
  Money get grandTotal => Money(grandTotalPaisa);
  Money get paid => Money(paidPaisa);
  Money get due => Money(duePaisa);

  int get totalPieces => items.fold(0, (sum, item) => sum + item.totalPieces);

  bool get isDraft => status == PurchaseStatus.draft;
  bool get isReceived => status == PurchaseStatus.received;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ref_number': refNumber,
      'date': date,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'status': status.name,
      'payment_status': paymentStatus.name,
      'subtotal_paisa': subtotalPaisa,
      'discount_paisa': discountPaisa,
      'freight_paisa': freightPaisa,
      'grand_total_paisa': grandTotalPaisa,
      'paid_paisa': paidPaisa,
      'due_paisa': duePaisa,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map, {List<PurchaseItem> items = const []}) {
    return Purchase(
      id: map['id'] as int?,
      refNumber: map['ref_number'] as String,
      date: map['date'] as String,
      supplierId: map['supplier_id'] as int,
      supplierName: map['supplier_name'] as String,
      status: PurchaseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PurchaseStatus.received,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['payment_status'],
        orElse: () => PaymentStatus.unpaid,
      ),
      subtotalPaisa: (map['subtotal_paisa'] as int?) ?? 0,
      discountPaisa: (map['discount_paisa'] as int?) ?? 0,
      freightPaisa: (map['freight_paisa'] as int?) ?? 0,
      grandTotalPaisa: (map['grand_total_paisa'] as int?) ?? 0,
      paidPaisa: (map['paid_paisa'] as int?) ?? 0,
      duePaisa: (map['due_paisa'] as int?) ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'credit',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      items: items,
    );
  }
}
