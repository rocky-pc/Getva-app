import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/getva_coin.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════
const _gold        = Color(0xFFD4A847);
const _goldBright  = Color(0xFFFFE066);
const _goldDeep    = Color(0xFFB8892A);
const _surface     = Color(0xFF0A0910);
const _cardBg      = Color(0xFF110F1E);
const _cardBg2     = Color(0xFF16132A);
const _violet      = Color(0xFF5A3FBF);
const _violetLight = Color(0xFF8B6FE8);
const _textPrimary = Colors.white;
const _textMuted   = Color(0xFF6B6880);
const _border      = Color(0xFF1E1B32);
const _green       = Color(0xFF00C853);
const _cyan        = Color(0xFF00E5FF);
const _rose        = Color(0xFFFF3D71);

// ═══════════════════════════════════════════════════════════════
//  GETVA COIN SCREEN
// ═══════════════════════════════════════════════════════════════
class GetvaCoinScreen extends StatefulWidget {
  const GetvaCoinScreen({Key? key}) : super(key: key);

  @override
  State<GetvaCoinScreen> createState() => _GetvaCoinScreenState();
}

class _GetvaCoinScreenState extends State<GetvaCoinScreen> {
  GetvaCoinSettings? _settings;
  List<GetvaCoinPackage> _packages = [];
  GetvaCoinWallet? _wallet;
  List<GetvaCoinTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  int _selectedPackageIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load settings
      GetvaCoinSettings? settings;
      try {
        final settingsResponse = await ApiService.getGetvaCoinSettings();
        if (settingsResponse != null && settingsResponse['success'] == true) {
          settings = GetvaCoinSettings.fromJson(settingsResponse['data'] ?? {});
        }
      } catch (e) {
        // Use default settings if API fails
      }

      // Load packages
      List<GetvaCoinPackage> packages = [];
      try {
        final packagesResponse = await ApiService.getGetvaCoinPackages();
        if (packagesResponse != null && packagesResponse['success'] == true) {
          final packagesList = packagesResponse['data'] as List<dynamic>? ?? [];
          packages = packagesList.map((p) => GetvaCoinPackage.fromJson(p)).toList();
        }
      } catch (e) {
        // Use empty list if API fails
      }

      // Load wallet
      GetvaCoinWallet? wallet;
      try {
        final userId = await SessionManager.getUserId();
        if (userId != null) {
          final walletResponse = await ApiService.getGetvaCoinWallet(userId);
          if (walletResponse != null && walletResponse['success'] == true && walletResponse['data'] != null) {
            wallet = GetvaCoinWallet.fromJson(walletResponse['data']);
          }
        }
      } catch (e) {
        // Use null wallet if API fails
      }

      // Load transactions
      List<GetvaCoinTransaction> transactions = [];
      try {
        final userId = await SessionManager.getUserId();
        if (userId != null) {
          final txnResponse = await ApiService.getGetvaCoinTransactions(userId);
          if (txnResponse != null && txnResponse['success'] == true) {
            final txnList = txnResponse['data'] as List<dynamic>? ?? [];
            transactions = txnList.map((t) => GetvaCoinTransaction.fromJson(t)).toList();
          }
        }
      } catch (e) {
        // Use empty list if API fails
      }

