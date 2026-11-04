import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';

class PartyPaymentDialog extends StatefulWidget {
  final bool isCustomerReceipt;
  final Party? preselectedParty;

  const PartyPaymentDialog({
    super.key,
    required this.isCustomerReceipt,
    this.preselectedParty,
  });

  static Future<void> show(BuildContext context, {required bool isCustomerReceipt, Party? preselectedParty}) async {
    await showDialog(
      context: context,
      builder: (ctx) => PartyPaymentDialog(
        isCustomerReceipt: isCustomerReceipt,
        preselectedParty: preselectedParty,
      ),
    );
  }

  @override
  State<PartyPaymentDialog> createState() => _PartyPaymentDialogState();
}

class _PartyPaymentDialogState extends State<PartyPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  Party? _selectedParty;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _refCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _accountType = 'cash'; // 'cash' or 'bank'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedParty = widget.preselectedParty;
    if (_selectedParty != null && _selectedParty!.currentBalancePaisa > 0) {
      _amountCtrl.text = (_selectedParty!.currentBalancePaisa / 100).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedParty == null) return;

    final amountPaisa = ((double.tryParse(_amountCtrl.text.trim()) ?? 0) * 100).round();
    if (amountPaisa <= 0) return;

    setState(() => _isSaving = true);
    final partyProv = context.read<PartyProvider>();
    final today = DateTime.now().toIso8601String().split('T').first;

    try {
      if (widget.isCustomerReceipt) {
        await partyProv.receivePayment(
          customerId: _selectedParty!.id!,
          customerName: _selectedParty!.name,
          amountPaisa: amountPaisa,
          accountType: _accountType,
          date: today,
          refNumber: _refCtrl.text.trim().isNotEmpty ? _refCtrl.text.trim() : null,
          notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        );
      } else {
        await partyProv.makeSupplierPayment(
          supplierId: _selectedParty!.id!,
          supplierName: _selectedParty!.name,
          amountPaisa: amountPaisa,
          accountType: _accountType,
          date: today,
          refNumber: _refCtrl.text.trim().isNotEmpty ? _refCtrl.text.trim() : null,
          notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        );
      }

      if (mounted) {
        await context.read<DashboardProvider>().refresh();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isCustomerReceipt ? 'Customer receipt saved!' : 'Supplier payment recorded!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partyProv = context.watch<PartyProvider>();
    final partiesList = widget.isCustomerReceipt ? partyProv.customers : partyProv.suppliers;

    return AlertDialog(
      title: Text(
        widget.isCustomerReceipt ? context.tr('action_receive_payment') : context.tr('action_pay_supplier'),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Party>(
                value: _selectedParty,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: widget.isCustomerReceipt ? 'Select Customer (Dealer) *' : 'Select Supplier *',
                ),
                items: partiesList.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text('${p.name} (${p.currentBalance.format()})', maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (p) {
                  setState(() {
                    _selectedParty = p;
                    if (p != null && p.currentBalancePaisa > 0) {
                      _amountCtrl.text = (p.currentBalancePaisa / 100).toStringAsFixed(0);
                    }
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
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
                      title: const Text('Cash', style: TextStyle(fontSize: 12)),
                      value: 'cash',
                      groupValue: _accountType,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _accountType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Bank', style: TextStyle(fontSize: 12)),
                      value: 'bank',
                      groupValue: _accountType,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _accountType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(labelText: 'Ref / Cheque # (Optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
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
              : const Text('Save Payment'),
        ),
      ],
    );
  }
}

