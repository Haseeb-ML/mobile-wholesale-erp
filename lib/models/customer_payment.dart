import 'package:mobile_wholesale_erp/core/utils/money.dart';

enum PaymentType { customerReceipt, supplierPayment }

class PartyPayment {
  final int? id;
  final PaymentType paymentType;
  final String receiptNumber; // e.g. "RCT-202611-0001" or "PAY-202611-0001"
  final String date;
  final int partyId;
  final String partyName;
  final int amountPaisa;
  final String accountType; // 'cash' or 'bank'
  final String? refNumber; // Cheque / bank transaction ref
  final String? notes;
  final String createdAt;

  PartyPayment({
    this.id,
    required this.paymentType,
    required this.receiptNumber,
    required this.date,
    required this.partyId,
    required this.partyName,
    required this.amountPaisa,
    required this.accountType,
    this.refNumber,
    this.notes,
    required this.createdAt,
  });

  Money get amount => Money(amountPaisa);

  bool get isCustomerReceipt => paymentType == PaymentType.customerReceipt;
  bool get isSupplierPayment => paymentType == PaymentType.supplierPayment;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'payment_type': paymentType.name,
      'receipt_number': receiptNumber,
      'date': date,
      'party_id': partyId,
      'party_name': partyName,
      'amount_paisa': amountPaisa,
      'account_type': accountType,
      'ref_number': refNumber,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory PartyPayment.fromMap(Map<String, dynamic> map) {
    return PartyPayment(
      id: map['id'] as int?,
      paymentType: (map['payment_type'] == 'supplierPayment')
          ? PaymentType.supplierPayment
          : PaymentType.customerReceipt,
      receiptNumber: map['receipt_number'] as String,
      date: map['date'] as String,
      partyId: map['party_id'] as int,
      partyName: map['party_name'] as String,
      amountPaisa: (map['amount_paisa'] as int?) ?? 0,
      accountType: map['account_type'] as String? ?? 'cash',
      refNumber: map['ref_number'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}

