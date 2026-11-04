import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/services/pdf_service.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/screens/parties/party_payment_dialog.dart';

class PartyDetailScreen extends StatefulWidget {
  final Party party;

  const PartyDetailScreen({super.key, required this.party});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartyProvider>().loadPartyLedger(widget.party.id!);
    });
  }

  Future<void> _shareLedger() async {
    final partyProv = context.read<PartyProvider>();
    final settings = context.read<AppState>().settings;
    await PdfService.instance.sharePartyLedgerPdf(
      widget.party,
      partyProv.activeLedgerEntries,
      settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final partyProv = context.watch<PartyProvider>();
    final p = widget.party;
    final entries = partyProv.activeLedgerEntries;
    final isCustomer = p.type == PartyType.customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share PDF Statement',
            onPressed: _shareLedger,
          ),
        ],
      ),
      body: Column(
        children: [
          // Party Profile Card
          CustomCard(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCustomer ? AppColors.primaryTealLight : AppColors.highlightAmberLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCustomer ? 'DEALER' : 'SUPPLIER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCustomer ? AppColors.primaryTealDark : AppColors.highlightAmberDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Phone: ${p.phone} • City: ${p.city ?? "Karachi"}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (p.address != null)
                  Text('Address: ${p.address}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCustomer
                              ? (p.currentBalancePaisa >= 0 ? "Customer Owes Us:" : "Customer Advance:")
                              : (p.currentBalancePaisa >= 0 ? "We Owe Supplier:" : "Supplier Advance:"),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        Text(
                          p.currentBalance.format(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: p.hasOutstandingDue ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => PartyPaymentDialog.show(
                        context,
                        isCustomerReceipt: isCustomer,
                        preselectedParty: p,
                      ),
                      icon: Icon(isCustomer ? Icons.call_received : Icons.call_made, size: 16),
                      label: Text(isCustomer ? 'Receive Payment' : 'Pay Supplier'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Running Statement Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Running Ledger Statement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                Text('${entries.length} Transactions', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Ledger Table / List
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No transactions recorded for this party.', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: e.debitPaisa > 0 ? AppColors.infoLight : AppColors.successLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                e.debitPaisa > 0 ? Icons.arrow_outward : Icons.arrow_downward,
                                size: 16,
                                color: e.debitPaisa > 0 ? AppColors.info : AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.refNumber ?? e.notes ?? e.type.toUpperCase(),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${e.date} • ${e.type.toUpperCase()}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  e.debitPaisa > 0 ? '+ ${e.debit.format()}' : '- ${e.credit.format()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: e.debitPaisa > 0 ? AppColors.error : AppColors.success,
                                  ),
                                ),
                                Text(
                                  'Bal: ${e.runningBalance.format()}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
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
}

