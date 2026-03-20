import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class RecentTransactions extends StatefulWidget {
  const RecentTransactions({Key? key}) : super(key: key);

  @override
  State<RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    _userId = await SessionManager.getUserId();
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final response = await ApiService.getUserTransactions(_userId!, limit: 10);
      if (response is List && mounted) {
        setState(() {
          _transactions = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _isLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            : _transactions.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      final type = transaction['type'];
                      final isPositive = type == 'reward' || type == 'deposit';
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getTransactionColor(type).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getTransactionIcon(type),
                                color: _getTransactionColor(type),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTransactionTitle(type),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    transaction['created_at'] != null
                                        ? transaction['created_at'].toString().substring(0, 10)
                                        : 'Recent',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isPositive ? '+' : '-'}₹${double.parse(transaction['amount'].toString()).abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'purchase': return Icons.shopping_bag_outlined;
      case 'reward': return Icons.card_giftcard_rounded;
      case 'withdrawal': return Icons.file_upload_outlined;
      case 'deposit': return Icons.file_download_outlined;
      default: return Icons.swap_horiz_rounded;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'purchase': return Colors.orange;
      case 'reward': return Colors.purple;
      case 'withdrawal': return Colors.red;
      case 'deposit': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getTransactionTitle(String type) {
    switch (type) {
      case 'purchase': return 'Card Purchase';
      case 'reward': return 'Won Reward';
      case 'withdrawal': return 'Withdrawal';
      case 'deposit': return 'Funds Added';
      default: return 'Transaction';
    }
  }
}
