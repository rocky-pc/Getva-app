import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
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
//  GETVA COIN SCREEN
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
  List<GetvaCoinPackage> _packages = [];
  GetvaCoinWallet? _wallet;
  List<GetvaCoinTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  int _selectedPackageIndex = -1;

  // ── UI State ─────────────────────────────────────────────────
  String _selectedPeriod = '24H';
  bool _animationsReady = false;

  // ── Animation Controllers ────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _entryAnim;
  late Animation<double> _shimmerAnim;

  final List<_Particle> _particles = [];

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
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
    _pulseAnim =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _orbAnim =
        CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);

    final rng = math.Random(99);
    for (int i = 0; i < 25; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: rng.nextDouble() * 1.5 + 0.5,
        speed: rng.nextDouble() * 0.3 + 0.1,
        opacity: rng.nextDouble() * 0.3 + 0.05,
        phase: rng.nextDouble(),
      ));
    }

    _animationsReady = true;

    Future.delayed(const Duration(milliseconds: 100),
            () { if (mounted) _entryCtrl.forward(); });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    _particleCtrl.dispose();
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  DATA LOADING
  // ═══════════════════════════════════════════════════════════════
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
          settings =
              GetvaCoinSettings.fromJson(settingsResponse['data'] ?? {});
        }
      } catch (_) {}

      // Load packages
      List<GetvaCoinPackage> packages = [];
      try {
        final packagesResponse = await ApiService.getGetvaCoinPackages();
        if (packagesResponse != null && packagesResponse['success'] == true) {
          final list = packagesResponse['data'] as List<dynamic>? ?? [];
          packages = list.map((p) => GetvaCoinPackage.fromJson(p)).toList();
        }
      } catch (_) {}

      // Load wallet
      GetvaCoinWallet? wallet;
      try {
        final userId = await SessionManager.getUserId();
        if (userId != null) {
          final walletResponse =
          await ApiService.getGetvaCoinWallet(userId);
          if (walletResponse != null &&
              walletResponse['success'] == true &&
              walletResponse['data'] != null) {
            wallet = GetvaCoinWallet.fromJson(walletResponse['data']);
          }
        }
      } catch (_) {}

      // Load transactions
      List<GetvaCoinTransaction> transactions = [];
      try {
        final userId = await SessionManager.getUserId();
        if (userId != null) {
          final txnResponse =
          await ApiService.getGetvaCoinTransactions(userId);
          if (txnResponse != null && txnResponse['success'] == true) {
            final txnList = txnResponse['data'] as List<dynamic>? ?? [];
            transactions =
                txnList.map((t) => GetvaCoinTransaction.fromJson(t)).toList();
          }
        }
      } catch (_) {}

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

  // ═══════════════════════════════════════════════════════════════
  //  PURCHASE
  // ═══════════════════════════════════════════════════════════════
  Future<void> _purchaseCoins() async {
    if (_selectedPackageIndex < 0 ||
        _selectedPackageIndex >= _packages.length) {
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
    } catch (_) {
      _showError('Purchase failed. Please try again.');
    }
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
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isEnabled = _settings?.isEnabled ?? true;

    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF080714),
                    Color(0xFF0A0910),
                    Color(0xFF060512),
                  ],
                ),
              ),
            ),
          ),
          // Animated orbs
          if (_animationsReady)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _orbAnim,
                builder: (context, child) => Stack(
                  children: [
                    Positioned(
                      top: -100 + _orbAnim.value * 40,
                      left: size.width / 2 - 200,
                      child: _OrbGlow(
                        color: _gold.withOpacity(0.08 + _pulseAnim.value * 0.04),
                        size: 420,
                      ),
                    ),
                    Positioned(
                      bottom: 100 + _orbAnim.value * -30,
                      right: -100,
                      child: _OrbGlow(
                        color: _violet.withOpacity(0.08),
                        size: 300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Particles
          if (_animationsReady)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleCtrl,
                builder: (context, child) => CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleCtrl.value,
                  ),
                ),
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

  // ── Loading ──────────────────────────────────────────────────
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _gold),
          SizedBox(height: 16),
          Text('Loading...', style: TextStyle(color: _textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _rose.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: _rose, size: 48),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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

  // ── Disabled ─────────────────────────────────────────────────
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
            ),
            child:
            const Icon(Icons.block_rounded, color: _textMuted, size: 48),
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

  // ── Main Content ─────────────────────────────────────────────
  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _gold,
      backgroundColor: _cardBg,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          _buildAppBar(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(
                animation: _entryAnim, delay: 0.0, child: _buildHeroCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(
                animation: _entryAnim,
                delay: 0.1,
                child: _buildPeriodSelector()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(
                animation: _entryAnim,
                delay: 0.2,
                child: _buildChartSection()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(
                animation: _entryAnim,
                delay: 0.3,
                child: _buildExchangeRateCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          if (_settings?.promotionActive == true)
            SliverToBoxAdapter(
              child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.35,
                  child: _buildPromotionCard()),
            ),
          if (_settings?.promotionActive == true)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(
                animation: _entryAnim,
                delay: 0.4,
                child: _buildPackagesSection()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _AnimatedReveal(
                animation: _entryAnim,
                delay: 0.5,
                child: _buildTransactionsSection()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAppBar() {
    final balance = _wallet?.coinBalance ?? 0.0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            _GlassButton(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
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
                      fontWeight: FontWeight.w900),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('GVC',
                          style: TextStyle(
                              color: _gold,
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
            _GlassButton(
              onTap: () {},
              child: const Icon(Icons.history_rounded,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  /// Hero wallet card — replaces the static price card with real wallet data
  Widget _buildHeroCard() {
    final balance = _wallet?.coinBalance ?? 0.0;
    final rate = _settings?.exchangeRate ?? 1.0;
    final valueInRupees = balance * rate;
    final isPositiveDay = true; // can be driven by API later

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_cardBg, _cardBg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: _gold.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10)),
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
                          fontWeight: FontWeight.w600),
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
                    Text(
                      '≈ ₹${valueInRupees.toStringAsFixed(2)} INR',
                      style: TextStyle(
                          color: _gold.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_goldDeep, _gold]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: _gold.withOpacity(0.35), blurRadius: 15)
                    ],
                  ),
                  child: const Center(
                    child: Text('🪙', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildMiniTrend(
                    '${isPositiveDay ? '+' : ''}${(rate * 100 - 100).toStringAsFixed(2)}%',
                    isPositiveDay),
                const SizedBox(width: 12),
                Text(
                  '1 GVC = ₹${rate.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: _green.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTrend(String value, bool isUp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isUp ? _green : _rose).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: isUp ? _green : _rose,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
                color: isUp ? _green : _rose,
                fontSize: 12,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['1H', '24H', '1W', '1M', '1Y'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: periods
            .map((p) => GestureDetector(
          onTap: () => setState(() => _selectedPeriod = p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: _selectedPeriod == p
                  ? const LinearGradient(
                  colors: [_goldDeep, _gold])
                  : null,
              color: _selectedPeriod == p
                  ? null
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedPeriod == p
                    ? _gold.withOpacity(0.5)
                    : _border,
              ),
            ),
            child: Text(
              p,
              style: TextStyle(
                color: _selectedPeriod == p
                    ? Colors.white
                    : _textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildChartSection() {
    // Chart uses static demo data (price history from API can be wired here)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 220,
        padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
        decoration: BoxDecoration(
          color: _cardBg2,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 38),
                  FlSpot(1, 41),
                  FlSpot(2, 39.5),
                  FlSpot(3, 43),
                  FlSpot(4, 41.5),
                  FlSpot(5, 44),
                  FlSpot(6, 42.85),
                ],
                isCurved: true,
                gradient:
                const LinearGradient(colors: [_goldDeep, _gold]),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _gold.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeRateCard() {
    final rate = _settings?.exchangeRate ?? 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
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
              child: const Icon(Icons.currency_exchange,
                  color: _cyan, size: 26),
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
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1 GVC = ₹${rate.toStringAsFixed(2)} INR',
                    style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Promotion banner (only shown when promotionActive == true)
  Widget _buildPromotionCard() {
    final promotion = _settings;
    if (promotion == null || !promotion.promotionActive) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _green.withOpacity(0.18),
              _cyan.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
              const Icon(Icons.celebration, color: _green, size: 26),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get ${promotion.promotionBonus}% bonus on purchases above ${promotion.promotionMinPurchase} coins!',
                    style: const TextStyle(
                        color: _textPrimary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Packages section — real packages from API, with bonus calculation
  Widget _buildPackagesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BUY COINS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
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
                borderRadius: BorderRadius.circular(18),
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
                    package.coinAmount >=
                        (_settings?.promotionMinPurchase ?? 0)
                    ? (package.coinAmount *
                    (_settings?.promotionBonus ?? 0) /
                    100)
                    .round()
                    : 0;

                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedPackageIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          _gold.withOpacity(0.12),
                          _goldDeep.withOpacity(0.06),
                        ],
                      )
                          : null,
                      color: isSelected ? null : _cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? _gold : _border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: _gold.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Coin icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _gold.withOpacity(0.2)
                                : _gold.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(
                                color: _gold.withOpacity(0.4))
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '🪙',
                              style: TextStyle(
                                  fontSize: isSelected ? 26 : 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Coin amount + bonus
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${package.coinAmount}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? _gold
                                          : _textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Text(
                                    ' Coins',
                                    style: TextStyle(
                                        color: _textMuted,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                              if (bonus > 0) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _green.withOpacity(0.15),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+$bonus Bonus Coins!',
                                    style: const TextStyle(
                                      color: _green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${package.priceInRupees.toStringAsFixed(0)}',
                              style: TextStyle(
                                color:
                                isSelected ? _gold : _textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '₹${package.ratePerCoin.toStringAsFixed(2)}/coin',
                              style: const TextStyle(
                                  color: _textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.check_circle_rounded,
                              color: _gold, size: 20),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

          // BUY button — visible when a package is selected
          if (_selectedPackageIndex >= 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GestureDetector(
                onTap: _purchaseCoins,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_goldDeep, _gold]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: _gold.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'BUY NOW 🪙',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Transaction history from real API
  Widget _buildTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT TRANSACTIONS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          if (_transactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: _textMuted.withOpacity(0.5), size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'No transactions yet',
                    style: TextStyle(color: _textMuted, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
              _transactions.length > 10 ? 10 : _transactions.length,
              itemBuilder: (context, index) {
                final txn = _transactions[index];
                final isPositive = txn.transactionType == 'purchase' ||
                    txn.transactionType == 'reward';
                final color = isPositive ? _green : _rose;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPositive
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn.transactionType.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              txn.description ??
                                  '${txn.amount.toStringAsFixed(0)} coins',
                              style: const TextStyle(
                                  color: _textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isPositive ? '+' : '-'}${txn.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border:
          Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _OrbGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _OrbGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
        RadialGradient(colors: [color, color.withOpacity(0)]),
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

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ParticlePainter(
      {required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = (p.y - t) % 1.0;
      final x = p.x +
          math.sin(t * math.pi * 2 + p.phase * 6) * 0.04;
      paint.color =
          (i % 3 != 0 ? _gold : _goldDeep).withOpacity(p.opacity);
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress;
}

class _AnimatedReveal extends StatelessWidget {
  final Animation<double> animation;
  final double delay;
  final Widget child;

  const _AnimatedReveal(
      {required this.animation,
        required this.delay,
        required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t =
        ((animation.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
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