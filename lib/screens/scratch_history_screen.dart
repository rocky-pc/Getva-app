import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class ScratchHistoryScreen extends StatefulWidget {
  const ScratchHistoryScreen({super.key});

  @override
  State<ScratchHistoryScreen> createState() => _ScratchHistoryScreenState();
}

class _ScratchHistoryScreenState extends State<ScratchHistoryScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _userId = await SessionManager.getUserId();
      if (_userId != null) {
        final transactions = await ApiService.getUserTransactions(_userId!, limit: 100);
        setState(() {
          _transactions = transactions;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Scratch History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(_transactions[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your scratch history will appear here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic transaction) {
    final type = transaction['type'] ?? '';
    final amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
    final boxName = transaction['mystery_box_name'] ?? transaction['scratch_card_name'] ?? 'Mystery Box';
    final boxPrice = double.tryParse(transaction['mystery_box_price']?.toString() ?? '0') ?? 0;
    final createdAt = transaction['created_at'] ?? '';
    
    // Format date
    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = createdAt;
      }
    }

    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (type) {
      case 'purchase':
        icon = Icons.shopping_cart;
        color = Colors.orange;
        title = 'Purchased $boxName';
        subtitle = 'Paid: ₹${boxPrice.toStringAsFixed(0)}';
        break;
      case 'reward':
        icon = Icons.card_giftcard;
        color = Colors.green;
        title = 'Won from $boxName';
        subtitle = 'Gained: ₹${amount.toStringAsFixed(2)}';
        break;
      case 'deposit':
        icon = Icons.add_circle;
        color = Colors.blue;
        title = 'Wallet Deposit';
        subtitle = 'Added: ₹${amount.toStringAsFixed(0)}';
        break;
      case 'withdrawal':
        icon = Icons.remove_circle;
        color = Colors.red;
        title = 'Wallet Withdrawal';
        subtitle = 'Withdrawn: ₹${amount.toStringAsFixed(0)}';
        break;
      default:
        icon = Icons.swap_horiz;
        color = Colors.grey;
        title = 'Transaction';
        subtitle = '₹${amount.toStringAsFixed(2)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: type == 'reward' 
                  ? Colors.green.withOpacity(0.15)
                  : type == 'purchase'
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              type == 'reward' ? '+' : type == 'purchase' ? '-' : type == 'withdrawal' ? '-' : '+',
              style: TextStyle(
                color: type == 'reward' 
                    ? Colors.green
                    : type == 'purchase'
                        ? Colors.orange
                        : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