      if (mounted) {
        setState(() {
          _settings = settings;
          _packages = packages;
          _wallet = wallet;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _purchaseCoins() async {
    if (_selectedPackageIndex < 0 || _selectedPackageIndex >= _packages.length) {
      _showError('Please select a package');
      return;
    }

    final package = _packages[_selectedPackageIndex];
    
    try {
      final userId = await SessionManager.getUserId();
      
      if (userId == null) {
        _showError('Please login to purchase coins');
        return;
      }

      final response = await ApiService.purchaseGetvaCoins(
        userId: userId,
        packageId: package.id,
        coinAmount: package.coinAmount,
        price: package.priceInRupees,
      );

      if (response != null && response['success'] == true) {
        _showSuccess('Coins purchased successfully!');
        _loadData();
      } else {
        _showError(response?['message'] ?? 'Purchase failed');
      }
    } catch (e) {
      _showError('Purchase failed. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _rose,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _settings?.isEnabled ?? true;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Row(
          children: [
            Text('🪙 ', style: TextStyle(fontSize: 24)),
            Text(
              'GETVA COIN',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _gold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _error != null
              ? _buildErrorView()
              : !isEnabled
                  ? _buildDisabledView()
                  : _buildContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: _rose, size: 64),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(color: _textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _surface,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, color: _textMuted, size: 64),
          SizedBox(height: 16),
          Text(
            'Getva Coin is currently disabled',
            style: TextStyle(color: _textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _gold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletCard(),
            const SizedBox(height: 24),
            _buildExchangeRateCard(),
            const SizedBox(height: 24),
            _buildPackagesSection(),
            const SizedBox(height: 24),
            _buildPromotionCard(),
            const SizedBox(height: 24),
            _buildTransactionsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    final balance = _wallet?.coinBalance ?? 0.0;
    final rate = _settings?.exchangeRate ?? 1.0;
    final valueInRupees = balance * rate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_goldDeep, _gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'Your Coin Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '🪙 ',
                style: TextStyle(fontSize: 36),
              ),
              Text(
                balance.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '≈ ₹${valueInRupees.toStringAsFixed(2)} INR',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateCard() {
    final rate = _settings?.exchangeRate ?? 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.currency_exchange, color: _cyan, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exchange Rate',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1 Getva Coin = ₹${rate.toStringAsFixed(2)} INR',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BUY COINS',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _gold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        if (_packages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const Text(
              'No packages available',
              style: TextStyle(color: _textMuted),
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _packages.length,
            itemBuilder: (context, index) {
              final package = _packages[index];
              final isSelected = _selectedPackageIndex == index;
              final bonus = _settings?.promotionActive == true && 
                  package.coinAmount >= (_settings?.promotionMinPurchase ?? 0)
                  ? (package.coinAmount * (_settings?.promotionBonus ?? 0) / 100).round()
                  : 0;
              final totalCoins = package.coinAmount + bonus;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPackageIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? _gold.withOpacity(0.1) : _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _gold : _border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? _gold : _gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '🪙',
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${package.coinAmount}',
                                  style: TextStyle(
                                    color: isSelected ? _gold : _textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                                const Text(
                                  ' Coins',
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (bonus > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+$bonus Bonus Coins!',
                                  style: TextStyle(
                                    color: _green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${package.priceInRupees.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isSelected ? _gold : _textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          Text(
                            '₹${package.ratePerCoin.toStringAsFixed(2)}/coin',
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (_selectedPackageIndex >= 0)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _purchaseCoins,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'BUY NOW',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromotionCard() {
    final promotion = _settings;
    if (promotion == null || !promotion.promotionActive) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _green.withOpacity(0.2),
            _cyan.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.celebration, color: _green, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎉 Limited Time Offer!',
                  style: TextStyle(
                    color: _green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get ${promotion.promotionBonus}% bonus on purchases above ${promotion.promotionMinPurchase} coins!',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT TRANSACTIONS',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _gold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        if (_transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const Text(
              'No transactions yet',
              style: TextStyle(color: _textMuted),
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length > 10 ? 10 : _transactions.length,
            itemBuilder: (context, index) {
              final txn = _transactions[index];
              final isPositive = txn.transactionType == 'purchase' || txn.transactionType == 'reward';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPositive ? _green.withOpacity(0.1) : _rose.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isPositive ? _green : _rose,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txn.transactionType.toUpperCase(),
                            style: TextStyle(
                              color: isPositive ? _green : _rose,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            txn.description ?? '${txn.amount.toStringAsFixed(0)} coins',
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : '-'}${txn.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isPositive ? _green : _rose,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
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
}