import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/models/audit_log.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/common/empty_state.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('audit_logs', orderBy: 'timestamp DESC, id DESC', limit: 100);
      _logs = rows.map((e) => AuditLog.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail & Activity Log'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const EmptyState(
                  icon: Icons.shield_outlined,
                  title: 'No audit records yet',
                  subtitle: 'Price overrides, credit overrides, reversals and adjustments will be logged here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];

                    return CustomCard(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTealLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log.action,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryTealDark),
                                ),
                              ),
                              Text(
                                log.timestamp.split('T').first,
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(log.details, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.headingNavy)),
                          const SizedBox(height: 4),
                          Text(
                            'User: ${log.userRole.toUpperCase()} • Entity: ${log.entity} ${log.entityId != null ? "(" + log.entityId! + ")" : ""}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

