import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/models/return_order.dart';
import 'package:mobile_wholesale_erp/ui/common/custom_card.dart';
import 'package:mobile_wholesale_erp/ui/common/empty_state.dart';
import 'package:mobile_wholesale_erp/ui/screens/returns/new_return_screen.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  List<ReturnOrder> _returns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReturns();
  }

  Future<void> _loadReturns() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('return_orders', orderBy: 'date DESC, id DESC');
      _returns = rows.map((e) => ReturnOrder.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error loading returns: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Returns & Credit Notes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.assignment_return_rounded),
        label: const Text('New Return'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewReturnScreen())).then((_) => _loadReturns()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _returns.isEmpty
              ? EmptyState(
                  icon: Icons.assignment_return_outlined,
                  title: 'No return documents',
                  subtitle: 'Process customer returns or supplier return debits.',
                  actionButton: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewReturnScreen())).then((_) => _loadReturns()),
                    icon: const Icon(Icons.add),
                    label: const Text('Process Return'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                  itemCount: _returns.length,
                  itemBuilder: (context, index) {
                    final ret = _returns[index];
                    final isSalesReturn = ret.isSalesReturn;

                    return CustomCard(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSalesReturn ? AppColors.warningLight : AppColors.infoLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.assignment_return_rounded,
                              color: isSalesReturn ? AppColors.warning : AppColors.info,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ret.partyName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${ret.returnNumber} • ${ret.date} (Ref: ${ret.originalDocumentNumber})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                ret.totalCredit.format(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.headingNavy),
                              ),
                              Text(
                                isSalesReturn ? 'Customer Credit' : 'Supplier Credit',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSalesReturn ? AppColors.warning : AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
