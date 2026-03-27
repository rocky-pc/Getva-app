import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/session_manager.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════
const _gold = Color(0xFFD4A847);
const _goldBright = Color(0xFFFFE066);
const _goldDeep = Color(0xFFB8892A);
const _surface = Color(0xFF0A0910);
const _cardBg = Color(0xFF110F1E);
const _cardBg2 = Color(0xFF16132A);
const _violet = Color(0xFF5A3FBF);
const _violetLight = Color(0xFF8B6FE8);
const _green = Color(0xFF22C55E);
const _red = Color(0xFFEF4444);
const _textPrimary = Colors.white;
const _textMuted = Color(0xFF6B6880);
const _border = Color(0xFF1E1B32);
const _cyan = Color(0xFF00C8FF);

// ═══════════════════════════════════════════════════════════════
//  GETVA COIN UPI PAYMENT SCREEN
// ═══════════════════════════════════════════════════════════════
class GetvaCoinUpiPaymentScreen extends StatefulWidget {
  final int coinAmount;
  final double totalPrice;
  final double exchangeRate;

  const GetvaCoinUpiPaymentScreen({
    Key? key,
    required this.coinAmount,
    required this.totalPrice,
    required this.exchangeRate,
  }) : super(key: key);

  @override
  State<GetvaCoinUpiPaymentScreen> createState() =>
      _GetvaCoinUpiPaymentScreenState();
}

class _GetvaCoinUpiPaymentScreenState extends State<GetvaCoinUpiPaymentScreen> {
  final _utrController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _upiId = '';
  String _upiName = '';
  bool _upiEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUpiSettings();
  }

  Future<void> _loadUpiSettings() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/upi_payments.php?action=get_settings'),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['settings'] != null) {
        final settings = data['settings'];
        setState(() {
          _upiId = settings['upi_id'] ?? '';
          _upiName = settings['upi_name'] ?? 'Getva Wallet';
          _upiEnabled = settings['upi_enabled'] == '1';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buy GVC via UPI',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _gold, strokeWidth: 2.5),
            )
          : _upiEnabled && _upiId.isNotEmpty
          ? _buildContent()
          : _buildUpiDisabled(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOrderSummary(),
          const SizedBox(height: 24),
          _buildInstructions(),
          const SizedBox(height: 24),
          _buildUpiCard(),
          const SizedBox(height: 24),
          _buildUtrInput(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardBg, _cardBg2],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Coins to Buy:',
                style: TextStyle(color: _textMuted, fontSize: 14),
              ),
              Text(
                '${widget.coinAmount} GVC',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exchange Rate:',
                style: TextStyle(color: _textMuted, fontSize: 14),
              ),
              Text(
                '1 GVC = ₹${widget.exchangeRate.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(color: _textPrimary, fontSize: 16),
                ),
                Text(
                  '₹${widget.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiDisabled() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.info_outline, color: _red, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'UPI Payments Unavailable',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'UPI payment option is currently disabled. Please try again later.',
              style: TextStyle(color: _textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: _cyan, size: 20),
              SizedBox(width: 8),
              Text(
                'How it works',
                style: TextStyle(
                  color: _cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStep(
            '1',
            'Open any UPI app (Google Pay, PhonePe, Paytm, etc.)',
          ),
          const SizedBox(height: 8),
          _buildStep(
            '2',
            'Send ₹${widget.totalPrice.toStringAsFixed(2)} to $_upiId',
          ),
          const SizedBox(height: 8),
          _buildStep('3', 'Enter the UTR/Transaction number below'),
          const SizedBox(height: 8),
          _buildStep('4', 'Wait for admin verification (up to 24 hours)'),
          const SizedBox(height: 8),
          _buildStep(
            '5',
            'Once verified, ${widget.coinAmount} GVC will be added to your wallet',
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _cyan.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: _cyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildUpiCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardBg, _cardBg2],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: _gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pay to UPI ID',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _upiId,
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  color: _textMuted,
                  size: 20,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _upiId));
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('UPI ID copied to clipboard'),
                      backgroundColor: _cardBg2,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, color: _gold, size: 16),
                const SizedBox(width: 8),
                Text(
                  _upiName,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtrInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UTR / Transaction Number',
          style: TextStyle(
            color: _textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _utrController,
          style: const TextStyle(color: _textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter UTR number from your payment app',
            hintStyle: TextStyle(color: _textMuted.withOpacity(0.5)),
            filled: true,
            fillColor: _cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _gold, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You can find the UTR number in your payment app\'s transaction history',
          style: TextStyle(color: _textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: _surface,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: _surface,
                strokeWidth: 2.5,
              ),
            )
          : const Text(
              'Submit for Verification',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Future<void> _submitPayment() async {
    final utrNumber = _utrController.text.trim();

    if (utrNumber.isEmpty) {
      _showError('Please enter the UTR number');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = await SessionManager.getUserId();
      if (userId == null) {
        _showError('Please login to submit payment');
        return;
      }

      final response = await ApiService.submitGetvaCoinPurchase(
        userId: userId,
        coinAmount: widget.coinAmount,
        utrNumber: utrNumber,
        upiId: _upiId,
      );

      if (response['success'] == true) {
        _showSuccess('Payment submitted for verification!');
        Navigator.pop(context);
      } else {
        _showError(response['message'] ?? 'Failed to submit payment');
      }
    } catch (e) {
      _showError('Failed to submit payment: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
