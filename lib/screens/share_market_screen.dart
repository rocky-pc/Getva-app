import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'notifications_screen.dart';
import '../services/api_service.dart';
import '../models/share_market.dart';
import '../services/session_manager.dart';

// ── Enhanced Design Tokens ─────────────────────────────────────
const _gold        = Color(0xFFD4A847);
const _goldBright  = Color(0xFFFFE066);
const _surface     = Color(0xFF0A0910);
const _cardBg      = Color(0xFF110F1E);
const _cardBg2     = Color(0xFF16132A);
const _violet      = Color(0xFF6366F1);
const _violetLight = Color(0xFF8B6FE8);
const _violetDark  = Color(0xFF4F46E5);
const _green       = Color(0xFF22C55E);
const _greenLight  = Color(0xFF4ADE80);
const _red         = Color(0xFFEF4444);
const _redLight    = Color(0xFFF87171);
const _cyan        = Color(0xFF00E5FF);
const _textPrimary = Colors.white;
const _textMuted   = Color(0xFF6B6880);
const _border      = Color(0xFF1E1B32);

class ShareMarketScreen extends StatefulWidget {
  const ShareMarketScreen({super.key});

  @override
  State<ShareMarketScreen> createState() => _ShareMarketScreenState();
}

class _ShareMarketScreenState extends State<ShareMarketScreen>
    with TickerProviderStateMixin {

  String _selectedPeriod = '1D';
  bool _isLoading = true;
  int _selectedStockIndex = 0;
  bool _showVolumeChart = false;
  int _selectedTabIndex = 0;
  double _walletBalance = 0.0;

  List<Share> _shares = [];
  List<UserShareHolding> _userHoldings = [];
  Map<String, List<FlSpot>> _priceData = {};
  Map<String, List<FlSpot>> _volumeData = {};

  String _formatVolume(int volume) {
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(1)}Cr';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }

  // FIX: Safe getter — never force-unwrap
  Share? get _selectedStock =>
      _shares.isNotEmpty && _selectedStockIndex < _shares.length
          ? _shares[_selectedStockIndex]
          : null;

  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _chartAnimationCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _indicatorCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _entryAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _chartAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _indicatorAnim;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final shares = await ApiService.getShares();
      final userId = await SessionManager.getUserId();
      if (userId != null) {
        final holdings = await ApiService.getUserShareHoldings(userId);
        final balance = await ApiService.getUserWalletBalance(userId);
        if (mounted) {
          setState(() {
            _userHoldings = holdings;
            _walletBalance = balance;
          });
        }
      }

      if (mounted) {
        setState(() {
          _shares = shares.isNotEmpty ? shares : _getMockShares();
          // FIX: Reset index safely whenever shares list changes
          _selectedStockIndex = 0;
          _isLoading = false;
        });
        await _initChartData();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _entryCtrl.forward();
            _chartAnimationCtrl.forward();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shares = _getMockShares();
          _selectedStockIndex = 0;
          _isLoading = false;
        });
        await _initChartData();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _entryCtrl.forward();
            _chartAnimationCtrl.forward();
          }
        });
      }
    }
  }

  List<Share> _getMockShares() {
    return [
      Share(
        id: 1,
        companyId: 1,
        companySymbol: 'RELIANCE',
        companyName: 'Reliance Industries Ltd',
        sector: 'Conglomerate',
        currentPrice: 2450.50,
        previousClose: 2435.25,
        dayHigh: 2468.00,
        dayLow: 2420.00,
        volume: 2500000,
        peRatio: 28.5,
        marketCap: '18.5T',
        change: 15.25,
        changePercent: 0.62,
        isActive: true,
        lastUpdated: DateTime.now(),
      ),
      Share(
        id: 2,
        companyId: 2,
        companySymbol: 'TCS',
        companyName: 'Tata Consultancy Services',
        sector: 'IT',
        currentPrice: 3850.75,
        previousClose: 3810.00,
        dayHigh: 3875.00,
        dayLow: 3795.00,
        volume: 1200000,
        peRatio: 32.1,
        marketCap: '14.2T',
        change: 40.75,
        changePercent: 1.07,
        isActive: true,
        lastUpdated: DateTime.now(),
      ),
      Share(
        id: 3,
        companyId: 3,
        companySymbol: 'INFY',
        companyName: 'Infosys Ltd',
        sector: 'IT',
        currentPrice: 1680.25,
        previousClose: 1695.00,
        dayHigh: 1700.00,
        dayLow: 1665.00,
        volume: 890000,
        peRatio: 25.8,
        marketCap: '7.1T',
        change: -14.75,
        changePercent: -0.87,
        isActive: true,
        lastUpdated: DateTime.now(),
      ),
      Share(
        id: 4,
        companyId: 4,
        companySymbol: 'HDFCBANK',
        companyName: 'HDFC Bank Ltd',
        sector: 'Banking',
        currentPrice: 1680.00,
        previousClose: 1675.50,
        dayHigh: 1690.00,
        dayLow: 1665.00,
        volume: 1500000,
        peRatio: 22.4,
        marketCap: '12.8T',
        change: 4.50,
        changePercent: 0.27,
        isActive: true,
        lastUpdated: DateTime.now(),
      ),
      Share(
        id: 5,
        companyId: 5,
        companySymbol: 'ICICIBANK',
        companyName: 'ICICI Bank Ltd',
        sector: 'Banking',
        currentPrice: 985.50,
        previousClose: 990.00,
        dayHigh: 995.00,
        dayLow: 975.00,
        volume: 2100000,
        peRatio: 18.6,
        marketCap: '7.5T',
        change: -4.50,
        changePercent: -0.45,
        isActive: true,
        lastUpdated: DateTime.now(),
      ),
    ];
  }

  Future<void> _initChartData() async {
    // FIX: Guard against null selected stock
    final stock = _selectedStock;
    if (stock == null) return;

    try {
      final historyData = await ApiService.getSharePriceHistory(
        symbol: stock.companySymbol,
        period: _selectedPeriod,
      );
      if (historyData.isNotEmpty && mounted) {
        setState(() {
          _priceData[_selectedPeriod] = historyData.map((point) =>
              FlSpot(
                (point['x'] as num?)?.toDouble() ?? 0,
                (point['y'] as num?)?.toDouble() ?? 0,
              )
          ).toList();
        });
      } else {
        _generateMockChartData();
      }
    } catch (e) {
      _generateMockChartData();
    }

    _generateVolumeData();
  }

  void _generateMockChartData() {
    final stock = _selectedStock;
    if (stock == null) return;

    final random = math.Random(42);
    final basePrice = stock.currentPrice;
    final periods = {
      '1D': 24,
      '1W': 7,
      '1M': 30,
      '1Y': 52,
      'ALL': 120,
    };

    final ranges = {
      '1D': {'variance': 1.2, 'min': -8.0, 'max': 8.0},
      '1W': {'variance': 2.5, 'min': -15.0, 'max': 15.0},
      '1M': {'variance': 3.0, 'min': -25.0, 'max': 20.0},
      '1Y': {'variance': 4.0, 'min': -45.0, 'max': 35.0},
      'ALL': {'variance': 3.5, 'min': -70.0, 'max': 60.0},
    };

    periods.forEach((period, points) {
      final range = ranges[period]!;
      List<FlSpot> data = [];
      double price = basePrice + range['min']!;

      for (int i = 0; i < points; i++) {
        double change = (random.nextDouble() - 0.5) * range['variance']!;
        price = (price + change).clamp(
          basePrice + range['min']!,
          basePrice + range['max']!,
        );
        data.add(FlSpot(i.toDouble(), price));
      }
      _priceData[period] = data;
    });
  }

  void _generateVolumeData() {
    final random = math.Random(77);
    for (var period in ['1D', '1W', '1M', '1Y', 'ALL']) {
      final periodData = _priceData[period];
      if (periodData != null) {
        List<FlSpot> volumes = [];
        for (int i = 0; i < periodData.length; i++) {
          volumes.add(FlSpot(i.toDouble(), random.nextDouble() * 15 + 5));
        }
        _volumeData[period] = volumes;
      }
    }
  }

  void _initAnimations() {
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _shimmerAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))..repeat();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);

    _chartAnimationCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _chartAnim = CurvedAnimation(parent: _chartAnimationCtrl, curve: Curves.easeOutCubic);

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _indicatorCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _indicatorAnim = CurvedAnimation(parent: _indicatorCtrl, curve: Curves.easeInOut);

    final rng = math.Random(77);
    for (int i = 0; i < 35; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(), y: rng.nextDouble(),
        radius: rng.nextDouble() * 2.0 + 0.5,
        speed: rng.nextDouble() * 0.3 + 0.1,
        opacity: rng.nextDouble() * 0.4 + 0.05,
        phase: rng.nextDouble(),
      ));
    }
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
    _indicatorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, child) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF080714),
                        Color(0xFF0A0910),
                        Color(0xFF060512),
                        Color(0xFF0B0820),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Animated orbs
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _orbAnim,
              builder: (context, child) => Stack(
                children: [
                  Positioned(
                    top: -100 + _orbAnim.value * 60,
                    left: size.width / 2 - 250,
                    child: _EnhancedOrbGlow(
                      color: _violet.withOpacity(0.15 + _pulseAnim.value * 0.05),
                      size: 420,
                      blurSigma: 70,
                    ),
                  ),
                  Positioned(
                    bottom: 80 + _orbAnim.value * -40,
                    right: -120,
                    child: _EnhancedOrbGlow(
                      color: _gold.withOpacity(0.1),
                      size: 340,
                      blurSigma: 60,
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.5,
                    left: -60,
                    child: _EnhancedOrbGlow(
                      color: _cyan.withOpacity(0.06),
                      size: 260,
                      blurSigma: 50,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Particle system
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
              filter: ImageFilter.blur(sigmaX: 0.3, sigmaY: 0.3),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? _buildLoadingView()
                : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildEnhancedAppBar(),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (_selectedTabIndex == 0) ...[
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.0,
                      child: _buildEnhancedHeroCard(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.1,
                      child: _buildStockSelector(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.15,
                      child: _buildEnhancedPeriodSelector(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.2,
                      child: _buildEnhancedChartSection(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.25,
                      child: _buildChartTypeToggle(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.3,
                      child: _buildTradeButtons(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  // FIX: Guard stats grid — only show when stock is available
                  if (_selectedStock != null)
                    SliverToBoxAdapter(
                      child: _AnimatedReveal(
                        animation: _entryAnim,
                        delay: 0.35,
                        child: _buildEnhancedStatsGrid(),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.4,
                      child: _buildEnhancedTrendingSection(),
                    ),
                  ),
                ] else ...[
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.0,
                      child: _buildPortfolioOverview(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.1,
                      child: _buildHoldingsList(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.2,
                      child: _buildTransactionHistory(),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
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
                      colors: [_violet, _violetDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _violet.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.trending_up, color: Colors.white, size: 32),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Market Data...',
            style: TextStyle(color: _textMuted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation(_violet),
              strokeWidth: 3,
              backgroundColor: _violet.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                _EnhancedGlassButton(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Share Market',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                _EnhancedGlassButton(
                  onTap: _loadData,
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                _EnhancedGlassButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationsScreen()),
                    );
                  },
                  child: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _cardBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: _selectedTabIndex == 0
                              ? const LinearGradient(
                              colors: [_violet, _violetDark])
                              : null,
                          color: _selectedTabIndex == 0
                              ? null
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Market',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTabIndex == 0
                                ? Colors.white
                                : _textMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: _selectedTabIndex == 1
                              ? const LinearGradient(
                              colors: [_violet, _violetDark])
                              : null,
                          color: _selectedTabIndex == 1
                              ? null
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Portfolio',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTabIndex == 1
                                ? Colors.white
                                : _textMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: _textMuted, fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildStockSelector() {
    if (_shares.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _shares.length,
          itemBuilder: (context, index) {
            final share = _shares[index];
            final isSelected = _selectedStockIndex == index;
            final isUp = share.change >= 0;

            return GestureDetector(
              onTap: () async {
                setState(() => _selectedStockIndex = index);
                _priceData.clear();
                _volumeData.clear();
                await _initChartData();
                if (mounted) {
                  _chartAnimationCtrl.reset();
                  _chartAnimationCtrl.forward();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [_violet, _violetDark])
                      : null,
                  color: isSelected ? null : _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? _violetLight : _border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      share.companySymbol,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          isUp ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isUp ? _green : _red,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${share.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: isUp ? _green : _red,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildEnhancedPeriodSelector() {
    final periods = ['1D', '1W', '1M', '1Y', 'ALL'];
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
          children: periods
              .map((p) => Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = p);
                _chartAnimationCtrl.reset();
                _chartAnimationCtrl.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _selectedPeriod == p
                      ? const LinearGradient(
                      colors: [_violet, _violetDark])
                      : null,
                  color: _selectedPeriod == p
                      ? null
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedPeriod == p
                        ? Colors.white
                        : _textMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildChartTypeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildToggleButton('Price', !_showVolumeChart, () {
            setState(() => _showVolumeChart = false);
          }),
          const SizedBox(width: 8),
          _buildToggleButton('Volume', _showVolumeChart, () {
            setState(() => _showVolumeChart = true);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _violet : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _violetLight : _border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : _textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedChartSection() {
    // FIX: Use local variable and guard early
    final stock = _selectedStock;
    if (stock == null) return const SizedBox.shrink();

    final spots = _showVolumeChart
        ? (_volumeData[_selectedPeriod] ?? _priceData[_selectedPeriod] ?? [])
        : (_priceData[_selectedPeriod] ?? _priceData['1D'] ?? []);

    if (spots.isEmpty) return const SizedBox.shrink();

    final isUp = stock.change >= 0;
    final chartColor = isUp ? _greenLight : _redLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _chartAnim,
        builder: (context, child) {
          return Container(
            height: 280,
            padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_cardBg2, _cardBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _violet.withOpacity(0.1),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: chartColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _showVolumeChart ? 'Volume Chart' : 'Price Chart',
                        style: TextStyle(
                          color: chartColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildChartLegend(isUp),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _showVolumeChart ? 5 : 20,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: _textMuted.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              final interval = _getInterval();
                              if (index % interval == 0 &&
                                  index < spots.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _getXLabel(index),
                                    style: const TextStyle(
                                        color: _textMuted, fontSize: 10),
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
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (_showVolumeChart) {
                                return Text(
                                  '${(value / 1000).toStringAsFixed(0)}K',
                                  style: const TextStyle(
                                      color: _textMuted, fontSize: 10),
                                );
                              }
                              return Text(
                                '₹${value.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: _textMuted, fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots
                              .map((spot) =>
                              FlSpot(spot.x, spot.y * _chartAnim.value))
                              .toList(),
                          isCurved: true,
                          color: chartColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: !_showVolumeChart,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                chartColor.withOpacity(0.3),
                                chartColor.withOpacity(0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 12,
                          tooltipBorder: BorderSide(
                              color: chartColor.withOpacity(0.5), width: 1),
                          getTooltipItems:
                              (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              if (_showVolumeChart) {
                                return LineTooltipItem(
                                  'Volume: ${(spot.y / 1000).toStringAsFixed(0)}K',
                                  TextStyle(
                                      color: chartColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                );
                              }
                              return LineTooltipItem(
                                '₹${spot.y.toStringAsFixed(2)}',
                                TextStyle(
                                    color: chartColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _getInterval() {
    switch (_selectedPeriod) {
      case '1D': return 4;
      case '1W': return 1;
      case '1M': return 5;
      case '1Y': return 10;
      default:   return 15;
    }
  }

  String _getXLabel(int index) {
    switch (_selectedPeriod) {
      case '1D':
        return '${index}:00';
      case '1W':
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[index % 7];
      case '1M':
        return 'Day ${index + 1}';
      case '1Y':
        const months = [
          'Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'
        ];
        return months[index % 12];
      default:
        return '';
    }
  }

  Widget _buildChartLegend(bool isUp) {
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
            decoration: BoxDecoration(
              color: isUp ? _green : _red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isUp ? 'Bullish Trend' : 'Bearish Trend',
            style: const TextStyle(color: _textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsGrid() {
    // FIX: Use local variable — caller already guards with if (_selectedStock != null)
    final stock = _selectedStock;
    if (stock == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEY STATISTICS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _violet,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildEnhancedStatItem(
                  'Open',
                  '₹${(stock.currentPrice - 2.5).toStringAsFixed(2)}'),
              _buildEnhancedStatItem(
                  'Prev. Close',
                  '₹${stock.previousClose.toStringAsFixed(2)}'),
              _buildEnhancedStatItem(
                  'Day High',
                  '₹${stock.dayHigh.toStringAsFixed(2)}',
                  Icons.arrow_upward,
                  _green),
              _buildEnhancedStatItem(
                  'Day Low',
                  '₹${stock.dayLow.toStringAsFixed(2)}',
                  Icons.arrow_downward,
                  _red),
              _buildEnhancedStatItem(
                  'Volume',
                  _formatVolume(stock.volume),
                  Icons.trending_up,
                  _cyan),
              _buildEnhancedStatItem(
                  'P/E Ratio',
                  stock.peRatio.toStringAsFixed(2),
                  Icons.pie_chart,
                  _violet),
              _buildEnhancedStatItem(
                  'Market Cap',
                  stock.marketCap,
                  Icons.account_balance,
                  _gold),
              _buildEnhancedStatItem(
                  '52W Range',
                  '₹120 - ₹175',
                  Icons.show_chart,
                  _violetLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatItem(String label, String value,
      [IconData? icon, Color? iconColor]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_cardBg, _cardBg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 14),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeroCard() {
    // FIX: Use local variable and guard
    final stock = _selectedStock;
    if (stock == null) return const SizedBox.shrink();

    final isUp = stock.change >= 0;
    final color = isUp ? _green : _red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_cardBg2, _cardBg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _violet.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.05)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isUp ? Icons.trending_up : Icons.trending_down,
                      color: color,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.companySymbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stock.companyName,
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${stock.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isUp ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
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
    );
  }

  Widget _buildTradeButtons() {
    final stock = _selectedStock;
    if (stock == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showTradeDialog(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green, _green.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'BUY',
                  textAlign: TextAlign.center,
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
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => _showTradeDialog(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_red, _red.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'SELL',
                  textAlign: TextAlign.center,
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
        ],
      ),
    );
  }

  void _showTradeDialog(bool isBuy) async {
    final stock = _selectedStock;
    if (stock == null) return;

    final userId = await SessionManager.getUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to trade')),
        );
      }
      return;
    }

    int availableQty = 0;
    if (!isBuy) {
      try {
        final holding = _userHoldings.firstWhere(
          (h) => h.companySymbol == stock.companySymbol,
        );
        availableQty = holding.quantity;
      } catch (e) {
        availableQty = 0;
      }
    }

    final TextEditingController quantityController = TextEditingController();
    double totalAmount = 0;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${isBuy ? 'Buy' : 'Sell'} ${stock.companySymbol}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isBuy) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wallet Balance', style: TextStyle(color: _textMuted)),
                    Text(
                      '₹${_walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(color: _gold, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Shares', style: TextStyle(color: _textMuted)),
                    Text(
                      '$availableQty Shares',
                      style: const TextStyle(color: _violet, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Price per share', style: TextStyle(color: _textMuted)),
                  Text(
                    '₹${stock.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (value) {
                  final qty = int.tryParse(value) ?? 0;
                  setModalState(() {
                    totalAmount = qty * stock.currentPrice;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: const TextStyle(color: _textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _violet),
                  ),
                  suffixText: 'Shares',
                  suffixStyle: const TextStyle(color: _textMuted),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: _border),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Value', style: TextStyle(color: _textMuted, fontSize: 16)),
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final qty = int.tryParse(quantityController.text) ?? 0;
                    if (qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter valid quantity')),
                      );
                      return;
                    }

                    if (isBuy && totalAmount > _walletBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient wallet balance')),
                      );
                      return;
                    }

                    if (!isBuy && qty > availableQty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient shares available to sell')),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    setState(() => _isLoading = true);

                    try {
                      final result = isBuy
                          ? await ApiService.buyShares(
                              userId: userId,
                              shareId: stock.id,
                              companySymbol: stock.companySymbol,
                              quantity: qty,
                              pricePerShare: stock.currentPrice,
                            )
                          : await ApiService.sellShares(
                              userId: userId,
                              shareId: stock.id,
                              companySymbol: stock.companySymbol,
                              quantity: qty,
                              pricePerShare: stock.currentPrice,
                            );

                      if (result['success'] == true) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Trade successful'),
                              backgroundColor: _green,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Trade failed'),
                              backgroundColor: _red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: _red),
                        );
                      }
                    } finally {
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBuy ? _green : _red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isBuy ? 'CONFIRM BUY' : 'CONFIRM SELL',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioOverview() {
    final totalValue = _userHoldings.fold<double>(
        0, (sum, h) => sum + h.totalValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_cardBg2, _cardBg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PORTFOLIO VALUE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _textMuted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${totalValue.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMiniStat(
                    'Holdings', '${_userHoldings.length}', _violet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingsList() {
    if (_userHoldings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: _textMuted, size: 48),
                SizedBox(height: 12),
                Text(
                  'No holdings yet',
                  style: TextStyle(color: _textMuted, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR HOLDINGS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _violet,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ..._userHoldings.map((holding) {
            final isUp = holding.profitLoss >= 0;
            final color = isUp ? _green : _red;
            final changePercent = holding.averagePrice > 0
                ? ((holding.currentPrice - holding.averagePrice) /
                holding.averagePrice) *
                100
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_cardBg, _cardBg2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          holding.companySymbol,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${holding.quantity} shares',
                          style: const TextStyle(
                              color: _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${holding.totalValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${isUp ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.history, color: _textMuted, size: 40),
              SizedBox(height: 12),
              Text(
                'No recent transactions',
                style: TextStyle(color: _textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTrendingSection() {
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
                  gradient: const LinearGradient(
                      colors: [_violet, _violetDark]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'TRENDING STOCKS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _violet,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _violet.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: _violet,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_shares.length, (index) {
            final share = _shares[index];
            final isUp = share.change >= 0;
            final color = isUp ? _green : _red;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index * 50)),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_cardBg, _cardBg2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.05)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                isUp
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: color,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  share.companySymbol,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  share.companyName,
                                  style: const TextStyle(
                                    color: _textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${share.currentPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isUp
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      color: color,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${isUp ? '+' : ''}${share.changePercent.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
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
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _EnhancedGlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _EnhancedGlassButton(
      {required this.onTap, required this.child});

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
          border:
          Border.all(color: Colors.white.withOpacity(0.12)),
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
        filter:
        ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
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
      final x = p.x +
          math.sin(t * math.pi * 2 + p.phase * 6) * 0.04;

      final gradientColor =
      (i % 3 != 0 ? _violetLight : _gold);
      paint.color = gradientColor.withOpacity(p.opacity *
          (0.5 + math.sin(progress * math.pi * 2) * 0.3));

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EnhancedParticlePainter old) =>
      old.progress != progress;
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
        final t =
        ((animation.value - delay) / (1.0 - delay))
            .clamp(0.0, 1.0);
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