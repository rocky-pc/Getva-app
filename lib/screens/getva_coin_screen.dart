import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/getva_coin.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'getva_coin_upi_payment_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS - Enhanced Color Palette
// ═══════════════════════════════════════════════════════════════
const _gold        = Color(0xFFD4A847);
const _goldBright  = Color(0xFFFFE066);
const _goldDeep    = Color(0xFFB8892A);
const _goldGlow    = Color(0xFFFFD966);
const _surface     = Color(0xFF0A0910);
const _cardBg      = Color(0xFF110F1E);
const _cardBg2     = Color(0xFF16132A);
const _indigo      = Color(0xFF6366F1);
const _violet      = Color(0xFF8B5CF6);
const _violetLight = Color(0xFF8B6FE8);
const _green       = Color(0xFF22C55E);
const _cyan        = Color(0xFF00E5FF);
const _rose        = Color(0xFFFF3D71);
const _red         = Color(0xFFEF4444);
const _textPrimary = Colors.white;
const _textMuted   = Color(0xFF6B6880);
const _border      = Color(0xFF1E1B32);

// ═══════════════════════════════════════════════════════════════
//  GETVA COIN SCREEN - Enhanced Version
// ═══════════════════════════════════════════════════════════════
class GetvaCoinScreen extends StatefulWidget {
  const GetvaCoinScreen({super.key});

  @override
  State<GetvaCoinScreen> createState() => _GetvaCoinScreenState();
}

