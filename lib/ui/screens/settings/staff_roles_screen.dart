import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/services/security_service.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';

class StaffRolesScreen extends StatefulWidget {
  const StaffRolesScreen({super.key});

  @override
  State<StaffRolesScreen> createState() => _StaffRolesScreenState();
}

class _StaffRolesScreenState extends State<StaffRolesScreen> {
  final TextEditingController _newPinCtrl = TextEditingController();
  bool _isSavingPin = false;

  @override
  void dispose() {
    _newPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePin() async {
    final pin = _newPinCtrl.text.trim();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSavingPin = true);
    try {
      final appState = context.read<AppState>();
      final salt = SecurityService.instance.generateSalt();
      final hash = SecurityService.instance.hashPin(pin, salt);

      final updated = appState.settings.copyWith(
        ownerPinHash: hash,
        ownerPinSalt: salt,
      );
      await appState.updateSettings(updated);

      if (mounted) {
        _newPinCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner PIN updated and hashed securely!'), backgroundColor: AppColors.success),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentRole = appState.activeRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Roles & Permissions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Switch Active Role on Device',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
            ),
            const SizedBox(height: 8),

            _roleCard(
              title: 'Owner (Full Control)',
              roleId: 'owner',
              description: 'Access all features, view profit margins, costs, override credit limits, cancel invoices and edit settings.',
              selected: currentRole == 'owner',
              onSelect: () => appState.setRole('owner'),
            ),
            const SizedBox(height: 8),

            _roleCard(
              title: 'Sales Counter Staff',
              roleId: 'sales',
              description: 'Create sales, look up products, take payments. Product costs, gross/net profits, and owner settings are restricted.',
              selected: currentRole == 'sales',
              onSelect: () => appState.setRole('sales'),
            ),
            const SizedBox(height: 8),

            _roleCard(
              title: 'Accountant',
              roleId: 'accountant',
              description: 'Full financial visibility, profit & loss, cash/bank reconcile, party ledgers and stock valuation.',
              selected: currentRole == 'accountant',
              onSelect: () => appState.setRole('accountant'),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Owner PIN Security
            const Text(
              'Change Owner Authorization PIN',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
            ),
            const SizedBox(height: 4),
            const Text(
              'Used to authorize credit-limit overrides, price deviations, reversals and data restores.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newPinCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'New 4-6 Digit PIN',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSavingPin ? null : _updatePin,
                  child: _isSavingPin
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save PIN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required String roleId,
    required String description,
    required bool selected,
    required VoidCallback onSelect,
  }) {
    return CustomCard(
      margin: EdgeInsets.zero,
      color: selected ? AppColors.primaryTealLight.withValues(alpha: 0.5) : Colors.white,
      border: Border.all(color: selected ? AppColors.primaryTeal : AppColors.borderLight, width: selected ? 1.5 : 1),
      onTap: onSelect,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<String>(
            value: roleId,
            groupValue: context.watch<AppState>().activeRole,
            onChanged: (_) => onSelect(),
            activeColor: AppColors.primaryTeal,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.headingNavy)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

