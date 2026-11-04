import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/core/services/app_storage_service.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/product_image_widget.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const AddEditProductScreen({super.key, this.productToEdit});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _skuCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _piecesPerBoxCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _wholesalePriceCtrl;
  late TextEditingController _minPriceCtrl;
  late TextEditingController _reorderLevelCtrl;
  late TextEditingController _tierQtyCtrl;
  late TextEditingController _tierPriceCtrl;
  late TextEditingController _openingStockCtrl;
  late TextEditingController _openingCostCtrl;

  String _selectedCategory = 'Chargers';
  String? _imagePath;
  bool _isSaving = false;

  final List<String> _categoryOptions = [
    'Chargers',
    'Charging Cables',
    'Power Banks',
    'Wireless Earbuds',
    'Wired Earphones',
    'Phone Covers',
    'Screen Protectors',
    'Car Chargers',
    'Mobile Holders',
    'OTG Adapters',
    'Memory Cards',
    'USB Accessories',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _skuCtrl = TextEditingController(text: p?.sku ?? 'ACC-${DateTime.now().millisecondsSinceEpoch % 100000}');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _modelCtrl = TextEditingController(text: p?.compatibleModel ?? '');
    _colorCtrl = TextEditingController(text: p?.colorSpec ?? '');
    _piecesPerBoxCtrl = TextEditingController(text: (p?.piecesPerBox ?? 50).toString());
    _costPriceCtrl = TextEditingController(text: p != null ? (p.costPricePaisa / 100).toStringAsFixed(0) : '200');
    _wholesalePriceCtrl = TextEditingController(text: p != null ? (p.wholesalePricePaisa / 100).toStringAsFixed(0) : '300');
    _minPriceCtrl = TextEditingController(text: p != null ? (p.minSellingPricePaisa / 100).toStringAsFixed(0) : '270');
    _reorderLevelCtrl = TextEditingController(text: (p?.reorderLevel ?? 10).toString());
    _tierQtyCtrl = TextEditingController(text: p?.tierMinQty != null ? p!.tierMinQty.toString() : '');
    _tierPriceCtrl = TextEditingController(text: p?.tierPricePaisa != null ? (p!.tierPricePaisa! / 100).toStringAsFixed(0) : '');
    _openingStockCtrl = TextEditingController(text: '0');
    _openingCostCtrl = TextEditingController(text: '200');

    if (p != null) {
      _selectedCategory = p.category;
      _imagePath = p.imagePath;
    }
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _piecesPerBoxCtrl.dispose();
    _costPriceCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _minPriceCtrl.dispose();
    _reorderLevelCtrl.dispose();
    _tierQtyCtrl.dispose();
    _tierPriceCtrl.dispose();
    _openingStockCtrl.dispose();
    _openingCostCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final relPath = await AppStorageService.instance.pickAndStoreImage(source);
    if (relPath != null) {
      setState(() => _imagePath = relPath);
    }
  }

  void _removePhoto() {
    setState(() => _imagePath = null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final costPaisa = ((double.tryParse(_costPriceCtrl.text.trim()) ?? 0) * 100).round();
      final wholesalePaisa = ((double.tryParse(_wholesalePriceCtrl.text.trim()) ?? 0) * 100).round();
      final minPaisa = ((double.tryParse(_minPriceCtrl.text.trim()) ?? 0) * 100).round();
      final tierQty = int.tryParse(_tierQtyCtrl.text.trim());
      final tierPaisa = _tierPriceCtrl.text.isNotEmpty
          ? ((double.tryParse(_tierPriceCtrl.text.trim()) ?? 0) * 100).round()
          : null;

      final p = widget.productToEdit;
      final product = Product(
        id: p?.id,
        sku: _skuCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        brand: _brandCtrl.text.trim().isNotEmpty ? _brandCtrl.text.trim() : null,
        compatibleModel: _modelCtrl.text.trim().isNotEmpty ? _modelCtrl.text.trim() : null,
        colorSpec: _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : null,
        imagePath: _imagePath,
        piecesPerBox: int.tryParse(_piecesPerBoxCtrl.text.trim()) ?? 50,
        costPricePaisa: costPaisa,
        wholesalePricePaisa: wholesalePaisa,
        minSellingPricePaisa: minPaisa,
        reorderLevel: int.tryParse(_reorderLevelCtrl.text.trim()) ?? 10,
        tierMinQty: tierQty,
        tierPricePaisa: tierPaisa,
        currentStockPieces: p?.currentStockPieces ?? 0,
        damagedStockPieces: p?.damagedStockPieces ?? 0,
        createdAt: p?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final openingPieces = int.tryParse(_openingStockCtrl.text.trim()) ?? 0;
      final openingCostPaisa = ((double.tryParse(_openingCostCtrl.text.trim()) ?? 0) * 100).round();

      await context.read<CatalogProvider>().saveProduct(
            product,
            openingPieces: openingPieces,
            openingCostPaisa: openingCostPaisa,
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? context.tr('prod_edit_title') : context.tr('prod_add_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Section (OPTIONAL)
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ProductImageWidget(
                          imagePath: _imagePath,
                          category: _selectedCategory,
                          productName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'New Accessory',
                          width: 110,
                          height: 110,
                          borderRadius: 16,
                        ),
                        if (_imagePath != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: _removePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 16),
                          label: Text(context.tr('prod_photo_select_gallery')),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: Text(context.tr('prod_photo_take_camera')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Basic Identifiers
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _skuCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_sku') + ' *'),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_barcode')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: context.tr('prod_name') + ' *'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Category Picker
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: context.tr('prod_category') + ' *'),
                items: _categoryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_brand')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _modelCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_model')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colorCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_color_spec')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _piecesPerBoxCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_box_pieces') + ' *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid box size' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                'Pricing & Inventory Levels (PKR)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.headingNavy),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_cost_price') + ' *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? 'Invalid cost' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _wholesalePriceCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_wholesale_price') + ' *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (double.tryParse(v ?? '') ?? -1) <= 0 ? 'Invalid rate' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minPriceCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_min_price') + ' *'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderLevelCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_reorder_level')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tierQtyCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_tier_qty')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _tierPriceCtrl,
                      decoration: InputDecoration(labelText: context.tr('prod_tier_price')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              // Opening Stock (Only for new products)
              if (!isEditing) ...[
                const SizedBox(height: 20),
                const Text(
                  'Opening Stock Setup (Optional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.headingNavy),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _openingStockCtrl,
                        decoration: InputDecoration(labelText: context.tr('prod_opening_stock')),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _openingCostCtrl,
                        decoration: InputDecoration(labelText: context.tr('prod_opening_cost')),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(context.tr('prod_save')),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
