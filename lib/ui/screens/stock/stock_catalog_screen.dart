import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/core/services/security_service.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/common/empty_state.dart';
import 'package:mobile_wholesale_erp/ui/common/product_image_widget.dart';
import 'package:mobile_wholesale_erp/ui/screens/stock/add_edit_product_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/stock/stock_adjustment_dialog.dart';
import 'package:mobile_wholesale_erp/ui/screens/stock/stock_movement_screen.dart';

class StockCatalogScreen extends StatelessWidget {
  const StockCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final appState = context.watch<AppState>();
    final canViewCost = SecurityService.instance.canViewCostAndProfit(appState.activeRole);
    final products = catalog.stockProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('stock_title')),
        actions: [
          IconButton(
            icon: Icon(catalog.isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: 'Toggle Grid / List View',
            onPressed: () => catalog.toggleViewMode(),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Stock Movement History',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockMovementScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Stock Count Adjustment',
            onPressed: () => StockAdjustmentDialog.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('stock_btn_add_product')),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: context.tr('stock_search_placeholder'),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: catalog.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => catalog.setSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => catalog.setSearchQuery(val),
            ),
          ),

          // Filter Row: Category Chips & Low Stock / Out of Stock
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  label: context.tr('stock_all'),
                  selected: catalog.stockFilter == 'all' && catalog.selectedCategory == 'All',
                  onTap: () {
                    catalog.setStockFilter('all');
                    catalog.setCategory('All');
                  },
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: context.tr('stock_low'),
                  selected: catalog.stockFilter == 'low',
                  color: AppColors.warning,
                  onTap: () => catalog.setStockFilter(catalog.stockFilter == 'low' ? 'all' : 'low'),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: context.tr('stock_out'),
                  selected: catalog.stockFilter == 'out',
                  color: AppColors.error,
                  onTap: () => catalog.setStockFilter(catalog.stockFilter == 'out' ? 'all' : 'out'),
                ),
                const SizedBox(width: 12),
                const VerticalDivider(width: 1),
                const SizedBox(width: 12),
                ...catalog.categories.where((c) => c != 'All').map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildFilterChip(
                      label: cat,
                      selected: catalog.selectedCategory == cat,
                      onTap: () => catalog.setCategory(catalog.selectedCategory == cat ? 'All' : cat),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Catalog Content
          Expanded(
            child: catalog.isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No accessories found',
                        subtitle: 'Try adjusting your search query or add a new accessory.',
                        actionButton: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.tr('stock_btn_add_product')),
                        ),
                      )
                    : catalog.isGridView
                        ? _buildGridView(context, products, canViewCost)
                        : _buildListView(context, products, canViewCost),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.primaryTeal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? activeColor : AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.headingNavy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<Product> products, bool canViewCost) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return _buildProductGridCard(context, p, canViewCost);
      },
    );
  }

  Widget _buildProductGridCard(BuildContext context, Product p, bool canViewCost) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(productToEdit: p))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Stock Badge overlay
            Stack(
              children: [
                ProductImageWidget(
                  imagePath: p.imagePath,
                  category: p.category,
                  productName: p.name,
                  width: double.infinity,
                  height: 105,
                  borderRadius: 12,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildStockBadge(p),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.headingNavy),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${p.sku}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (p.compatibleModel != null)
                          Text(
                            p.compatibleModel!,
                            style: const TextStyle(fontSize: 9, color: AppColors.textLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Wholesale', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                              Text(
                                p.wholesalePrice.format(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryTeal),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (canViewCost)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Cost', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                              Text(
                                p.costPrice.format(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<Product> products, bool canViewCost) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return CustomCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(10),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen(productToEdit: p))),
          child: Row(
            children: [
              ProductImageWidget(
                imagePath: p.imagePath,
                category: p.category,
                productName: p.name,
                width: 64,
                height: 64,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.headingNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${p.sku} • ${p.category} ${p.compatibleModel != null ? "• " + p.compatibleModel! : ""}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Wholesale: ${p.wholesalePrice.format()}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
                        ),
                        if (canViewCost)
                          Text(
                            'Cost: ${p.costPrice.format()}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStockBadge(p),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockBadge(Product p) {
    final isOut = p.isOutOfStock;
    final isLow = p.isLowStock;

    final color = isOut ? AppColors.error : (isLow ? AppColors.warning : AppColors.success);
    final bg = isOut ? AppColors.errorLight : (isLow ? AppColors.warningLight : AppColors.successLight);
    final label = isOut ? '0 pcs' : '${p.currentStockPieces} pcs';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

