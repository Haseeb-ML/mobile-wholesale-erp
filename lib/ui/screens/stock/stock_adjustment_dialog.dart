import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/models/stock_adjustment.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';

class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const StockAdjustmentDialog(),
    );
  }

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  Product? _selectedProduct;
  final TextEditingController _newQtyCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController(text: 'Physical Stock Count Audit');
  bool _isSaving = false;

  @override
  void dispose() {
    _newQtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedProduct == null) return;
    final newQty = int.tryParse(_newQtyCtrl.text.trim());
    if (newQty == null || newQty < 0) return;
    if (_reasonCtrl.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final oldQty = _selectedProduct!.currentStockPieces;
      final diff = newQty - oldQty;
      final costPaisa = _selectedProduct!.costPricePaisa;
      final appState = context.read<AppState>();

      final adj = StockAdjustment(
        productId: _selectedProduct!.id!,
        sku: _selectedProduct!.sku,
        productName: _selectedProduct!.name,
        oldQtyPieces: oldQty,
        newQtyPieces: newQty,
        diffQtyPieces: diff,
        costPerPiecePaisa: costPaisa,
        totalCostImpactPaisa: diff * costPaisa,
        reason: _reasonCtrl.text.trim(),
        date: DateTime.now().toIso8601String().split('T').first,
        createdBy: appState.activeRole,
        createdAt: DateTime.now().toIso8601String(),
      );

      await context.read<CatalogProvider>().adjustStockCount(adj);
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
    final catalog = context.watch<CatalogProvider>();
    final products = catalog.allProducts;

    final currentQty = _selectedProduct?.currentStockPieces ?? 0;
    final inputQty = int.tryParse(_newQtyCtrl.text.trim()) ?? currentQty;
    final diff = inputQty - currentQty;

    return AlertDialog(
      title: const Text('Stock Count Adjustment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Select Accessory *'),
              items: products.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text('${p.name} (${p.currentStockPieces} pcs)', maxLines: 1, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (p) {
                setState(() {
                  _selectedProduct = p;
                  if (p != null) _newQtyCtrl.text = p.currentStockPieces.toString();
                });
              },
            ),
            const SizedBox(height: 12),
            if (_selectedProduct != null) ...[
              Text('Current System Stock: ${_selectedProduct!.currentStockPieces} pieces',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              TextField(
                controller: _newQtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Physically Counted Pieces *'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 6),
              Text(
                'Adjustment Difference: ${diff > 0 ? "+$diff" : "$diff"} pieces',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: diff == 0 ? AppColors.textMuted : (diff > 0 ? AppColors.success : AppColors.error),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(labelText: 'Mandatory Audit Reason *'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selectedProduct == null || _isSaving) ? null : _submit,
          child: const Text('Confirm Adjustment'),
        ),
      ],
    );
  }
}

