import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/models/expense.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const AddExpenseDialog(),
    );
  }

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _selectedCategory = 'Refreshment & Tea';
  String _accountId = 'cash'; // 'cash' or 'bank'
  bool _isSaving = false;

  final List<String> _categories = [
    'Refreshment & Tea',
    'Transport & Freight',
    'Shop Rent',
    'Electricity & Bills',
    'Staff Salary',
    'Miscellaneous',
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amountPaisa = ((double.tryParse(_amountCtrl.text.trim()) ?? 0) * 100).round();
    if (amountPaisa <= 0) return;

    setState(() => _isSaving = true);
    try {
      final exp = Expense(
        category: _selectedCategory,
        amountPaisa: amountPaisa,
        accountId: _accountId,
        date: DateTime.now().toIso8601String().split('T').first,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        createdAt: DateTime.now().toIso8601String(),
      );

      await AccountingService.instance.recordExpense(exp);
      if (mounted) {
        await context.read<DashboardProvider>().refresh();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense recorded successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Shop Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Expense Category *'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (PKR) *'),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid amount' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Cash in Shop', style: TextStyle(fontSize: 12)),
                      value: 'cash',
                      groupValue: _accountId,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _accountId = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Bank Account', style: TextStyle(fontSize: 12)),
                      value: 'bank',
                      groupValue: _accountId,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _accountId = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Description / Notes (Optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Expense'),
        ),
      ],
    );
  }
}
