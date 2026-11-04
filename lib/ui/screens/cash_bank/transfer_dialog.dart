import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';

class TransferDialog extends StatefulWidget {
  const TransferDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const TransferDialog(),
    );
  }

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _fromAccount = 'cash';
  String _toAccount = 'bank';
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccount == _toAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and Destination accounts must be different.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final amountPaisa = ((double.tryParse(_amountCtrl.text.trim()) ?? 0) * 100).round();
    if (amountPaisa <= 0) return;

    setState(() => _isSaving = true);
    try {
      await AccountingService.instance.transferFunds(
        fromAccountId: _fromAccount,
        toAccountId: _toAccount,
        amountPaisa: amountPaisa,
        date: DateTime.now().toIso8601String().split('T').first,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );

      if (mounted) {
        await context.read<DashboardProvider>().refresh();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funds transferred successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer Funds (Contra)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _fromAccount,
                decoration: const InputDecoration(labelText: 'From Account *'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash in Shop')),
                  DropdownMenuItem(value: 'bank', child: Text('Meezan Bank Account')),
                ],
                onChanged: (v) => setState(() => _fromAccount = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _toAccount,
                decoration: const InputDecoration(labelText: 'To Account *'),
                items: const [
                  DropdownMenuItem(value: 'bank', child: Text('Meezan Bank Account')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash in Shop')),
                ],
                onChanged: (v) => setState(() => _toAccount = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Transfer Amount (PKR) *'),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid amount' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Deposit Slip / Notes (Optional)'),
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
              : const Text('Confirm Transfer'),
        ),
      ],
    );
  }
}

