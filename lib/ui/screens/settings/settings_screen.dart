import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/screens/backup/backup_restore_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/onboarding/welcome_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/settings/audit_log_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/settings/staff_roles_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _footerCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().settings;
    _shopNameCtrl = TextEditingController(text: s.shopName);
    _addressCtrl = TextEditingController(text: s.address);
    _phoneCtrl = TextEditingController(text: s.phone);
    _footerCtrl = TextEditingController(text: s.invoiceFooter);
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveShopDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final appState = context.read<AppState>();
    final updated = appState.settings.copyWith(
      shopName: _shopNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      invoiceFooter: _footerCtrl.text.trim(),
    );
    await appState.updateSettings(updated);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop details saved!'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Details Form
            CustomCard(
              margin: EdgeInsets.zero,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Shop Branding & Invoice Header', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shopNameCtrl,
                      decoration: InputDecoration(labelText: context.tr('set_shop_name') + ' *'),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(labelText: context.tr('set_shop_phone') + ' *'),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: InputDecoration(labelText: context.tr('set_shop_address') + ' *'),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _footerCtrl,
                      decoration: InputDecoration(labelText: context.tr('set_invoice_footer')),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveShopDetails,
                        child: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Update Shop Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Language Selector
            CustomCard(
              margin: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.primaryTeal),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('set_language'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(appState.language == 'ur' ? 'اردو (Urdu RTL)' : 'English', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: appState.language,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ur', child: Text('اردو')),
                    ],
                    onChanged: (lang) {
                      if (lang != null) appState.setLanguage(lang);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Navigation to Sub-modules
            _toolTile(
              icon: Icons.shield_outlined,
              color: AppColors.info,
              title: context.tr('set_staff_roles'),
              subtitle: 'Active Role: ${appState.activeRole.toUpperCase()} • Change Owner PIN',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffRolesScreen())),
            ),
            const SizedBox(height: 10),

            _toolTile(
              icon: Icons.backup_rounded,
              color: AppColors.highlightAmberDark,
              title: context.tr('set_backup_restore'),
              subtitle: 'Export offline ZIP archive or restore verified snapshot',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen())),
            ),
            const SizedBox(height: 10),

            _toolTile(
              icon: Icons.history_edu_rounded,
              color: const Color(0xFF8B5CF6),
              title: context.tr('set_audit_trail'),
              subtitle: 'View activity logs of reversals, overrides and adjustments',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen())),
            ),
            const SizedBox(height: 20),

            // Mode Switching / Reset
            CustomCard(
              margin: EdgeInsets.zero,
              color: appState.isDemoMode ? AppColors.demoBannerBg : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        appState.isDemoMode ? Icons.explore : Icons.business,
                        color: appState.isDemoMode ? AppColors.demoBannerText : AppColors.primaryTeal,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        appState.isDemoMode ? 'Active Mode: DEMO' : 'Active Mode: REAL BUSINESS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: appState.isDemoMode ? AppColors.demoBannerText : AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appState.isDemoMode
                        ? 'You are running in the demonstration database. You can start your clean live business anytime.'
                        : 'You are using your live business database. Transactions are separate from the demo database.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        );
                      },
                      child: Text(appState.isDemoMode ? 'Start My Real Business' : 'Switch Database / Mode'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _toolTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
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
