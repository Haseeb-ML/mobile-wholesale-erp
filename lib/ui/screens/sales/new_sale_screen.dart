import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/providers/cart_provider.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/pin_dialog.dart';
import 'package:mobile_wholesale_erp/ui/common/product_image_widget.dart';
import 'package:mobile_wholesale_erp/ui/screens/sales/invoice_detail_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/sales/invoice_history_screen.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();
  final TextEditingController _paidCtrl = TextEditingController();
  String _catalogSearch = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _discountCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  void _showAddToCartDialog(Product product) {
    PackUnit selectedUnit = PackUnit.piece;
    int packQty = 1;
    final cart = context.read<CartProvider>();

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
            final unitPricePaisa = product.getEffectivePricePaisa(totalPieces);
            final lineTotalPaisa = totalPieces * unitPricePaisa;

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
                            Text('Stock: ${product.currentStockPieces} pcs • Box: ${product.piecesPerBox} pcs',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Pack Unit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _unitOption(
                        label: 'Piece',
                        sub: '1 pc',
                        selected: selectedUnit == PackUnit.piece,
                        onTap: () => setModalState(() => selectedUnit = PackUnit.piece),
                      ),
                      const SizedBox(width: 8),
                      _unitOption(
                        label: 'Dozen',
                        sub: '12 pcs',
                        selected: selectedUnit == PackUnit.dozen,
                        onTap: () => setModalState(() => selectedUnit = PackUnit.dozen),
                      ),
                      const SizedBox(width: 8),
                      _unitOption(
                        label: 'Box/Carton',
                        sub: '${product.piecesPerBox} pcs',
                        selected: selectedUnit == PackUnit.box,
                        onTap: () => setModalState(() => selectedUnit = PackUnit.box),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: packQty > 1 ? () => setModalState(() => packQty--) : null,
                          ),
                          Text('$packQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setModalState(() => packQty++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total: $totalPieces pcs ($packQty ${selectedUnit.name})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          'PKR ${(lineTotalPaisa / 100).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryTeal),
                        ),
                      ],
                    ),
                  ),
                  if (totalPieces > product.currentStockPieces) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Out of stock limit! Available: ${product.currentStockPieces} pcs',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: totalPieces > product.currentStockPieces
                          ? null
                          : () {
                              cart.addOrUpdateProduct(
                                product: product,
                                packUnit: selectedUnit,
                                packQty: packQty,
                              );
                              Navigator.pop(ctx);
                            },
                      child: const Text('Add to Sales Cart'),
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

  Widget _unitOption({required String label, required String sub, required bool selected, required VoidCallback onTap}) {
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
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? AppColors.primaryTealDark : AppColors.headingNavy)),
              Text(sub, style: TextStyle(fontSize: 10, color: selected ? AppColors.primaryTealDark : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitSale() async {
    final cart = context.read<CartProvider>();
    final appState = context.read<AppState>();

    // Check Credit Limit Exceeded
    if (cart.isCreditLimitExceeded()) {
      final authorized = await PinDialog.verify(
        context,
        title: context.tr('sales_credit_override_title'),
        message: context.tr('sales_credit_override_msg'),
      );
      if (!authorized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sale blocked: Customer credit limit exceeded.'), backgroundColor: AppColors.error),
          );
        }
        return;
      }
    }

    try {
      final invoice = await cart.postInvoice(userRole: appState.activeRole);
      if (mounted) {
        await context.read<CatalogProvider>().loadProducts();
        await context.read<PartyProvider>().loadParties();
        await context.read<DashboardProvider>().refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice ${invoice.invoiceNumber} posted successfully!'), backgroundColor: AppColors.success),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice)),
        );
      }
    } on InsufficientStockException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock Kam Hai: ${e.name} ke sirf ${e.available} pieces mojood hain (Requested: ${e.requested})'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting invoice: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();
    final parties = context.watch<PartyProvider>();

    final filteredProducts = catalog.allProducts.where((p) {
      if (_catalogSearch.isEmpty) return true;
      final q = _catalogSearch.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q) || (p.compatibleModel?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('sales_new_invoice')),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Sales Invoices',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Customer Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.person_pin_rounded, color: AppColors.primaryTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Party?>(
                      value: cart.selectedCustomer,
                      hint: const Text('Cash / Walk-in Customer (Select Dealer)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<Party?>(
                          value: null,
                          child: Text('Cash / Walk-in Customer', style: TextStyle(fontSize: 13)),
                        ),
                        ...parties.customers.map((c) {
                          return DropdownMenuItem<Party?>(
                            value: c,
                            child: Text('${c.name} (${c.city ?? "Karachi"})', style: const TextStyle(fontSize: 13)),
                          );
                        }),
                      ],
                      onChanged: (p) => cart.selectCustomer(p),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Main Area: Cart Summary on Top, Catalog Search on Bottom
          Expanded(
            child: Row(
              children: [
                // Cart Items Section (Flexible)
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        color: AppColors.backgroundLight,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${context.tr("sales_cart")} (${cart.items.length})',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cart.totalPieces} pcs',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: cart.isEmpty
                            ? Center(
                                child: Text(context.tr('sales_cart_empty'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              )
                            : ListView.builder(
                                itemCount: cart.items.length,
                                itemBuilder: (context, index) {
                                  final item = cart.items[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.productName,
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis),
                                              Text(
                                                '${item.packQty} ${item.packUnitShort} (${item.totalPieces} pcs) @ PKR ${(item.unitPricePaisa / 100).toStringAsFixed(0)}/pc',
                                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          item.netTotal.format(),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                                          onPressed: () => cart.removeItem(index),
                                        ),
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

                // Fast Product Catalog Picker
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search accessories...',
                            prefixIcon: const Icon(Icons.search, size: 16),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onChanged: (v) => setState(() => _catalogSearch = v),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final p = filteredProducts[index];
                            final isOutOfStock = p.currentStockPieces <= 0;
                            return InkWell(
                              onTap: isOutOfStock
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${p.name} is currently out of stock (0 pcs).'),
                                          backgroundColor: AppColors.error,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  : () => _showAddToCartDialog(p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
                                ),
                                child: Row(
                                  children: [
                                    Opacity(
                                      opacity: isOutOfStock ? 0.5 : 1.0,
                                      child: ProductImageWidget(
                                        imagePath: p.imagePath,
                                        category: p.category,
                                        productName: p.name,
                                        width: 40,
                                        height: 40,
                                        borderRadius: 6,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isOutOfStock ? AppColors.textMuted : AppColors.headingNavy,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          Text(
                                            isOutOfStock
                                                ? 'Out of Stock (0 pcs)'
                                                : '${p.wholesalePrice.format()} • Stock: ${p.currentStockPieces} pcs',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isOutOfStock ? FontWeight.w600 : FontWeight.normal,
                                              color: isOutOfStock ? AppColors.error : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isOutOfStock ? Icons.block : Icons.add_circle,
                                      color: isOutOfStock ? AppColors.textMuted : AppColors.primaryTeal,
                                      size: 20,
                                    ),
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
              ],
            ),
          ),

          // 3. Checkout Drawer / Bottom Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        Text(
                          cart.grandTotal.format(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryTeal),
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
                      _paymentChip('Cash', 'cash', cart),
                      const SizedBox(width: 8),
                      _paymentChip('Bank', 'bank', cart),
                      const SizedBox(width: 8),
                      _paymentChip('Credit (Udhar)', 'credit', cart),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty || cart.isPosting ? null : _submitSale,
                    child: cart.isPosting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(context.tr('sales_post_btn')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentChip(String label, String value, CartProvider cart) {
    final selected = cart.paymentMethod == value;
    return InkWell(
      onTap: () => cart.setPaymentMethod(value),
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
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.headingNavy),
        ),
      ),
    );
  }
}
