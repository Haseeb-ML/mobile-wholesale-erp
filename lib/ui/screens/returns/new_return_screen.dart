import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';
import 'package:mobile_wholesale_erp/models/return_order.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';

class NewReturnScreen extends StatefulWidget {
  const NewReturnScreen({super.key});

  @override
  State<NewReturnScreen> createState() => _NewReturnScreenState();
}

class _NewReturnScreenState extends State<NewReturnScreen> {
  List<Invoice> _postedInvoices = [];
  Invoice? _selectedInvoice;
  List<InvoiceItem> _invoiceItems = [];
  InvoiceItem? _selectedItem;

  int _returnPieces = 1;
  bool _isSaleable = true;
  final TextEditingController _refundCashCtrl = TextEditingController(text: '0');
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPostedInvoices();
  }

  @override
  void dispose() {
    _refundCashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPostedInvoices() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('invoices', where: 'status = ?', whereArgs: ['posted'], orderBy: 'date DESC', limit: 30);
    setState(() {
      _postedInvoices = rows.map((e) => Invoice.fromMap(e)).toList();
    });
  }

  Future<void> _onInvoiceSelected(Invoice? inv) async {
    setState(() {
      _selectedInvoice = inv;
      _selectedItem = null;
      _invoiceItems = [];
    });
    if (inv != null) {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [inv.id]);
      setState(() {
        _invoiceItems = rows.map((e) => InvoiceItem.fromMap(e)).toList();
      });
    }
  }

  Future<void> _submitReturn() async {
    if (_selectedInvoice == null || _selectedItem == null) return;
    if (_returnPieces <= 0 || _returnPieces > _selectedItem!.totalPieces) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return quantity must be between 1 and ${_selectedItem!.totalPieces} pieces.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final unitRate = _selectedItem!.unitPricePaisa;
      final totalCreditPaisa = _returnPieces * unitRate;
      final refundPaisa = ((double.tryParse(_refundCashCtrl.text.trim()) ?? 0) * 100).round();

      final retNumber = 'SRTN-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, "0")}-${DateTime.now().millisecondsSinceEpoch % 10000}';

      final returnOrder = ReturnOrder(
        returnType: ReturnType.salesReturn,
        returnNumber: retNumber,
        originalDocumentId: _selectedInvoice!.id!,
        originalDocumentNumber: _selectedInvoice!.invoiceNumber,
        partyId: _selectedInvoice!.customerId ?? 1, // Fallback to walkin
        partyName: _selectedInvoice!.customerName,
        date: DateTime.now().toIso8601String().split('T').first,
        totalCreditPaisa: totalCreditPaisa,
        refundedCashPaisa: refundPaisa,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        createdAt: DateTime.now().toIso8601String(),
        items: [
          ReturnItem(
            productId: _selectedItem!.productId,
            sku: _selectedItem!.sku,
            productName: _selectedItem!.productName,
            packUnit: PackUnit.piece,
            packQty: _returnPieces,
            piecesPerPack: 1,
            totalPieces: _returnPieces,
            isSaleable: _isSaleable,
            unitCreditRatePaisa: unitRate,
            netCreditPaisa: totalCreditPaisa,
            costPerPiecePaisa: _selectedItem!.costPerPiecePaisa,
          ),
        ],
      );

      await AccountingService.instance.processSalesReturn(returnOrder);

      if (mounted) {
        await context.read<CatalogProvider>().loadProducts();
        await context.read<PartyProvider>().loadParties();
        await context.read<DashboardProvider>().refresh();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Return $retNumber processed successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing return: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Customer Return'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Invoice>(
              value: _selectedInvoice,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Select Original Sales Invoice *'),
              items: _postedInvoices.map((inv) {
                return DropdownMenuItem(
                  value: inv,
                  child: Text('${inv.invoiceNumber} - ${inv.customerName} (${inv.date})', maxLines: 1, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: _onInvoiceSelected,
            ),
            const SizedBox(height: 12),

            if (_invoiceItems.isNotEmpty) ...[
              DropdownButtonFormField<InvoiceItem>(
                value: _selectedItem,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Item to Return *'),
                items: _invoiceItems.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text('${item.productName} (Billed: ${item.totalPieces} pcs @ PKR ${(item.unitPricePaisa / 100).toStringAsFixed(0)})', maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (item) {
                  setState(() {
                    _selectedItem = item;
                    _returnPieces = 1;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            if (_selectedItem != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Return Pieces (Max: ${_selectedItem!.totalPieces}):', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _returnPieces > 1 ? () => setState(() => _returnPieces--) : null,
                      ),
                      Text('$_returnPieces pcs', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _returnPieces < _selectedItem!.totalPieces ? () => setState(() => _returnPieces++) : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text('Item Condition (Inventory Routing):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Saleable (Adds to stock)', style: TextStyle(fontSize: 12)),
                      value: true,
                      groupValue: _isSaleable,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _isSaleable = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Damaged (Quarantined)', style: TextStyle(fontSize: 12)),
                      value: false,
                      groupValue: _isSaleable,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _isSaleable = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Credit Note Value:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      'PKR ${((_returnPieces * _selectedItem!.unitPricePaisa) / 100).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryTeal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _refundCashCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Immediate Cash Refunded to Customer (PKR)'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Return Reason / Notes (e.g. Defective mic / Changed mind)'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitReturn,
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Return Document'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

