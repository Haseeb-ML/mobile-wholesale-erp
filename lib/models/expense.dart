import 'package:mobile_wholesale_erp/core/utils/money.dart';

class Expense {
  final int? id;
  final String category; // 'Shop Rent', 'Staff Salary', 'Transport & Freight', 'Electricity & Bills', 'Refreshment & Tea', 'Miscellaneous'
  final int amountPaisa;
  final String accountId; // 'cash' or 'bank'
  final String date;
  final String? notes;
  final String createdAt;

  Expense({
    this.id,
    required this.category,
    required this.amountPaisa,
    this.accountId = 'cash',
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Money get amount => Money(amountPaisa);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'amount_paisa': amountPaisa,
      'account_id': accountId,
      'date': date,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      category: map['category'] as String,
      amountPaisa: (map['amount_paisa'] as int?) ?? 0,
      accountId: map['account_id'] as String? ?? 'cash',
      date: map['date'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}

