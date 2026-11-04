import 'package:mobile_wholesale_erp/core/utils/money.dart';

enum PartyType { customer, supplier }

class Party {
  final int? id;
  final PartyType type;
  final String name; // Dealer Shop Name or Supplier Business Name
  final String? contactPerson;
  final String phone;
  final String? city;
  final String? address;
  final int creditLimitPaisa; // Max credit allowed (for customers)
  final String? paymentTerms; // e.g. "Net 15 Days", "Weekly Saturday", "Cash Only"
  final int openingBalancePaisa; // Opening balance
  final int currentBalancePaisa; // Current running balance in paisa
  final String? notes;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Party({
    this.id,
    required this.type,
    required this.name,
    this.contactPerson,
    required this.phone,
    this.city,
    this.address,
    this.creditLimitPaisa = 0,
    this.paymentTerms,
    this.openingBalancePaisa = 0,
    this.currentBalancePaisa = 0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Money get currentBalance => Money(currentBalancePaisa);
  Money get creditLimit => Money(creditLimitPaisa);
  Money get openingBalance => Money(openingBalancePaisa);

  bool get isCustomer => type == PartyType.customer;
  bool get isSupplier => type == PartyType.supplier;

  // For customer: positive = owes us (receivable), negative = advance
  // For supplier: positive = we owe supplier (payable), negative = supplier advance
  bool get hasOutstandingDue => currentBalancePaisa > 0;
  bool get hasAdvance => currentBalancePaisa < 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'city': city,
      'address': address,
      'credit_limit_paisa': creditLimitPaisa,
      'payment_terms': paymentTerms,
      'opening_balance_paisa': openingBalancePaisa,
      'current_balance_paisa': currentBalancePaisa,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['id'] as int?,
      type: (map['type'] == 'supplier') ? PartyType.supplier : PartyType.customer,
      name: map['name'] as String,
      contactPerson: map['contact_person'] as String?,
      phone: map['phone'] as String,
      city: map['city'] as String?,
      address: map['address'] as String?,
      creditLimitPaisa: (map['credit_limit_paisa'] as int?) ?? 0,
      paymentTerms: map['payment_terms'] as String?,
      openingBalancePaisa: (map['opening_balance_paisa'] as int?) ?? 0,
      currentBalancePaisa: (map['current_balance_paisa'] as int?) ?? 0,
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Party copyWith({
    int? id,
    PartyType? type,
    String? name,
    String? contactPerson,
    String? phone,
    String? city,
    String? address,
    int? creditLimitPaisa,
    String? paymentTerms,
    int? openingBalancePaisa,
    int? currentBalancePaisa,
    String? notes,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Party(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      creditLimitPaisa: creditLimitPaisa ?? this.creditLimitPaisa,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      openingBalancePaisa: openingBalancePaisa ?? this.openingBalancePaisa,
      currentBalancePaisa: currentBalancePaisa ?? this.currentBalancePaisa,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PartyLedgerEntry {
  final int? id;
  final int partyId;
  final String date;
  final String type; // 'opening', 'invoice', 'purchase_bill', 'receipt', 'payment', 'credit_note', 'debit_note'
  final int? refId;
  final String? refNumber;
  final int debitPaisa;
  final int creditPaisa;
  final int runningBalancePaisa;
  final String? notes;
  final String createdAt;

  PartyLedgerEntry({
    this.id,
    required this.partyId,
    required this.date,
    required this.type,
    this.refId,
    this.refNumber,
    required this.debitPaisa,
    required this.creditPaisa,
    required this.runningBalancePaisa,
    this.notes,
    required this.createdAt,
  });

  Money get debit => Money(debitPaisa);
  Money get credit => Money(creditPaisa);
  Money get runningBalance => Money(runningBalancePaisa);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'party_id': partyId,
      'date': date,
      'type': type,
      'ref_id': refId,
      'ref_number': refNumber,
      'debit_paisa': debitPaisa,
      'credit_paisa': creditPaisa,
      'running_balance_paisa': runningBalancePaisa,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory PartyLedgerEntry.fromMap(Map<String, dynamic> map) {
    return PartyLedgerEntry(
      id: map['id'] as int?,
      partyId: map['party_id'] as int,
      date: map['date'] as String,
      type: map['type'] as String,
      refId: map['ref_id'] as int?,
      refNumber: map['ref_number'] as String?,
      debitPaisa: (map['debit_paisa'] as int?) ?? 0,
      creditPaisa: (map['credit_paisa'] as int?) ?? 0,
      runningBalancePaisa: (map['running_balance_paisa'] as int?) ?? 0,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
