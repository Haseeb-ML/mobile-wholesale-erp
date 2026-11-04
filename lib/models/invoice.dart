import 'package:mobile_wholesale_erp/core/utils/money.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';

enum InvoiceStatus { draft, posted, cancelled }
enum PaymentStatus { paid, partial, unpaid }

class Invoice {
  final int? id;
  final String invoiceNumber; // e.g. "INV-202611-0001"
  final String date;
  final int? customerId; // null = Walk-in cash customer
  final String customerName;
  final String? customerPhone;
  final InvoiceStatus status;
  final PaymentStatus paymentStatus;
  final int subtotalPaisa;
  final int discountPaisa;
  final int taxPaisa;
  final int grandTotalPaisa;
  final int paidPaisa;
  final int duePaisa;
  final int totalCostPaisa; // COGS for this invoice
  final String paymentMethod; // 'cash', 'bank', 'mixed', 'credit'
  final String? notes;
  final String createdBy;
  final String createdAt;
  final List<InvoiceItem> items;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.date,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.status,
    required this.paymentStatus,
    required this.subtotalPaisa,
    this.discountPaisa = 0,
    this.taxPaisa = 0,
    required this.grandTotalPaisa,
    this.paidPaisa = 0,
    required this.duePaisa,
    this.totalCostPaisa = 0,
    this.paymentMethod = 'cash',
    this.notes,
    this.createdBy = 'Owner',
    required this.createdAt,
    this.items = const [],
  });

  Money get subtotal => Money(subtotalPaisa);
  Money get discount => Money(discountPaisa);
  Money get tax => Money(taxPaisa);
  Money get grandTotal => Money(grandTotalPaisa);
  Money get paid => Money(paidPaisa);
  Money get due => Money(duePaisa);
  Money get totalCost => Money(totalCostPaisa);
  Money get grossProfit => Money(grandTotalPaisa - taxPaisa - totalCostPaisa);

  int get totalPieces => items.fold(0, (sum, item) => sum + item.totalPieces);

  bool get isDraft => status == InvoiceStatus.draft;
  bool get isPosted => status == InvoiceStatus.posted;
  bool get isCancelled => status == InvoiceStatus.cancelled;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'date': date,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'status': status.name,
      'payment_status': paymentStatus.name,
      'subtotal_paisa': subtotalPaisa,
      'discount_paisa': discountPaisa,
      'tax_paisa': taxPaisa,
      'grand_total_paisa': grandTotalPaisa,
      'paid_paisa': paidPaisa,
      'due_paisa': duePaisa,
      'total_cost_paisa': totalCostPaisa,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, {List<InvoiceItem> items = const []}) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      date: map['date'] as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.posted,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['payment_status'],
        orElse: () => PaymentStatus.unpaid,
      ),
      subtotalPaisa: (map['subtotal_paisa'] as int?) ?? 0,
      discountPaisa: (map['discount_paisa'] as int?) ?? 0,
      taxPaisa: (map['tax_paisa'] as int?) ?? 0,
      grandTotalPaisa: (map['grand_total_paisa'] as int?) ?? 0,
      paidPaisa: (map['paid_paisa'] as int?) ?? 0,
      duePaisa: (map['due_paisa'] as int?) ?? 0,
      totalCostPaisa: (map['total_cost_paisa'] as int?) ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as String? ?? 'Owner',
      createdAt: map['created_at'] as String,
      items: items,
    );
  }

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    String? date,
    int? customerId,
    String? customerName,
    String? customerPhone,
    InvoiceStatus? status,
    PaymentStatus? paymentStatus,
    int? subtotalPaisa,
    int? discountPaisa,
    int? taxPaisa,
    int? grandTotalPaisa,
    int? paidPaisa,
    int? duePaisa,
    int? totalCostPaisa,
    String? paymentMethod,
    String? notes,
    String? createdBy,
    String? createdAt,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotalPaisa: subtotalPaisa ?? this.subtotalPaisa,
      discountPaisa: discountPaisa ?? this.discountPaisa,
      taxPaisa: taxPaisa ?? this.taxPaisa,
      grandTotalPaisa: grandTotalPaisa ?? this.grandTotalPaisa,
      paidPaisa: paidPaisa ?? this.paidPaisa,
      duePaisa: duePaisa ?? this.duePaisa,
      totalCostPaisa: totalCostPaisa ?? this.totalCostPaisa,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}

