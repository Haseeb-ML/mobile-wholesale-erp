import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';

class AddEditPartyScreen extends StatefulWidget {
  final Party? partyToEdit;
  final PartyType initialType;

  const AddEditPartyScreen({super.key, this.partyToEdit, this.initialType = PartyType.customer});

  @override
  State<AddEditPartyScreen> createState() => _AddEditPartyScreenState();
}

class _AddEditPartyScreenState extends State<AddEditPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  late PartyType _type;
  late TextEditingController _nameCtrl;
  late TextEditingController _contactPersonCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _creditLimitCtrl;
  late TextEditingController _termsCtrl;
  late TextEditingController _openingBalCtrl;
  late TextEditingController _notesCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.partyToEdit;
    _type = p?.type ?? widget.initialType;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _contactPersonCtrl = TextEditingController(text: p?.contactPerson ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _cityCtrl = TextEditingController(text: p?.city ?? 'Karachi');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _creditLimitCtrl = TextEditingController(text: p != null ? (p.creditLimitPaisa / 100).toStringAsFixed(0) : '100000');
    _termsCtrl = TextEditingController(text: p?.paymentTerms ?? 'Net 15 Days');
    _openingBalCtrl = TextEditingController(text: p != null ? (p.openingBalancePaisa / 100).toStringAsFixed(0) : '0');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _creditLimitCtrl.dispose();
    _termsCtrl.dispose();
    _openingBalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final creditLimitPaisa = ((double.tryParse(_creditLimitCtrl.text.trim()) ?? 0) * 100).round();
      final openingBalPaisa = ((double.tryParse(_openingBalCtrl.text.trim()) ?? 0) * 100).round();

      final p = widget.partyToEdit;
      final party = Party(
        id: p?.id,
        type: _type,
        name: _nameCtrl.text.trim(),
        contactPerson: _contactPersonCtrl.text.trim().isNotEmpty ? _contactPersonCtrl.text.trim() : null,
        phone: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
        address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        creditLimitPaisa: creditLimitPaisa,
        paymentTerms: _termsCtrl.text.trim().isNotEmpty ? _termsCtrl.text.trim() : null,
        openingBalancePaisa: p != null ? p.openingBalancePaisa : openingBalPaisa,
        currentBalancePaisa: p != null ? p.currentBalancePaisa : openingBalPaisa,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        createdAt: p?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await context.read<PartyProvider>().saveParty(party);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = _type == PartyType.customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partyToEdit != null
            ? 'Edit ${isCustomer ? "Customer" : "Supplier"}'
            : 'Add ${isCustomer ? "Customer (Dealer)" : "Supplier"}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: isCustomer ? 'Dealer / Shop Name *' : 'Supplier Business Name *',
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactPersonCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Person'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone / WhatsApp *'),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City / Market'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Plaza / Shop Address'),
                    ),
                  ),
                ],
              ),
              if (isCustomer) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _creditLimitCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Credit Limit (PKR)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _termsCtrl,
                        decoration: const InputDecoration(labelText: 'Payment Terms'),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.partyToEdit == null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _openingBalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isCustomer ? 'Opening Due from Customer (PKR)' : 'Opening Payable to Supplier (PKR)',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes / Remarks'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Party'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
