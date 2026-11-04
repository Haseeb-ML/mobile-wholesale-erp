import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/core/services/pdf_service.dart';
import 'package:mobile_wholesale_erp/core/services/security_service.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/common/pin_dialog.dart';
import 'package:mobile_wholesale_erp/ui/navigation/main_navigation_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Invoice _currentInvoice;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
  }

  Future<void> _sharePdf() async {
    try {
      final settings = context.read<AppState>().settings;
      await PdfService.instance.shareInvoicePdf(_currentInvoice, settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _printInvoice() async {
    try {
      final settings = context.read<AppState>().settings;
      await PdfService.instance.printInvoice(_currentInvoice, settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _cancelInvoice() async {
    final appState = context.read<AppState>();
    final canCancel = SecurityService.instance.canCancelInvoice(appState.activeRole);

    if (!canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the Shop Owner can cancel/reverse invoices.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final authorized = await PinDialog.verify(
      context,
      title: 'Confirm Cancellation',
      message: 'Reversing this invoice will restore stock and adjust customer balances. Enter Owner PIN to proceed.',
    );
    if (!authorized) return;

    setState(() => _isProcessing = true);
    try {
      await AccountingService.instance.cancelInvoice(_currentInvoice.id!, userRole: appState.activeRole);
      setState(() {
        _currentInvoice = _currentInvoice.copyWith(status: InvoiceStatus.cancelled);
      });
      if (mounted) {
        await context.read<CatalogProvider>().loadProducts();
        await context.read<PartyProvider>().loadParties();
        await context.read<DashboardProvider>().refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice cancelled and reversed successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancellation error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = _currentInvoice;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back / واپس',
            onPressed: _navigateBack,
          ),
          title: Text(inv.invoiceNumber),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: context.tr('invoice_share_pdf'),
              onPressed: _sharePdf,
            ),
            IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: context.tr('invoice_print'),
              onPressed: _printInvoice,
            ),
          ],
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            CustomCard(
              margin: EdgeInsets.zero,
              color: inv.isCancelled
                  ? AppColors.errorLight
                  : (inv.duePaisa == 0 ? AppColors.successLight : AppColors.warningLight),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.isCancelled ? 'CANCELLED / REVERSED' : 'STATUS: ${inv.paymentStatus.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: inv.isCancelled
                              ? AppColors.error
                              : (inv.duePaisa == 0 ? AppColors.success : AppColors.warning),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Date: ${inv.date} • Mode: ${inv.paymentMethod.toUpperCase()}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  Text(
                    inv.grandTotal.format(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.headingNavy),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer Info
            CustomCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer (Dealer)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(inv.customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                  if (inv.customerPhone != null)
                    Text('Phone: ${inv.customerPhone}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Items List
            const Text('Invoice Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
            const SizedBox(height: 8),

            ...inv.items.map((item) {
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(
                            '${item.packQty} ${item.packUnitShort} (${item.totalPieces} pcs) @ PKR ${(item.unitPricePaisa / 100).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.netTotal.format(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Accounting Financial Summary
            CustomCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _row('Subtotal', inv.subtotal.format()),
                  if (inv.discountPaisa > 0) _row('Discount', '- ${inv.discount.format()}'),
                  if (inv.taxPaisa > 0) _row('Tax', inv.tax.format()),
                  const Divider(),
                  _row('Grand Total', inv.grandTotal.format(), isBold: true),
                  _row('Paid', inv.paid.format()),
                  const Divider(),
                  _row('Remaining Due', inv.due.format(), isBold: true, color: inv.duePaisa > 0 ? AppColors.error : AppColors.success),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            if (!inv.isCancelled) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sharePdf,
                  icon: const Icon(Icons.share_rounded),
                  label: Text(context.tr('invoice_share_pdf')),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _cancelInvoice,
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  label: Text(context.tr('invoice_cancel')),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _navigateBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Sales / نئی سیل پر واپس'),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
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

