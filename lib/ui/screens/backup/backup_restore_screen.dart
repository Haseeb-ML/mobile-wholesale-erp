import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/services/backup_restore_service.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isProcessing = false;
  String? _lastBackupFile;

  Future<void> _createBackup() async {
    setState(() => _isProcessing = true);
    final isDemo = context.read<AppState>().isDemoMode;

    try {
      final res = await BackupRestoreService.instance.createBackup(forDemo: isDemo);
      if (res.success && res.filePath != null) {
        setState(() => _lastBackupFile = res.filePath);
        if (mounted) {
          await context.read<AppState>().loadSettings();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Backup created!'), backgroundColor: AppColors.success),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message ?? 'Backup failed.'), backgroundColor: AppColors.error),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareBackup() async {
    if (_lastBackupFile == null) return;
    await Share.shareXFiles(
      [XFile(_lastBackupFile!)],
      subject: 'Mobile Wholesale ERP Backup Archive',
    );
  }

  Future<void> _restoreBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (files.isEmpty || files.first.path == null) return;

    final filePath = files.first.path!;
    final isDemo = context.read<AppState>().isDemoMode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text(
          'Restoring this backup will replace current data with the archive snapshot. '
          'A precautionary backup will be created automatically before restore starts.\n\nProceed?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final res = await BackupRestoreService.instance.restoreBackup(filePath, forDemo: isDemo);
      if (res.success) {
        if (mounted) {
          await context.read<AppState>().loadSettings();
          await context.read<CatalogProvider>().loadProducts();
          await context.read<PartyProvider>().loadParties();
          await context.read<DashboardProvider>().refresh();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: AppColors.success),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Backup & Restore'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primaryTealLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.backup_rounded, color: AppColors.primaryTeal),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Complete Offline Archive (.mwzip)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Includes SQLite Database, all accessory photos & SHA-256 verification manifest',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Last Backup Date: ${appState.settings.lastBackupDate ?? "Never"}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _createBackup,
                      icon: const Icon(Icons.archive_rounded),
                      label: const Text('Create New Backup Now'),
                    ),
                  ),
                  if (_lastBackupFile != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _shareBackup,
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share Backup File (WhatsApp / Drive)'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            CustomCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.highlightAmberLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.restore_page_rounded, color: AppColors.highlightAmberDark),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Restore from Archive', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Select a previously exported .mwzip archive to restore records and photos',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _restoreBackup,
                      icon: const Icon(Icons.file_open_rounded),
                      label: const Text('Select File to Restore'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Security & Data Integrity Guarantees:\n'
              '• Flushes SQLite WAL checkpoints prior to archiving.\n'
              '• Computes SHA-256 cryptographic hashes for the database and each photo.\n'
              '• Stages incoming restores in an isolated sandbox before replacing live data.\n'
              '• Automatically creates an internal precautionary snapshot so a corrupted or interrupted restore leaves your current store intact.',
              style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
