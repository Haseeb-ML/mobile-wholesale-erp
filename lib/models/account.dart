import 'package:mobile_wholesale_erp/core/utils/money.dart';

enum AccountType { cash, bank, wallet }

class FinancialAccount {
  final String id; // 'cash', 'bank', etc.
  final String name;
  final AccountType type;
  final int balancePaisa;
  final String? accountNumber;
  final String? bankName;

  FinancialAccount({
    required this.id,
    required this.name,
    required this.type,
    this.balancePaisa = 0,
    this.accountNumber,
    this.bankName,
  });

  Money get balance => Money(balancePaisa);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance_paisa': balancePaisa,
      'account_number': accountNumber,
      'bank_name': bankName,
    };
  }

  factory FinancialAccount.fromMap(Map<String, dynamic> map) {
    return FinancialAccount(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.cash,
      ),
      balancePaisa: (map['balance_paisa'] as int?) ?? 0,
      accountNumber: map['account_number'] as String?,
      bankName: map['bank_name'] as String?,
    );
  }
}

class AccountTransaction {
  final int? id;
  final String accountId; // 'cash' or 'bank'
  final String date;
  final String type; // 'opening', 'sale_paid', 'customer_receipt', 'purchase_paid', 'supplier_payment', 'expense', 'transfer_in', 'transfer_out'
  final int? refId;
  final String? refNumber;
  final int debitPaisa; // Money in
  final int creditPaisa; // Money out
  final int runningBalancePaisa;
  final String? notes;
  final String createdAt;

  AccountTransaction({
    this.id,
    required this.accountId,
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
      'account_id': accountId,
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

  factory AccountTransaction.fromMap(Map<String, dynamic> map) {
    return AccountTransaction(
      id: map['id'] as int?,
      accountId: map['account_id'] as String,
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

