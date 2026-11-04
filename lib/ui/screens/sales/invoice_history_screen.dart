import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/common/empty_state.dart';
import 'package:mobile_wholesale_erp/ui/screens/sales/invoice_detail_screen.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'paid', 'unpaid'
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final invRows = await db.query('invoices', orderBy: 'date DESC, id DESC');

      final List<Invoice> loaded = [];
      for (final r in invRows) {
        final invId = r['id'] as int;
        final itemRows = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invId]);
        final items = itemRows.map((e) => InvoiceItem.fromMap(e)).toList();
        loaded.add(Invoice.fromMap(r, items: items));
      }
      _invoices = loaded;
    } catch (e) {
      debugPrint('Error loading invoices: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _invoices.where((inv) {
      if (_filter == 'paid' && inv.paymentStatus != PaymentStatus.paid) return false;
      if (_filter == 'unpaid' && inv.paymentStatus == PaymentStatus.paid) return false;

      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return inv.invoiceNumber.toLowerCase().contains(q) ||
            inv.customerName.toLowerCase().contains(q) ||
            (inv.customerPhone?.contains(q) ?? false);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Invoices History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by invoice # or dealer name...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _filterTab('All Invoices', 'all'),
              const SizedBox(width: 8),
              _filterTab('Paid', 'paid'),
              const SizedBox(width: 8),
              _filterTab('Unpaid / Credit', 'unpaid'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No invoices found',
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final inv = filtered[index];
                          final isPaid = inv.duePaisa == 0;

                          return CustomCard(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            padding: const EdgeInsets.all(12),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv)),
                            ).then((_) => _loadInvoices()),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: inv.isCancelled
                                        ? AppColors.errorLight
                                        : (isPaid ? AppColors.successLight : AppColors.warningLight),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    inv.isCancelled ? Icons.cancel : Icons.receipt_rounded,
                                    color: inv.isCancelled
                                        ? AppColors.error
                                        : (isPaid ? AppColors.success : AppColors.warning),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv.customerName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${inv.invoiceNumber} • ${inv.date}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      inv.grandTotal.format(),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.headingNavy),
                                    ),
                                    Text(
                                      inv.isCancelled
                                          ? 'CANCELLED'
                                          : (isPaid ? 'PAID' : 'DUE: ${inv.due.format()}'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: inv.isCancelled
                                            ? AppColors.error
                                            : (isPaid ? AppColors.success : AppColors.warning),
                                      ),
                                    ),
                                  ],
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

  Widget _filterTab(String label, String value) {
    final selected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primaryTeal : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : AppColors.headingNavy,
          ),
        ),
      ),
    );
  }
}

