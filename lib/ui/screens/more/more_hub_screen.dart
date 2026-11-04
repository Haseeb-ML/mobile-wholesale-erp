import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/screens/backup/backup_restore_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/cash_bank/accounts_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/purchases/purchases_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/reports/reports_hub_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/returns/returns_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/settings/settings_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/settings/staff_roles_screen.dart';

class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('nav_more')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _navTile(
            context,
            icon: Icons.receipt_long_rounded,
            color: AppColors.info,
            title: context.tr('purchases_title'),
            subtitle: 'Supplier purchase bills, inward stock and payable tracking',
            destination: const PurchasesScreen(),
          ),
          _navTile(
            context,
            icon: Icons.assignment_return_rounded,
            color: AppColors.warning,
            title: 'Returns & Credit Notes',
            subtitle: 'Customer returns (saleable/damaged) & supplier return debits',
            destination: const ReturnsScreen(),
          ),
          _navTile(
            context,
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.primaryTeal,
            title: context.tr('accounts_title'),
            subtitle: 'Cash in shop, Meezan Bank, expenses and internal contra transfers',
            destination: const AccountsScreen(),
          ),
          _navTile(
            context,
            icon: Icons.assessment_rounded,
            color: const Color(0xFF8B5CF6),
            title: context.tr('reports_title'),
            subtitle: 'Profit & Loss, stock valuation with CSV export, customer ledgers',
            destination: const ReportsHubScreen(),
          ),
          _navTile(
            context,
            icon: Icons.backup_rounded,
            color: AppColors.highlightAmberDark,
            title: context.tr('set_backup_restore'),
            subtitle: 'Offline .mwzip backup creation, sharing and safe staging restore',
            destination: const BackupRestoreScreen(),
          ),
          _navTile(
            context,
            icon: Icons.badge_outlined,
            color: const Color(0xFF0284C7),
            title: context.tr('set_staff_roles'),
            subtitle: 'Role selector (Owner, Sales, Accountant) and PIN security',
            destination: const StaffRolesScreen(),
          ),
          _navTile(
            context,
            icon: Icons.settings_rounded,
            color: AppColors.headingNavy,
            title: context.tr('settings_title'),
            subtitle: 'Shop branding, invoice terms, language (English / Urdu RTL)',
            destination: const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight),
        ],
      ),
    );
  }
}
