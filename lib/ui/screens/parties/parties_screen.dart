import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/models/party.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/common/empty_state.dart';
import 'package:mobile_wholesale_erp/ui/screens/parties/add_edit_party_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/parties/party_detail_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partyProv = context.watch<PartyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('parties_title')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryTeal,
          tabs: [
            Tab(text: context.tr('parties_tab_customers')),
            Tab(text: context.tr('parties_tab_suppliers')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(_tabController.index == 0 ? 'Add Dealer' : 'Add Supplier'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditPartyScreen(
                initialType: _tabController.index == 0 ? PartyType.customer : PartyType.supplier,
              ),
            ),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by dealer / supplier name, city, phone...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => partyProv.setSearchQuery(v),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPartyList(context, partyProv.customers, isCustomer: true),
                _buildPartyList(context, partyProv.suppliers, isCustomer: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyList(BuildContext context, List<Party> list, {required bool isCustomer}) {
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: isCustomer ? 'No dealers or customers found' : 'No suppliers found',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        final owesUs = isCustomer ? p.currentBalancePaisa > 0 : false;
        final weOwe = !isCustomer ? p.currentBalancePaisa > 0 : false;

        return CustomCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PartyDetailScreen(party: p)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isCustomer ? AppColors.primaryTealLight : AppColors.highlightAmberLight,
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCustomer ? AppColors.primaryTealDark : AppColors.highlightAmberDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${p.phone} • ${p.city ?? "Karachi"}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    if (isCustomer && p.creditLimitPaisa > 0)
                      Text('Credit Limit: ${p.creditLimit.format()}', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    p.currentBalance.format(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: (owesUs || weOwe) ? AppColors.error : AppColors.success,
                    ),
                  ),
                  Text(
                    isCustomer
                        ? (p.currentBalancePaisa > 0 ? "Owes Us" : (p.currentBalancePaisa < 0 ? "Advance" : "Clear"))
                        : (p.currentBalancePaisa > 0 ? "We Owe" : (p.currentBalancePaisa < 0 ? "Advance" : "Clear")),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: (owesUs || weOwe) ? AppColors.error : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
