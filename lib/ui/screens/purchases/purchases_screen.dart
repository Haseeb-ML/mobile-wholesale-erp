import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/providers/purchase_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/common/empty_state.dart';
import 'package:mobile_wholesale_erp/ui/screens/purchases/new_purchase_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/purchases/purchase_detail_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();
    final purchases = purchaseProvider.purchases;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('purchases_title')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('purchase_new')),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewPurchaseScreen())),
      ),
      body: purchaseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : purchases.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No supplier purchase bills recorded',
                  subtitle: 'Record purchases to receive inventory and update stock costs.',
                  actionButton: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewPurchaseScreen())),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('purchase_new')),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final pur = purchases[index];
                    final isPaid = pur.duePaisa == 0;

                    return CustomCard(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PurchaseDetailScreen(purchase: pur)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPaid ? AppColors.successLight : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: isPaid ? AppColors.success : AppColors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pur.supplierName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${pur.refNumber} • ${pur.date}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                pur.grandTotal.format(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.headingNavy),
                              ),
                              Text(
                                isPaid ? 'PAID' : 'PAYABLE: ${pur.due.format()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPaid ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
