import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../models/gold_rate.dart';
import 'upi_payment_screen.dart';

// ── Design tokens ────────────────────────────────────────────────
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
const _rose = Color(0xFFFF3D71);
const _textPrimary = Colors.white;
const _textMuted = Color(0xFF6B6880);
const _border = Color(0xFF1E1B32);
const _inputBg = Color(0xFF0D0B1A);

class GoldScreen extends StatefulWidget {
  const GoldScreen({super.key});

  @override
  State<GoldScreen> createState() => _GoldScreenState();
}

class _GoldScreenState extends State<GoldScreen> with TickerProviderStateMixin {
  late Future<List<GoldRate>> _goldRatesFuture;
  String _selectedGoldType = '24K';
  String _selectedPeriod = '3months';
  bool _isLoadingHistory = true;
  List<GoldRateHistory> _goldRateHistory = [];

  // ── Held-gold state (shown in AppBar) ──────────────────────────
  Map<String, double> _heldGoldByType = {};
  double _heldGoldGrams = 0.0;
  double _heldGoldValueInr = 0.0;
  bool _isLoadingHeldGold = true;

  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _entryCtrl;

  late Animation<double> _shimmerAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _entryAnim;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _entryAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );

    final rng = math.Random(88);
    for (int i = 0; i < 22; i++) {
      _particles.add(
        _Particle(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radius: rng.nextDouble() * 1.8 + 0.5,
          speed: rng.nextDouble() * 0.35 + 0.12,
          opacity: rng.nextDouble() * 0.38 + 0.07,
          phase: rng.nextDouble(),
        ),
      );
    }

    _goldRatesFuture = ApiService.getGoldRates();
    _loadHistory();
    _loadHeldGold();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    _particleCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Load user's held gold for AppBar display ──────────────────
  Future<void> _loadHeldGold() async {
    if (!mounted) return;
    setState(() => _isLoadingHeldGold = true);
    try {
      final userId = await SessionManager.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _isLoadingHeldGold = false);
        return;
      }
      final wallets = await ApiService.getUserGoldWallet(userId);
      final map = <String, double>{};
      for (final wallet in wallets) {
        map[wallet.goldType] = wallet.grams;
      }
      if (mounted) {
        setState(() {
          _heldGoldByType = map;
          _updateHeldGoldForType();
          _isLoadingHeldGold = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHeldGold = false);
    }
  }

  void _updateHeldGoldForType() {
    _heldGoldGrams = _heldGoldByType[_selectedGoldType] ?? 0.0;
    // Value is computed lazily once rates are loaded (see _buildAppBar)
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    try {
      final history = await ApiService.getGoldRateHistory(
        goldType: _selectedGoldType,
        period: _selectedPeriod,
      );
      if (mounted)
        setState(() {
          _goldRateHistory = history;
          _isLoadingHistory = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _onGoldTypeChanged(String? v) {
    if (v != null && v != _selectedGoldType) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedGoldType = v;
        _updateHeldGoldForType();
      });
      _loadHistory();
    }
  }

  void _onPeriodChanged(String v) {
    if (v != _selectedPeriod) {
      HapticFeedback.selectionClick();
      setState(() => _selectedPeriod = v);
      _loadHistory();
    }
  }

  void _showBuySheet(BuildContext context, List<GoldRate> goldRates) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _BuyGoldSheet(
          selectedGoldType: _selectedGoldType,
          goldRates: goldRates,
          onGoldTypeChanged: (t) {
            setState(() => _selectedGoldType = t);
            _updateHeldGoldForType();
          },
          onPurchaseComplete: () {
            _loadHeldGold();
          },
        ),
      ),
    );
  }

  void _showSellSheet(BuildContext context, List<GoldRate> goldRates) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _SellGoldSheet(
          selectedGoldType: _selectedGoldType,
          goldRates: goldRates,
          userGoldGrams: _heldGoldGrams,
          onGoldTypeChanged: (t) {
            setState(() => _selectedGoldType = t);
            _updateHeldGoldForType();
          },
          onSellComplete: () {
            _loadHeldGold();
          },
        ),
      ),
    );
  }

  Future<void> _refreshGoldData() async {
    setState(() {
      _goldRatesFuture = ApiService.getGoldRates();
    });
    _loadHistory();
    _loadHeldGold();
    try {
      final rates = await _goldRatesFuture;
      if (rates.isNotEmpty) {
        _selectedGoldType = rates
            .firstWhere(
              (r) => r.goldType == _selectedGoldType,
          orElse: () => rates.first,
        )
            .goldType;
      }
      await _loadHistory();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _surface,
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ── Background gradient ──────────────────────────────
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
            // ── Ambient orbs ────────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _orbAnim,
                builder: (context, child) => Stack(
                  children: [
                    Positioned(
                      top: -80 + _orbAnim.value * 35,
                      left: size.width / 2 - 190 + _orbAnim.value * 25,
                      child: _OrbGlow(
                        color: _gold.withOpacity(
                          0.16 + _pulseAnim.value * 0.06,
                        ),
                        size: 400,
                      ),
                    ),
                    Positioned(
                      top: 240 + _orbAnim.value * -28,
                      right: -90 + _orbAnim.value * 18,
                      child: _OrbGlow(
                        color: _violet.withOpacity(
                          0.10 + _pulseAnim.value * 0.03,
                        ),
                        size: 290,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Floating particles ───────────────────────────────
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
            // ── Noise texture ────────────────────────────────────
            Positioned.fill(
              child: Opacity(
                opacity: 0.022,
                child: CustomPaint(painter: _NoisePainter()),
              ),
            ),

            // ── Main scrollable content ──────────────────────────
            FutureBuilder<List<GoldRate>>(
              future: _goldRatesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _gold,
                      strokeWidth: 2,
                    ),
                  );
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty)
                  return _buildError(snapshot.error?.toString());

                final goldRates = snapshot.data!;
                final selectedRate = goldRates.firstWhere(
                      (r) => r.goldType == _selectedGoldType,
                  orElse: () => goldRates.first,
                );

                // Update held gold INR value now that we have the rate
                _heldGoldValueInr =
                    _heldGoldGrams * selectedRate.ratePerGram;

                return RefreshIndicator(
                  color: _gold,
                  onRefresh: _refreshGoldData,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildAppBar(selectedRate),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverToBoxAdapter(
                        child: _AnimatedReveal(
                          animation: _entryAnim,
                          delay: 0.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _RateHeroCard(
                              rate: selectedRate,
                              goldType: _selectedGoldType,
                              pulseAnim: _pulseAnim,
                              shimmerAnim: _shimmerAnim,
                              orbAnim: _orbAnim,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: _AnimatedReveal(
                          animation: _entryAnim,
                          delay: 0.1,
                          child: _GoldTypePicker(
                            selected: _selectedGoldType,
                            onChanged: _onGoldTypeChanged,
                            rates: goldRates,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: _AnimatedReveal(
                          animation: _entryAnim,
                          delay: 0.2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _ChartCard(
                              isLoading: _isLoadingHistory,
                              history: _goldRateHistory,
                              selectedPeriod: _selectedPeriod,
                              onPeriodChanged: _onPeriodChanged,
                              pulseAnim: _pulseAnim,
                              shimmerAnim: _shimmerAnim,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: _AnimatedReveal(
                          animation: _entryAnim,
                          delay: 0.3,
                          child: _buildStatsRow(selectedRate),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      SliverToBoxAdapter(
                        child: _AnimatedReveal(
                          animation: _entryAnim,
                          delay: 0.4,
                            child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _BuyButton(
                              pulseAnim: _pulseAnim,
                              onTap: () => _showBuySheet(context, goldRates),
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverToBoxAdapter(
                        child: _AnimatedReveal(
                          animation: _entryAnim,
                          delay: 0.45,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SellButton(
                              pulseAnim: _pulseAnim,
                              onTap: _heldGoldGrams > 0 
                                  ? () => _showSellSheet(context, goldRates)
                                  : null,
                              hasGold: _heldGoldGrams > 0,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 50)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar: title left + held-gold badge + notification right ──
  Widget _buildAppBar(GoldRate selectedRate) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button (if navigator can pop)
            if (Navigator.canPop(context))
              _GlassButton(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withOpacity(0.75),
                  size: 16,
                ),
              )
            else
              const SizedBox(width: 44),

            const SizedBox(width: 12),

            // ── "Digital Gold" shimmer title ──────────────────────
            _AnimatedReveal(
              animation: _entryAnim,
              delay: 0.0,
              child: AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (context, child) => ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: const [_gold, _goldBright, _gold],
                    begin: Alignment(-1.5 + _shimmerAnim.value * 4, 0),
                    end: Alignment(-0.5 + _shimmerAnim.value * 4, 0),
                  ).createShader(b),
                  child: child!,
                ),
                child: const Text(
                  'Digital Gold',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Held Gold Pill ────────────────────────────────────
            _AnimatedReveal(
              animation: _entryAnim,
              delay: 0.15,
              child: _HeldGoldBadge(
                isLoading: _isLoadingHeldGold,
                grams: _heldGoldGrams,
                valueInr: _heldGoldGrams * selectedRate.ratePerGram,
                goldType: _selectedGoldType,
                shimmerAnim: _shimmerAnim,
              ),
            ),

            const Spacer(),

            // Notification button
            _GlassButton(
              onTap: () {},
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(GoldRate rate) {
    const double changePercent = 0.0;
    const changeColor = changePercent >= 0 ? _green : _red;
    const changeIcon = changePercent >= 0
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              label: 'Per Gram',
              value: '₹${rate.ratePerGram.toStringAsFixed(0)}',
              icon: Icons.scale_rounded,
              iconColor: _gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              label: 'Per Tola',
              value: '₹${rate.ratePerTola.toStringAsFixed(0)}',
              icon: Icons.balance_rounded,
              iconColor: _violetLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              label: '24h Change',
              value:
              '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
              icon: changeIcon,
              iconColor: changeColor,
              valueColor: changeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String? err) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _red.withOpacity(0.1),
              border: Border.all(color: _red.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: _red,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load gold rates',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            err ?? 'Please check your connection',
            style: const TextStyle(color: _textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Held Gold Badge Widget ─────────────────────────────────────────
/// Compact pill shown next to the "Digital Gold" title in the AppBar.
/// Shows the user's current holdings for the selected gold type.
class _HeldGoldBadge extends StatelessWidget {
  final bool isLoading;
  final double grams;
  final double valueInr;
  final String goldType;
  final Animation<double> shimmerAnim;

  const _HeldGoldBadge({
    required this.isLoading,
    required this.grams,
    required this.valueInr,
    required this.goldType,
    required this.shimmerAnim,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Skeleton shimmer while loading
      return AnimatedBuilder(
        animation: shimmerAnim,
        builder: (context, _) => Container(
          width: 80,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + shimmerAnim.value * 4, 0),
              end: Alignment(-0.5 + shimmerAnim.value * 4, 0),
              colors: const [
                Color(0xFF1C1830),
                Color(0xFF2A2240),
                Color(0xFF1C1830),
              ],
            ),
          ),
        ),
      );
    }

    // No gold held — show a subtle empty state pill
    if (grams <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.diamond_outlined, color: _textMuted, size: 12),
            SizedBox(width: 5),
            Text(
              '0g held',
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Gold is held — show grams on top, value below, gold-bordered pill
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _gold.withOpacity(0.13),
              _goldBright.withOpacity(0.07),
              _gold.withOpacity(0.13),
            ],
            begin: Alignment(-1.5 + shimmerAnim.value * 4, 0),
            end: Alignment(-0.5 + shimmerAnim.value * 4, 0),
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gold coin icon
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_gold, _goldBright],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '✦',
                style: TextStyle(
                  color: Color(0xFF1A1200),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          // Grams + value stacked
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${grams.toStringAsFixed(3)}g',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      goldType,
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '₹${_formatCompact(valueInr)}',
                style: const TextStyle(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact number formatting: 1,23,456 → ₹1.23L; 9,999 → ₹9,999
  String _formatCompact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ────────────────────────────────────────────────────────────────────
// _RateHeroCard
// ────────────────────────────────────────────────────────────────────
class _RateHeroCard extends StatelessWidget {
  final GoldRate rate;
  final String goldType;
  final Animation<double> pulseAnim;
  final Animation<double> shimmerAnim;
  final Animation<double> orbAnim;

  const _RateHeroCard({
    required this.rate,
    required this.goldType,
    required this.pulseAnim,
    required this.shimmerAnim,
    required this.orbAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseAnim, orbAnim, shimmerAnim]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.14 + pulseAnim.value * 0.08),
                blurRadius: 36 + pulseAnim.value * 12,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            const Color(0xFF1C1735),
                            const Color(0xFF221A45),
                            pulseAnim.value,
                          )!,
                          const Color(0xFF13102A),
                          const Color(0xFF0E0C1C),
                        ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -40 + orbAnim.value * 14,
                  right: -30 + orbAnim.value * 10,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _gold.withOpacity(0.15 + pulseAnim.value * 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-2 + shimmerAnim.value * 4.5, -1),
                        end: Alignment(-1.5 + shimmerAnim.value * 4.5, 1),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardGridPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Color.lerp(
                          _border,
                          _gold.withOpacity(0.35),
                          pulseAnim.value,
                        )!,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _gold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _gold.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '⚡',
                                  style: TextStyle(fontSize: 10),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$goldType GOLD',
                                  style: const TextStyle(
                                    color: _gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _green.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: _green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _green,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: _green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [_gold, _goldBright],
                              ).createShader(b),
                              child: const Text(
                                '₹',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE8E0FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(b),
                            child: Text(
                              rate.ratePerGram.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            '/gram',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _green.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  color: _green,
                                  size: 11,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  '+0.00%',
                                  style: TextStyle(
                                    color: _green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _AnimatedReveal
// ────────────────────────────────────────────────────────────────────
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
          opacity: curve.clamp(0.01, 1.0),
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

// ────────────────────────────────────────────────────────────────────
// _GoldTypePicker
// ────────────────────────────────────────────────────────────────────
class _GoldTypePicker extends StatelessWidget {
  final String selected;
  final void Function(String?) onChanged;
  final List<GoldRate> rates;
  const _GoldTypePicker({
    required this.selected,
    required this.onChanged,
    required this.rates,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(title: 'Gold Type'),
          const SizedBox(height: 12),
          Row(
            children: ['24K', '22K', '18K'].map((type) {
              final isActive = selected == type;
              final rate = rates.firstWhere(
                    (r) => r.goldType == type,
                orElse: () => rates.first,
              );
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: type != '18K' ? 10 : 0),
                  child: _GoldTypeChip(
                    type: type,
                    ratePerGram: rate.ratePerGram,
                    isActive: isActive,
                    onTap: () => onChanged(type),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _GoldTypeChip
// ────────────────────────────────────────────────────────────────────
class _GoldTypeChip extends StatefulWidget {
  final String type;
  final double ratePerGram;
  final bool isActive;
  final VoidCallback onTap;
  const _GoldTypeChip({
    required this.type,
    required this.ratePerGram,
    required this.isActive,
    required this.onTap,
  });
  @override
  State<_GoldTypeChip> createState() => _GoldTypeChipState();
}

class _GoldTypeChipState extends State<_GoldTypeChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) =>
            Transform.scale(scale: 1.0 - _ctrl.value * 0.04, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.isActive
                ? const LinearGradient(
              colors: [_gold, _goldBright],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: widget.isActive ? null : _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isActive ? _gold : _border,
              width: widget.isActive ? 1.5 : 1,
            ),
            boxShadow: widget.isActive
                ? [BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 14)]
                : null,
          ),
          child: Column(
            children: [
              Text(
                widget.type,
                style: TextStyle(
                  color: widget.isActive
                      ? const Color(0xFF1A1200)
                      : _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${widget.ratePerGram.toStringAsFixed(0)}',
                style: TextStyle(
                  color: widget.isActive
                      ? const Color(0xFF1A1200).withOpacity(0.7)
                      : _textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _ChartCard
// ────────────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final bool isLoading;
  final List<GoldRateHistory> history;
  final String selectedPeriod;
  final void Function(String) onPeriodChanged;
  final Animation<double> pulseAnim;
  final Animation<double> shimmerAnim;
  const _ChartCard({
    required this.isLoading,
    required this.history,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.pulseAnim,
    required this.shimmerAnim,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Color.lerp(
              _border,
              _gold.withOpacity(0.2),
              pulseAnim.value,
            )!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Text(
                  'Price History',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                ...[('3months', '3M'), ('6months', '6M'), ('1year', '1Y')].map(
                      (p) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _PeriodChip(
                      label: p.$2,
                      isActive: selectedPeriod == p.$1,
                      onTap: () => onPeriodChanged(p.$1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
              child: isLoading
                  ? const Center(child: _ChartSkeleton())
                  : history.isEmpty
                  ? const Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: _textMuted),
                ),
              )
                  : _buildChart(history),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChart(List<GoldRateHistory> history) {
    final sorted = List<GoldRateHistory>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));
    final spots = List.generate(
      sorted.length,
          (i) => FlSpot(i.toDouble(), sorted[i].rate),
    );
    final minY = sorted.map((e) => e.rate).reduce(math.min) - 5;
    final maxY = sorted.map((e) => e.rate).reduce(math.max) + 5;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) => const SizedBox.shrink(),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                '₹${v.toInt()}',
                style: const TextStyle(color: _textMuted, fontSize: 9),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _gold,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_gold.withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _PeriodChip
// ────────────────────────────────────────────────────────────────────
class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _PeriodChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [_gold, _goldBright])
              : null,
          color: isActive ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _gold : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF1A1200) : _textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _ChartSkeleton
// ────────────────────────────────────────────────────────────────────
class _ChartSkeleton extends StatefulWidget {
  const _ChartSkeleton();
  @override
  State<_ChartSkeleton> createState() => _ChartSkeletonState();
}

class _ChartSkeletonState extends State<_ChartSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _anim.value * 4, 0),
            end: Alignment(-0.5 + _anim.value * 4, 0),
            colors: const [
              Color(0xFF141022),
              Color(0xFF1E1830),
              Color(0xFF141022),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _MiniStat
// ────────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _BuyButton
// ────────────────────────────────────────────────────────────────────
class _BuyButton extends StatefulWidget {
  final Animation<double> pulseAnim;
  final VoidCallback onTap;
  const _BuyButton({required this.pulseAnim, required this.onTap});
  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_ctrl, widget.pulseAnim]),
        builder: (context, child) => Transform.scale(
          scale: 1.0 - _ctrl.value * 0.02,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gold, _goldBright, _goldDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(
                    0.38 + widget.pulseAnim.value * 0.12,
                  ),
                  blurRadius: 20 + widget.pulseAnim.value * 8,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1200).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF1A1200),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Buy Gold Now',
              style: TextStyle(
                color: Color(0xFF1A1200),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _BuyGoldSheet
// ────────────────────────────────────────────────────────────────────
class _BuyGoldSheet extends StatefulWidget {
  final String selectedGoldType;
  final List<GoldRate> goldRates;
  final Function(String) onGoldTypeChanged;
  final VoidCallback? onPurchaseComplete;

  const _BuyGoldSheet({
    required this.selectedGoldType,
    required this.goldRates,
    required this.onGoldTypeChanged,
    this.onPurchaseComplete,
  });
  @override
  State<_BuyGoldSheet> createState() => _BuyGoldSheetState();
}

class _BuyGoldSheetState extends State<_BuyGoldSheet> {
  late String _selectedType;
  double _grams = 1.0;
  bool _loading = false;
  double _walletBalance = 0.0;
  Map<String, double> _userGoldByType = {};
  double _userGoldGrams = 0.0;
  double _userGoldValueInr = 0.0;
  final _gramsController = TextEditingController(text: '1.0');

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedGoldType;
    _loadWalletBalance();
    _loadUserGoldWallet();
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  GoldRate get _rate => widget.goldRates.firstWhere(
        (r) => r.goldType == _selectedType,
    orElse: () => widget.goldRates.first,
  );

  double get _total => _grams * _rate.ratePerGram;

  bool get _canAfford => _walletBalance >= _total;

  Future<void> _loadWalletBalance() async {
    try {
      final balance = await ApiService.getWalletBalance();
      if (mounted) setState(() => _walletBalance = balance);
    } catch (_) {}
  }

  Future<void> _loadUserGoldWallet() async {
    try {
      final userId = await SessionManager.getUserId();
      if (userId == null) return;

      final wallets = await ApiService.getUserGoldWallet(userId);
      final map = <String, double>{};
      for (final wallet in wallets) {
        map[wallet.goldType] = wallet.grams;
      }

      if (mounted) {
        setState(() {
          _userGoldByType = map;
          _updateSelectedTypeHoldings();
        });
      }
    } catch (_) {}
  }

  void _onBuySheetGoldTypeSelected(String type) {
    setState(() {
      _selectedType = type;
      _updateSelectedTypeHoldings();
    });
    widget.onGoldTypeChanged(type);
  }

  void _updateSelectedTypeHoldings() {
    _userGoldGrams = _userGoldByType[_selectedType] ?? 0.0;
    _userGoldValueInr = _userGoldGrams * _rate.ratePerGram;
  }

  Future<void> _purchaseGold() async {
    if (_grams <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (!_canAfford) {
      final missing = (_total - _walletBalance).clamp(0.0, double.infinity);
      _showError(
        'Insufficient wallet balance (₹${missing.toStringAsFixed(2)} short). Please top up via UPI.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Purchase',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are buying ${_grams.toStringAsFixed(2)}g of $_selectedType gold.',
              style: const TextStyle(color: _textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ₹${_total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: _gold,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xFF1A1200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final userId = await SessionManager.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final result = await ApiService.purchaseGold(
        userId: userId,
        goldType: _selectedType,
        grams: _grams,
        amount: _total,
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Purchase failed');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully purchased ${_grams.toStringAsFixed(2)}g of $_selectedType gold!',
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        widget.onPurchaseComplete?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    await _loadWalletBalance();
    await _loadUserGoldWallet();
  }

  Future<void> _navigateToUpiPayment() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpiPaymentScreen()),
    );
    await _loadWalletBalance();
    await _loadUserGoldWallet();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Sheet header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_gold, _goldBright]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.diamond_rounded,
                  color: Color(0xFF1A1200),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Buy Digital Gold',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Secure & Instant',
                    style: TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Wallet Balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: _gold,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${_walletBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _canAfford ? _green : _rose,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Selected-type gold held
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_selectedType Gold Held',
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_userGoldGrams.toStringAsFixed(3)} g',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${_userGoldValueInr.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _userGoldValueInr > 0 ? _green : _textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gold type selector
          Row(
            children: ['24K', '22K', '18K'].map((t) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _onBuySheetGoldTypeSelected(t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _selectedType == t
                            ? const LinearGradient(colors: [_gold, _goldBright])
                            : null,
                        color: _selectedType == t ? null : _cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedType == t ? _gold : _border,
                        ),
                      ),
                      child: Text(
                        t,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedType == t
                              ? const Color(0xFF1A1200)
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Rate display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _gold.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rate / Gram',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_rate.ratePerGram.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: _border),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Rate / Tola',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_rate.ratePerTola.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quantity input
          TextField(
            controller: _gramsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            onChanged: (v) =>
                setState(() => _grams = double.tryParse(v) ?? 0),
            decoration: InputDecoration(
              labelText: 'Quantity (grams)',
              labelStyle: const TextStyle(color: _textMuted),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick amount presets
          Row(
            children: [0.5, 1.0, 2.0, 5.0].map((g) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _grams = g;
                        _gramsController.text = g.toString();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                        _grams == g ? _gold.withOpacity(0.15) : _cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _grams == g
                              ? _gold.withOpacity(0.5)
                              : _border,
                        ),
                      ),
                      child: Text(
                        '${g}g',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _grams == g ? _gold : _textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Total amount
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buy via wallet button
          GestureDetector(
            onTap: _loading ? null : _purchaseGold,
            child: Opacity(
              opacity: (_grams > 0 && !_loading) ? 1.0 : 0.5,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: (_grams > 0 && !_loading)
                      ? const LinearGradient(
                    colors: [_gold, _goldBright, _goldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: (_grams > 0 && !_loading)
                      ? null
                      : _textMuted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: (_canAfford && _grams > 0)
                      ? [
                    BoxShadow(
                      color: _gold.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                      : [],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A1200),
                      strokeWidth: 2.5,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _canAfford
                            ? Icons.bolt_rounded
                            : Icons.warning_rounded,
                        color: _canAfford
                            ? const Color(0xFF1A1200)
                            : _rose,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _canAfford
                            ? 'BUY ${_grams.toStringAsFixed(2)}g $_selectedType GOLD'
                            : 'INSUFFICIENT WALLET BALANCE',
                        style: TextStyle(
                          color: _canAfford
                              ? const Color(0xFF1A1200)
                              : _rose,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // UPI top-up button
          GestureDetector(
            onTap: (_loading || _grams <= 0) ? null : _navigateToUpiPayment,
            child: Opacity(
              opacity: (_grams > 0 && !_loading) ? 1.0 : 0.5,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _cardBg,
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Text(
                    'TOP-UP VIA UPI',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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
}

// ────────────────────────────────────────────────────────────────────
// Shared painter / helper widgets
// ────────────────────────────────────────────────────────────────────

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
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

class _CardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_CardGridPainter _) => false;
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
  const _ParticlePainter({required this.particles, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = (p.y - t) % 1.0;
      final x = p.x + math.sin(t * math.pi * 2 + p.phase * 6) * 0.04;
      paint.color =
          (i % 3 != 0 ? _gold : _violetLight).withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _NoisePainter extends CustomPainter {
  final _rng = math.Random(44);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 1600; i++) {
      paint.color = Colors.white.withOpacity(_rng.nextDouble() * 0.5);
      canvas.drawCircle(
        Offset(
          _rng.nextDouble() * size.width,
          _rng.nextDouble() * size.height,
        ),
        _rng.nextDouble() * 0.65,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_NoisePainter _) => false;
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_gold, _goldBright],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: _textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

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
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _SellButton
// ────────────────────────────────────────────────────────────────────
class _SellButton extends StatefulWidget {
  final Animation<double> pulseAnim;
  final VoidCallback? onTap;
  final bool hasGold;

  const _SellButton({required this.pulseAnim, this.onTap, this.hasGold = false});

  @override
  State<_SellButton> createState() => _SellButtonState();
}

class _SellButtonState extends State<_SellButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.hasGold && widget.onTap != null;
    
    return GestureDetector(
      onTapDown: isEnabled ? (_) => _ctrl.forward() : null,
      onTapUp: isEnabled
          ? (_) {
              _ctrl.reverse();
              HapticFeedback.mediumImpact();
              widget.onTap!();
            }
          : null,
      onTapCancel: isEnabled ? () => _ctrl.reverse() : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ctrl, widget.pulseAnim]),
        builder: (context, child) => Transform.scale(
          scale: 1.0 - _ctrl.value * 0.02,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? const LinearGradient(
                      colors: [_rose, Color(0xFFFF6B8A), _rose],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isEnabled ? null : _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isEnabled ? _rose.withOpacity(0.5) : _border,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: _rose.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sell_rounded,
                color: isEnabled ? Colors.white : _textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.hasGold ? 'Sell Gold' : 'No Gold to Sell',
              style: TextStyle(
                color: isEnabled ? Colors.white : _textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// _SellGoldSheet
// ────────────────────────────────────────────────────────────────────
class _SellGoldSheet extends StatefulWidget {
  final String selectedGoldType;
  final List<GoldRate> goldRates;
  final double userGoldGrams;
  final Function(String) onGoldTypeChanged;
  final VoidCallback? onSellComplete;

  const _SellGoldSheet({
    required this.selectedGoldType,
    required this.goldRates,
    required this.userGoldGrams,
    required this.onGoldTypeChanged,
    this.onSellComplete,
  });

  @override
  State<_SellGoldSheet> createState() => _SellGoldSheetState();
}

class _SellGoldSheetState extends State<_SellGoldSheet> {
  late String _selectedType;
  double _grams = 1.0;
  bool _loading = false;
  final _gramsController = TextEditingController(text: '1.0');

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedGoldType;
    _grams = widget.userGoldGrams > 0 ? widget.userGoldGrams : 1.0;
    _gramsController.text = _grams.toString();
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  GoldRate get _rate => widget.goldRates.firstWhere(
        (r) => r.goldType == _selectedType,
    orElse: () => widget.goldRates.first,
  );

  double get _total => _grams * _rate.ratePerGram;

  bool get _canSell => _grams > 0 && _grams <= widget.userGoldGrams;

  void _onGoldTypeSelected(String type) {
    setState(() {
      _selectedType = type;
    });
    widget.onGoldTypeChanged(type);
  }

  Future<void> _submitSellRequest() async {
    if (!_canSell) {
      _showError('Please enter a valid amount within your gold balance');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Sell Request',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are selling ${_grams.toStringAsFixed(2)}g of $_selectedType gold.',
              style: const TextStyle(color: _textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              'You will receive: ₹${_total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: _rose,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This request requires admin approval. Your gold will be deducted and funds will be added to your wallet after approval.',
              style: TextStyle(color: _textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Submit Request',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final userId = await SessionManager.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final result = await ApiService.submitGoldSellRequest(
        userId: userId,
        goldType: _selectedType,
        grams: _grams,
        ratePerGram: _rate.ratePerGram,
        totalAmount: _total,
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Sell request failed');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Sell request submitted! Pending admin approval.',
            ),
            backgroundColor: _violet,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        widget.onSellComplete?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_rose, Color(0xFFFF6B8A)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sell_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sell Digital Gold',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Instant Credit to Wallet',
                    style: TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available $_selectedType Gold',
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.userGoldGrams.toStringAsFixed(3)} g',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Current Value',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${(widget.userGoldGrams * _rate.ratePerGram).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: _green,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: ['24K', '22K', '18K'].map((t) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _onGoldTypeSelected(t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _selectedType == t
                            ? const LinearGradient(colors: [_rose, Color(0xFFFF6B8A)])
                            : null,
                        color: _selectedType == t ? null : _cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedType == t ? _rose : _border,
                        ),
                      ),
                      child: Text(
                        t,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedType == t
                              ? Colors.white
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _rose.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rate / Gram',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_rate.ratePerGram.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: _border),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Rate / Tola',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_rate.ratePerTola.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _gramsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => _grams = double.tryParse(v) ?? 0),
            decoration: InputDecoration(
              labelText: 'Quantity to sell (grams)',
              labelStyle: const TextStyle(color: _textMuted),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [0.5, 1.0, 5.0, 10.0].map((g) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _grams = g > widget.userGoldGrams ? widget.userGoldGrams : g;
                        _gramsController.text = _grams.toString();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _grams == g ? _rose.withOpacity(0.15) : _cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _grams == g
                              ? _rose.withOpacity(0.5)
                              : _border,
                        ),
                      ),
                      child: Text(
                        '${g}g',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _grams == g ? _rose : _textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _rose.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _rose.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text(
                  'You Will Receive',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _rose,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: _loading || !_canSell ? null : _submitSellRequest,
            child: Opacity(
              opacity: (_canSell && !_loading) ? 1.0 : 0.5,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: _canSell && !_loading
                      ? const LinearGradient(
                          colors: [_rose, Color(0xFFFF6B8A), _rose],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _canSell && !_loading ? null : _textMuted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _canSell
                      ? [
                          BoxShadow(
                            color: _rose.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sell_rounded,
                              color: _canSell ? Colors.white : _textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _canSell
                                  ? 'SUBMIT SELL REQUEST'
                                  : 'ENTER VALID AMOUNT',
                              style: TextStyle(
                                color: _canSell ? Colors.white : _textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}