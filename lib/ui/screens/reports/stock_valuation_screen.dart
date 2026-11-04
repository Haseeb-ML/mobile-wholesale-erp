import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/providers/report_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';

class StockValuationScreen extends StatefulWidget {
  const StockValuationScreen({super.key});

  @override
  State<StockValuationScreen> createState() => _StockValuationScreenState();
}

class _StockValuationScreenState extends State<StockValuationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadStockValuationReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = context.watch<ReportProvider>();
    final summary = reportProv.stockValuation;
    final items = reportProv.stockReportItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Valuation & On-Hand'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => reportProv.exportStockCsv(),
          ),
        ],
      ),
      body: reportProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                CustomCard(
                  margin: const EdgeInsets.all(16),
                  color: AppColors.primaryTealLight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Inventory Valuation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTealDark)),
                          Text(
                            summary.totalValuation.format(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryTealDark),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${summary.totalPiecesOnHand} Pieces on Hand', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTealDark)),
                          Text('${summary.totalItems} Active SKUs • ${summary.totalDamagedPieces} Damaged', style: const TextStyle(fontSize: 10, color: AppColors.primaryTealDark)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: Text('Item / SKU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                      Expanded(flex: 2, child: Text('Stock (Pcs)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                      Expanded(flex: 2, child: Text('Avg Cost', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                      Expanded(flex: 2, child: Text('Valuation', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final p = items[index];
                      final valPaisa = p.currentStockPieces * p.costPricePaisa;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('${p.sku} • ${p.category}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${p.currentStockPieces} pcs',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: p.isOutOfStock ? AppColors.error : (p.isLowStock ? AppColors.warning : AppColors.headingNavy),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                p.costPrice.format(includeSymbol: false),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'PKR ${(valPaisa / 100).toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
