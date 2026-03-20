import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/wallet_balance_card.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/common_bottom_nav.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<int> _rupeeOptions = [];
  bool _isLoading = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadRupeeOptions();
  }

  Future<void> _loadRupeeOptions() async {
    try {
      final options = await ApiService.getRupeeOptions();
      setState(() {
        _rupeeOptions = options;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _rupeeOptions = [10, 50, 100, 500, 1000, 2000];
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletBalanceCard(),
              const SizedBox(height: 24),
              const RecentTransactions(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showFundsDialog(context);
        },
        label: const Text('Add Funds'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFD4A847),
        foregroundColor: const Color(0xFF1A1200),
      ),
      bottomNavigationBar: CommonBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _showFundsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Manage Funds',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Deposit'),
              onTap: () {
                Navigator.pop(context);
                _showDepositDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Withdraw'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Withdrawal feature coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context) {
    if (_isLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Deposit Amount',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _rupeeOptions.map((amount) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deposit ₹$amount coming soon')),
                    );
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '₹$amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}