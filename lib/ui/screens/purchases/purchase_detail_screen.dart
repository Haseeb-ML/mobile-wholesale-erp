import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/models/purchase.dart';
import 'package:mobile_wholesale_erp/models/purchase_item.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final Purchase purchase;

  const PurchaseDetailScreen({super.key, required this.purchase});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  List<PurchaseItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('purchase_items', where: 'purchase_id = ?', whereArgs: [widget.purchase.id]);
      _items = rows.map((e) => PurchaseItem.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error loading purchase items: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pur = widget.purchase;

    return Scaffold(
      appBar: AppBar(
        title: Text(pur.refNumber),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCard(
              margin: EdgeInsets.zero,
              color: pur.duePaisa == 0 ? AppColors.successLight : AppColors.warningLight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS: ${pur.paymentStatus.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: pur.duePaisa == 0 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      Text('Date: ${pur.date} • Mode: ${pur.paymentMethod.toUpperCase()}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  Text(
                    pur.grandTotal.format(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Supplier', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(pur.supplierName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Purchased Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ..._items.map((item) {
                return CustomCard(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              '${item.packQty} ${item.packUnit.name} (${item.totalPieces} pcs) @ PKR ${(item.unitRatePaisa / 100).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(item.netTotal.format(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
            CustomCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _row('Subtotal', pur.subtotal.format()),
                  if (pur.freightPaisa > 0) _row('Freight / Transport', pur.freight.format()),
                  if (pur.discountPaisa > 0) _row('Discount', '- ${pur.discount.format()}'),
                  const Divider(),
                  _row('Grand Total', pur.grandTotal.format(), isBold: true),
                  _row('Paid', pur.paid.format()),
                  const Divider(),
                  _row('Remaining Payable', pur.due.format(), isBold: true, color: pur.duePaisa > 0 ? AppColors.warning : AppColors.success),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
