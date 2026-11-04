import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';
import 'package:mobile_wholesale_erp/providers/purchase_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/product_image_widget.dart';

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final TextEditingController _refCtrl = TextEditingController();
  final TextEditingController _freightCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _refCtrl.dispose();
    _freightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showAddItemDialog(Product product) {
    PackUnit selectedUnit = PackUnit.box;
    int packQty = 1;
    final unitCostCtrl = TextEditingController(text: (product.costPricePaisa / 100).toStringAsFixed(0));
    final pur = context.read<PurchaseProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final piecesPerPack = selectedUnit == PackUnit.piece
                ? 1
                : selectedUnit == PackUnit.dozen
                    ? 12
                    : product.piecesPerBox;
            final totalPieces = packQty * piecesPerPack;
            final costPerPiece = double.tryParse(unitCostCtrl.text.trim()) ?? 0;
            final lineTotalPkr = totalPieces * costPerPiece;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProductImageWidget(
                        imagePath: product.imagePath,
                        category: product.category,
                        productName: product.name,
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Current Stock: ${product.currentStockPieces} pcs',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Packing Unit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _unitOption('Piece (1 pc)', selectedUnit == PackUnit.piece, () => setModalState(() => selectedUnit = PackUnit.piece)),
                      const SizedBox(width: 6),
                      _unitOption('Dozen (12 pcs)', selectedUnit == PackUnit.dozen, () => setModalState(() => selectedUnit = PackUnit.dozen)),
                      const SizedBox(width: 6),
                      _unitOption('Box (${product.piecesPerBox} pcs)', selectedUnit == PackUnit.box, () => setModalState(() => selectedUnit = PackUnit.box)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Packs Qty *'),
                          controller: TextEditingController(text: packQty.toString()),
                          onChanged: (v) {
                            final q = int.tryParse(v) ?? 1;
                            setModalState(() => packQty = q);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: unitCostCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cost / Piece (PKR) *'),
                          onChanged: (_) => setModalState(() {}),
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
                        Text('Total: $totalPieces pcs in $packQty ${selectedUnit.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('PKR ${lineTotalPkr.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryTeal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final costPaisa = ((double.tryParse(unitCostCtrl.text.trim()) ?? 0) * 100).round();
                        pur.addOrUpdateItem(
                          product: product,
                          packUnit: selectedUnit,
                          packQty: packQty,
                          unitCostPerPiecePaisa: costPaisa,
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add to Purchase Bill'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _unitOption(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryTealLight : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primaryTeal : AppColors.borderLight),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? AppColors.primaryTealDark : AppColors.headingNavy),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitPurchase() async {
    final pur = context.read<PurchaseProvider>();
    pur.setRefNumber(_refCtrl.text.trim());
    pur.setNotes(_notesCtrl.text.trim());

    try {
      await pur.postPurchaseBill();
      if (mounted) {
        await context.read<CatalogProvider>().loadProducts();
        await context.read<PartyProvider>().loadParties();
        await context.read<DashboardProvider>().refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase Bill posted successfully! Inventory updated.'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pur = context.watch<PurchaseProvider>();
    final catalog = context.watch<CatalogProvider>();
    final parties = context.watch<PartyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('purchase_new')),
      ),
      body: Column(
        children: [
          // Supplier & Ref Row
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<Party>(
                  value: pur.selectedSupplier,
                  decoration: InputDecoration(labelText: context.tr('purchase_supplier') + ' *'),
                  isExpanded: true,
                  items: parties.suppliers.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.name));
                  }).toList(),
                  onChanged: (s) => pur.selectSupplier(s),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _refCtrl,
                        decoration: InputDecoration(labelText: context.tr('purchase_ref_no')),
                        onChanged: (v) => pur.setRefNumber(v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _freightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: context.tr('purchase_freight')),
                        onChanged: (v) {
                          final fPaisa = ((double.tryParse(v) ?? 0) * 100).round();
                          pur.setFreight(fPaisa);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Bill Items & Product picker
          Expanded(
            child: Row(
              children: [
                // Bill Cart
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        color: AppColors.backgroundLight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Purchase Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('${pur.cartItems.length} items', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: pur.cartItems.isEmpty
                            ? const Center(child: Text('Select accessories from right to add', style: TextStyle(fontSize: 11, color: AppColors.textMuted)))
                            : ListView.builder(
                                itemCount: pur.cartItems.length,
                                itemBuilder: (context, index) {
                                  final item = pur.cartItems[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.dividerLight))),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1),
                                              Text('${item.packQty} ${item.packUnit.name} (${item.totalPieces} pcs) @ PKR ${(item.unitRatePaisa / 100).toStringAsFixed(0)}',
                                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ),
                                        Text(item.netTotal.format(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                const VerticalDivider(width: 1),

                // Catalog Quick List
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    itemCount: catalog.allProducts.length,
                    itemBuilder: (context, index) {
                      final p = catalog.allProducts[index];
                      return InkWell(
                        onTap: () => _showAddItemDialog(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.dividerLight))),
                          child: Row(
                            children: [
                              ProductImageWidget(
                                imagePath: p.imagePath,
                                category: p.category,
                                productName: p.name,
                                width: 36,
                                height: 36,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(p.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const Icon(Icons.add_circle, color: AppColors.primaryTeal, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom Checkout Bar
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Bill', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text(
                          pur.grandTotal.format(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _paymentChip('Credit Bill', 'credit', pur),
                      const SizedBox(width: 8),
                      _paymentChip('Cash Paid', 'cash', pur),
                      const SizedBox(width: 8),
                      _paymentChip('Bank Paid', 'bank', pur),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: pur.cartItems.isEmpty || pur.isPosting ? null : _submitPurchase,
                    child: pur.isPosting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(context.tr('purchase_post_btn')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentChip(String label, String value, PurchaseProvider pur) {
    final selected = pur.paymentMethod == value;
    return InkWell(
      onTap: () => pur.setPaymentMethod(value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTeal : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.primaryTeal : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.headingNavy),
        ),
      ),
    );
  }
}