class _GetvaCoinScreenState extends State<GetvaCoinScreen>
    with TickerProviderStateMixin {

  // ── API State ────────────────────────────────────────────────
  GetvaCoinSettings? _settings;
  GetvaCoinWallet? _wallet;
  List<GetvaCoinTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  
  // ── Purchase State ──────────────────────────────────────────
  final TextEditingController _coinAmountController = TextEditingController();
  int _coinAmount = 0;

  // ── UI State ─────────────────────────────────────────────────
  String _selectedPeriod = '24H';
  bool _animationsReady = false;
  int _selectedChartIndex = -1;

  // ── Chart Data ───────────────────────────────────────────────
  late List<FlSpot> _priceSpots;
  late List<FlSpot> _volumeSpots;
  List<double> _chartData = [];

  // ── Animation Controllers ────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _chartAnimationCtrl;
  late AnimationController _glowCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _entryAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _chartAnim;
  late Animation<double> _glowAnim;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initChartData();
    _initAnimations();
    _loadData();
  }

  void _initChartData() {
    // Generate realistic crypto-style chart data
    final random = math.Random(42);
    double price = 38.5;
    List<double> data = [];
    for (int i = 0; i < 30; i++) {
      // Add realistic price movement with volatility
      double change = (random.nextDouble() - 0.5) * 2.5;
      price = (price + change).clamp(35.0, 48.0);
      data.add(price);
    }
    _chartData = data;

    _priceSpots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    _volumeSpots = List.generate(data.length, (i) => FlSpot(i.toDouble(), random.nextDouble() * 15 + 5));
  }

  void _initAnimations() {
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);

    _chartAnimationCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _chartAnim = CurvedAnimation(parent: _chartAnimationCtrl, curve: Curves.easeOutCubic);

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    final rng = math.Random(99);
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: rng.nextDouble() * 2.0 + 0.5,
        speed: rng.nextDouble() * 0.3 + 0.1,
        opacity: rng.nextDouble() * 0.4 + 0.05,
        phase: rng.nextDouble(),
      ));
    }

    _animationsReady = true;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _entryCtrl.forward();
        _chartAnimationCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    _particleCtrl.dispose();
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    _chartAnimationCtrl.dispose();
    _glowCtrl.dispose();
    _coinAmountController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  DATA LOADING (same as original)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      GetvaCoinSettings? settings;
      try {
        final settingsResponse = await ApiService.getGetvaCoinSettings();
        if (settingsResponse != null && settingsResponse['success'] == true) {
          settings = GetvaCoinSettings.fromJson(settingsResponse['data'] ?? {});
        }
      } catch (e) {
        print('Error loading settings: $e');
      }

      GetvaCoinWallet? wallet;
      try {
        final userId = await SessionManager.getUserId();
        if (userId != null) {
          final walletResponse = await ApiService.getGetvaCoinWallet(userId);
          if (walletResponse != null &&
              walletResponse['success'] == true &&
              walletResponse['data'] != null) {
            wallet = GetvaCoinWallet.fromJson(walletResponse['data']);
          }
        }
      } catch (e) {
        print('Error loading wallet: $e');
      }

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
        print('Error loading transactions: $e');
      }

      if (mounted) {
        setState(() {
          _settings = settings;
          _wallet = wallet;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadData: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _purchaseCoins() async {
    if (_coinAmount <= 0) {
      _showError('Please enter a valid coin amount');
      return;
    }

    final minPurchase = _settings?.minPurchase ?? 10;
    final maxPurchase = _settings?.maxPurchase ?? 5000;

    if (_coinAmount < minPurchase) {
      _showError('Minimum purchase is $minPurchase coins');
      return;
    }

    if (_coinAmount > maxPurchase) {
      _showError('Maximum purchase is $maxPurchase coins');
      return;
    }

    try {
      final userId = await SessionManager.getUserId();
      if (userId == null) {
        _showError('Please login to purchase coins');
        return;
      }

      final response = await ApiService.purchaseGetvaCoins(
        userId: userId,
        coinAmount: _coinAmount,
      );

      if (response != null && response['success'] == true) {
        _showSuccess('Coins purchased successfully!');
        _coinAmountController.clear();
        setState(() => _coinAmount = 0);
        _loadData();
      } else {
        _showError(response?['message'] ?? 'Purchase failed');
      }
    } catch (_) {
      _showError('Purchase failed. Please try again.');
    }
  }

  void _navigateToUpiPayment() {
    if (_coinAmount <= 0) {
      _showError('Please enter a valid coin amount');
      return;
    }

    final minPurchase = _settings?.minPurchase ?? 10;
    final maxPurchase = _settings?.maxPurchase ?? 5000;

    if (_coinAmount < minPurchase) {
      _showError('Minimum purchase is $minPurchase coins');
      return;
    }

    if (_coinAmount > maxPurchase) {
      _showError('Maximum purchase is $maxPurchase coins');
      return;
    }

    final exchangeRate = _settings?.exchangeRate ?? 1.0;
    final totalPrice = _coinAmount * exchangeRate;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GetvaCoinUpiPaymentScreen(
          coinAmount: _coinAmount,
          totalPrice: totalPrice,
          exchangeRate: exchangeRate,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ENHANCED BUILD METHOD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isEnabled = _settings?.isEnabled ?? true;

    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Enhanced Background with animated gradient
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF080714),
                        Color(0xFF0A0910),
                        Color(0xFF060512),
                        Color(0xFF0B0820),
                      ],
                      stops: [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Animated orbs with enhanced effects
          if (_animationsReady)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _orbAnim,
                builder: (context, child) => Stack(
                  children: [
                    Positioned(
                      top: -100 + _orbAnim.value * 60,
                      left: size.width / 2 - 250,
                      child: _EnhancedOrbGlow(
                        color: _gold.withOpacity(0.12 + _pulseAnim.value * 0.08),
                        size: 480,
                        blurSigma: 80,
                      ),
                    ),
                    Positioned(
                      bottom: 80 + _orbAnim.value * -40,
                      right: -120,
                      child: _EnhancedOrbGlow(
                        color: _violet.withOpacity(0.1),
                        size: 360,
                        blurSigma: 60,
                      ),
                    ),
                    Positioned(
                      top: size.height * 0.3,
                      left: -80,
                      child: _EnhancedOrbGlow(
                        color: _cyan.withOpacity(0.05),
                        size: 280,
                        blurSigma: 50,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Enhanced particle system
          if (_animationsReady)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleCtrl,
                builder: (context, child) => CustomPaint(
                  painter: _EnhancedParticlePainter(
                    particles: _particles,
                    progress: _particleCtrl.value,
                  ),
                ),
              ),
            ),

          // Glassmorphism overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Content
          SafeArea(
            child: _isLoading || !_animationsReady
                ? _buildLoadingView()
                : _error != null
                ? _buildErrorView()
                : !isEnabled
                ? _buildDisabledView()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  // ── Enhanced Loading View ────────────────────────────────────
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_gold, _goldDeep],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🪙', style: TextStyle(fontSize: 32)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Getva Coin...',
            style: TextStyle(color: _textMuted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation(_gold),
              strokeWidth: 3,
              backgroundColor: _gold.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // ── Enhanced Error View ──────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _rose.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _rose.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.error_outline, color: _rose, size: 48),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              _error ?? 'Something went wrong',
              style: const TextStyle(color: _textMuted, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_gold, _goldDeep]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _gold.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: _surface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _textMuted.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _textMuted.withOpacity(0.2), width: 1),
            ),
            child: const Icon(Icons.block_rounded, color: _textMuted, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'Getva Coin is currently\ndisabled',
            style: TextStyle(color: _textMuted, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Enhanced Main Content ────────────────────────────────────
  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _gold,
      backgroundColor: _cardBg,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          _buildEnhancedAppBar(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(animation: _entryAnim, delay: 0.0, child: _buildEnhancedHeroCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(animation: _entryAnim, delay: 0.1, child: _buildEnhancedPeriodSelector()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(animation: _entryAnim, delay: 0.2, child: _buildEnhancedChartSection()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(animation: _entryAnim, delay: 0.25, child: _buildEnhancedStatsRow()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(animation: _entryAnim, delay: 0.3, child: _buildEnhancedExchangeRateCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          if (_settings?.promotionActive == true)
            SliverToBoxAdapter(
              child: _AnimatedReveal(animation: _entryAnim, delay: 0.35, child: _buildEnhancedPromotionCard()),
            ),
          if (_settings?.promotionActive == true)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(animation: _entryAnim, delay: 0.4, child: _buildEnhancedPackagesSection()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(animation: _entryAnim, delay: 0.5, child: _buildEnhancedTransactionsSection()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ENHANCED SECTION WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEnhancedAppBar() {
    final balance = _wallet?.coinBalance ?? 0.0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            _EnhancedGlassButton(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Getva Coin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_gold, _goldDeep]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('GVC',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Balance: ${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            _EnhancedGlassButton(
              onTap: () {},
              child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeroCard() {
    final balance = _wallet?.coinBalance ?? 0.0;
    final rate = _settings?.exchangeRate ?? 1.0;
    final valueInRupees = balance * rate;
    final isPositiveDay = true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_cardBg, _cardBg2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: _gold.withOpacity(0.3 + _glowAnim.value * 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(0.15 + _glowAnim.value * 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Coin Balance',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '🪙 ${balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6, left: 6),
                              child: Text(
                                'GVC',
                                style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '≈ ₹${valueInRupees.toStringAsFixed(2)} INR',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + value * 0.2,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_goldDeep, _gold, _goldBright],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('🪙', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildEnhancedMiniTrend(
                      '${isPositiveDay ? '+' : ''}${(rate * 100 - 100).toStringAsFixed(2)}%',
                      isPositiveDay,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _green.withOpacity(0.3)),
                      ),
                      child: Text(
                        '1 GVC = ₹${rate.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: _green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildEnhancedMiniTrend(String value, bool isUp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isUp ? _green : _rose).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isUp ? _green : _rose).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: isUp ? _green : _rose,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: isUp ? _green : _rose,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPeriodSelector() {
    final periods = ['1H', '24H', '1W', '1M', '1Y'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _cardBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: periods.map((p) => Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = p);
                _updateChartDataForPeriod(p);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _selectedPeriod == p
                      ? const LinearGradient(colors: [_goldDeep, _gold])
                      : null,
                  color: _selectedPeriod == p ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedPeriod == p ? Colors.white : _textMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  void _updateChartDataForPeriod(String period) {
    // Simulate chart data update based on period
    final random = math.Random(42);
    double price = 38.5;
    int points = period == '1H' ? 24 : period == '24H' ? 30 : period == '1W' ? 50 : period == '1M' ? 60 : 100;
    List<double> data = [];
    for (int i = 0; i < points; i++) {
      double change = (random.nextDouble() - 0.5) * (period == '1Y' ? 3.0 : 2.0);
      price = (price + change).clamp(35.0, 48.0);
      data.add(price);
    }
    setState(() {
      _chartData = data;
      _priceSpots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    });
    _chartAnimationCtrl.reset();
    _chartAnimationCtrl.forward();
  }

  Widget _buildEnhancedChartSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _chartAnim,
        builder: (context, child) {
          return Container(
            height: 260,
            padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_cardBg2, _cardBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Price Chart',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildChartLegend(),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Stack(
                    children: [
                      LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 2,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: _textMuted.withOpacity(0.1),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 25,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index % 5 == 0 && index < _chartData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${index + 1}d',
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '₹${value.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _priceSpots.map((spot) => FlSpot(spot.x, spot.y * _chartAnim.value)).toList(),
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [_goldDeep, _gold, _goldBright],
                              ),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _gold.withOpacity(0.35),
                                    _gold.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipRoundedRadius: 12,
                              tooltipBorder: BorderSide(color: _gold.withOpacity(0.5), width: 1),
                              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '₹${spot.y.toStringAsFixed(2)}',
                                    const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 12),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                      // Animated glow effect on chart
                      Positioned(
                        right: 10,
                        top: 10,
                        child: AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (context, child) {
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _gold.withOpacity(0.3 + _glowAnim.value * 0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _textMuted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'GVC Price',
            style: TextStyle(color: _textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsRow() {
    final rate = _settings?.exchangeRate ?? 1.0;
    final volume = 2456789;
    final marketCap = 12500000;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildEnhancedStatCard('Exchange Rate', '₹${rate.toStringAsFixed(2)}', Icons.currency_exchange, _cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEnhancedStatCard('24h Volume', '₹${(volume / 1000000).toStringAsFixed(1)}M', Icons.trending_up, _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildEnhancedStatCard('Market Cap', '₹${(marketCap / 1000000).toStringAsFixed(0)}M', Icons.show_chart, _gold),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardBg, _cardBg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedExchangeRateCard() {
    final rate = _settings?.exchangeRate ?? 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _cardBg,
                  _cardBg2,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _gold.withOpacity(0.2 + _pulseAnim.value * 0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_cyan, Color(0xFF00A3FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.currency_exchange, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Exchange Rate',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 GVC = ₹${rate.toStringAsFixed(2)} INR',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: Just now',
                        style: TextStyle(
                          color: _textMuted.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_upward, color: _green, size: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedPromotionCard() {
    final promotion = _settings;
    if (promotion == null || !promotion.promotionActive) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + value * 0.05,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _green.withOpacity(0.2),
                    _cyan.withOpacity(0.1),
                    _green.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _green.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _green.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_green, Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.celebration, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎉 LIMITED TIME OFFER! 🎉',
                          style: TextStyle(
                            color: _green,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get ${promotion.promotionBonus}% bonus coins on purchases above ${promotion.promotionMinPurchase} coins!',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _green, size: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedPackagesSection() {
    final exchangeRate = _settings?.exchangeRate ?? 1.0;
    final minPurchase = _settings?.minPurchase ?? 10;
    final maxPurchase = _settings?.maxPurchase ?? 5000;
    final totalPrice = _coinAmount * exchangeRate;
    final bonus = _settings?.promotionActive == true &&
        _coinAmount >= (_settings?.promotionMinPurchase ?? 0)
        ? (_coinAmount * (_settings?.promotionBonus ?? 0) / 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_gold, _goldDeep]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'BUY COINS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _gold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '1 GVC = ₹${exchangeRate.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                // Coin amount input
                TextField(
                  controller: _coinAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Enter Coin Amount',
                    labelStyle: const TextStyle(color: _textMuted),
                    hintText: 'e.g., 100',
                    hintStyle: TextStyle(color: _textMuted.withOpacity(0.5)),
                    prefixIcon: const Text('🪙', style: TextStyle(fontSize: 24)),
                    suffixText: 'GVC',
                    suffixStyle: const TextStyle(color: _gold, fontWeight: FontWeight.w600),
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
                  ),
                  onChanged: (value) {
                    setState(() {
                      _coinAmount = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Min/Max hints
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Min: $minPurchase GVC',
                      style: const TextStyle(color: _textMuted, fontSize: 11),
                    ),
                    Text(
                      'Max: $maxPurchase GVC',
                      style: const TextStyle(color: _textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Price calculation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_gold.withOpacity(0.1), _goldDeep.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _gold.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'You Pay:',
                            style: TextStyle(color: _textMuted, fontSize: 14),
                          ),
                          Text(
                            '₹${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (bonus > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bonus Coins:',
                              style: TextStyle(color: _green, fontSize: 14),
                            ),
                            Text(
                              '+$bonus GVC',
                              style: const TextStyle(
                                color: _green,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Coins:',
                              style: TextStyle(color: _textPrimary, fontSize: 14),
                            ),
                            Text(
                              '${_coinAmount + bonus} GVC',
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Enhanced BUY button
          if (_coinAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  // UPI Payment Button
                  GestureDetector(
                    onTap: () => _navigateToUpiPayment(),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_cyan, Color(0xFF0099CC)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _cyan.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'PAY VIA UPI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Direct Purchase Button (if wallet has sufficient balance)
                  GestureDetector(
                    onTap: _purchaseCoins,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_goldDeep, _gold, _goldBright],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withOpacity(0.4 + _pulseAnim.value * 0.2),
                                blurRadius: 25,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'BUY $_coinAmount COINS 🪙',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_gold, _goldDeep]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RECENT TRANSACTIONS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _gold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_transactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: _textMuted.withOpacity(0.5), size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'No transactions yet',
                    style: TextStyle(color: _textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your first purchase will appear here',
                    style: TextStyle(color: _textMuted.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length > 8 ? 8 : _transactions.length,
              itemBuilder: (context, index) {
                final txn = _transactions[index];
                final isPositive = txn.transactionType == 'purchase' ||
                    txn.transactionType == 'reward';
                final color = isPositive ? _green : _rose;

                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isPositive
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: color,
                                  size: 22,
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
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      txn.description ??
                                          '${txn.amount.toStringAsFixed(0)} coins',
                                      style: const TextStyle(
                                          color: _textMuted, fontSize: 11),
                                    ),
                                    Text(
                                      _formatDate(txn.createdAt),
                                      style: const TextStyle(
                                          color: _textMuted, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isPositive ? '+' : '-'}${txn.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  ENHANCED HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _EnhancedGlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _EnhancedGlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _EnhancedOrbGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double blurSigma;

  const _EnhancedOrbGlow({
    required this.color,
    required this.size,
    this.blurSigma = 50,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withOpacity(0)],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double x, y, radius, speed, opacity, phase;
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

class _EnhancedParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _EnhancedParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = (p.y - t) % 1.0;
      final x = p.x + math.sin(t * math.pi * 2 + p.phase * 6) * 0.04;

      // Create gradient for each particle
      final gradientColor = (i % 3 != 0 ? _gold : _goldBright);
      paint.color = gradientColor.withOpacity(p.opacity * (0.5 + math.sin(progress * math.pi * 2) * 0.3));

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EnhancedParticlePainter old) => old.progress != progress;
}

class _AnimatedReveal extends StatelessWidget {
  final Animation<double> animation;
  final double delay;
  final Widget child;

  const _AnimatedReveal({
    required this.animation,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = ((animation.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}