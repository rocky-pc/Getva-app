import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'notifications_screen.dart';

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

  // Enhanced stock data with more details
  final List<Map<String, dynamic>> _stocks = [
    {
      'symbol': 'TATASTEEL',
      'name': 'Tata Steel Ltd.',
      'price': 158.45,
      'change': 2.35,
      'changePercent': 1.50,
      'high': 160.20,
      'low': 155.80,
      'volume': '12.4M',
      'volumeNum': 12400000,
      'pe': 12.5,
      'marketCap': '195.2B',
      'sector': 'Metals',
    },
    {
      'symbol': 'RELIANCE',
      'name': 'Reliance Industries',
      'price': 2950.20,
      'change': 15.40,
      'changePercent': 0.52,
      'high': 2975.00,
      'low': 2930.50,
      'volume': '8.2M',
      'volumeNum': 8200000,
      'pe': 24.8,
      'marketCap': '1950.5B',
      'sector': 'Energy',
    },
    {
      'symbol': 'HDFCBANK',
      'name': 'HDFC Bank Ltd.',
      'price': 1445.60,
      'change': -5.20,
      'changePercent': -0.36,
      'high': 1452.30,
      'low': 1440.20,
      'volume': '15.6M',
      'volumeNum': 15600000,
      'pe': 18.2,
      'marketCap': '810.3B',
      'sector': 'Banking',
    },
    {
      'symbol': 'INFY',
      'name': 'Infosys Ltd.',
      'price': 1620.00,
      'change': 12.80,
      'changePercent': 0.80,
      'high': 1632.50,
      'low': 1608.30,
      'volume': '9.8M',
      'volumeNum': 9800000,
      'pe': 22.4,
      'marketCap': '670.8B',
      'sector': 'IT',
    },
    {
      'symbol': 'TCS',
      'name': 'Tata Consultancy',
      'price': 3890.45,
      'change': -20.10,
      'changePercent': -0.51,
      'high': 3920.00,
      'low': 3880.50,
      'volume': '5.2M',
      'volumeNum': 5200000,
      'pe': 28.6,
      'marketCap': '1425.3B',
      'sector': 'IT',
    },
  ];

  Map<String, dynamic> get _selectedStock => _stocks[_selectedStockIndex];

  // Enhanced chart data for different periods
  Map<String, List<FlSpot>> _priceData = {};
  Map<String, List<FlSpot>> _volumeData = {};

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
    _initChartData();
    _initAnimations();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _entryCtrl.forward();
        _chartAnimationCtrl.forward();
      }
    });
  }

  void _initChartData() {
    // Generate realistic chart data for each period
    final random = math.Random(42);
    final basePrice = _selectedStock['price'];

    // 1D data (24 points - hourly)
    List<FlSpot> dayData = [];
    double price = basePrice - 5;
    for (int i = 0; i < 24; i++) {
      double change = (random.nextDouble() - 0.5) * 1.2;
      price = (price + change).clamp(basePrice - 8.0, basePrice + 8.0).toDouble();
      dayData.add(FlSpot(i.toDouble(), price));
    }
    _priceData['1D'] = dayData;

    // 1W data (7 points - daily)
    List<FlSpot> weekData = [];
    price = basePrice - 8;
    for (int i = 0; i < 7; i++) {
      double change = (random.nextDouble() - 0.5) * 2.5;
      price = (price + change).clamp(basePrice - 15.0, basePrice + 15.0).toDouble();
      weekData.add(FlSpot(i.toDouble(), price));
    }
    _priceData['1W'] = weekData;

    // 1M data (30 points)
    List<FlSpot> monthData = [];
    price = basePrice - 12;
    for (int i = 0; i < 30; i++) {
      double change = (random.nextDouble() - 0.5) * 3;
      price = (price + change).clamp(basePrice - 25.0, basePrice + 20.0).toDouble();
      monthData.add(FlSpot(i.toDouble(), price));
    }
    _priceData['1M'] = monthData;

    // 1Y data (52 points - weekly)
    List<FlSpot> yearData = [];
    price = basePrice - 30;
    for (int i = 0; i < 52; i++) {
      double change = (random.nextDouble() - 0.5) * 4;
      price = (price + change).clamp(basePrice - 45.0, basePrice + 35.0).toDouble();
      yearData.add(FlSpot(i.toDouble(), price));
    }
    _priceData['1Y'] = yearData;

    // ALL data (120 points)
    List<FlSpot> allData = [];
    price = basePrice - 50;
    for (int i = 0; i < 120; i++) {
      double change = (random.nextDouble() - 0.5) * 3.5;
      price = (price + change).clamp(basePrice - 70.0, basePrice + 60.0).toDouble();
      allData.add(FlSpot(i.toDouble(), price));
    }
    _priceData['ALL'] = allData;

    // Volume data
    for (var period in ['1D', '1W', '1M', '1Y', 'ALL']) {
      List<FlSpot> volumes = [];
      for (int i = 0; i < _priceData[period]!.length; i++) {
        volumes.add(FlSpot(i.toDouble(), random.nextDouble() * 15 + 5));
      }
      _volumeData[period] = volumes;
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
    _pulseCtrl.dispose(); _orbCtrl.dispose();
    _particleCtrl.dispose(); _entryCtrl.dispose();
    _shimmerCtrl.dispose(); _chartAnimationCtrl.dispose();
    _glowCtrl.dispose(); _indicatorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Enhanced animated background
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

          // Enhanced particle system
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
                SliverToBoxAdapter(
                    child: _AnimatedReveal(animation: _entryAnim, delay: 0.0, child: _buildEnhancedHeroCard())
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                    child: _AnimatedReveal(animation: _entryAnim, delay: 0.1, child: _buildStockSelector())
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                    child: _AnimatedReveal(animation: _entryAnim, delay: 0.15, child: _buildEnhancedPeriodSelector())
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                    child: _AnimatedReveal(animation: _entryAnim, delay: 0.2, child: _buildEnhancedChartSection())
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                    child: _AnimatedReveal(animation: _entryAnim, delay: 0.25, child: _buildChartTypeToggle())
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                    child: _AnimatedReveal(animation: _entryAnim, delay: 0.3, child: _buildEnhancedStatsGrid())
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                    child: _AnimatedReveal(animation: _entryAnim, delay: 0.4, child: _buildEnhancedTrendingSection())
                ),
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
        child: Row(
          children: [
            _EnhancedGlassButton(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                        _selectedStock['symbol'],
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _violet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedStock['sector'],
                        style: const TextStyle(color: _violetLight, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Text(
                    _selectedStock['name'],
                    style: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500)
                ),
              ],
            ),
            const Spacer(),
            _EnhancedGlassButton(
                onTap: () {},
                child: const Icon(Icons.search_rounded, color: Colors.white, size: 20)
            ),
            const SizedBox(width: 8),
            _EnhancedGlassButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeroCard() {
    final stock = _selectedStock;
    final price = stock['price'] as double;
    final change = stock['change'] as double;
    final changePercent = stock['changePercent'] as double;
    final isUp = change >= 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _cardBg,
              _cardBg2.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: (isUp ? _green : _red).withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Price',
                      style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${price.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isUp ? _green : _red).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isUp ? _green : _red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isUp ? '+' : ''}${change.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: isUp ? _green : _red,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMiniStat('High', '₹${(stock['high'] as double).toStringAsFixed(2)}', _green),
                const SizedBox(width: 24),
                _buildMiniStat('Low', '₹${(stock['low'] as double).toStringAsFixed(2)}', _red),
                const SizedBox(width: 24),
                _buildMiniStat('Volume', stock['volume'] as String, _violet),
              ],
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
          style: const TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildStockSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _stocks.length,
          itemBuilder: (context, index) {
            final stock = _stocks[index];
            final isSelected = _selectedStockIndex == index;
            final isUp = stock['change'] >= 0;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStockIndex = index;
                  _initChartData();
                });
                _chartAnimationCtrl.reset();
                _chartAnimationCtrl.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      stock['symbol'],
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
                          '${stock['changePercent'].toStringAsFixed(2)}%',
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
          children: periods.map((p) => Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = p);
                _chartAnimationCtrl.reset();
                _chartAnimationCtrl.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _selectedPeriod == p
                      ? const LinearGradient(colors: [_violet, _violetDark])
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

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
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
    final spots = _showVolumeChart
        ? (_volumeData[_selectedPeriod] ?? _priceData[_selectedPeriod]!)
        : (_priceData[_selectedPeriod] ?? _priceData['1D']!);

    final isUp = _selectedStock['change'] >= 0;
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
              gradient: LinearGradient(
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                              int interval = _getInterval();
                              if (index % interval == 0 && index < spots.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _getXLabel(index),
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
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (_showVolumeChart) {
                                return Text(
                                  '${(value / 1000).toStringAsFixed(0)}K',
                                  style: const TextStyle(
                                    color: _textMuted,
                                    fontSize: 10,
                                  ),
                                );
                              }
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
                          spots: spots.map((spot) => FlSpot(spot.x, spot.y * _chartAnim.value)).toList(),
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
                          tooltipBorder: BorderSide(color: chartColor.withOpacity(0.5), width: 1),
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              if (_showVolumeChart) {
                                return LineTooltipItem(
                                  'Volume: ${(spot.y / 1000).toStringAsFixed(0)}K',
                                  TextStyle(color: chartColor, fontWeight: FontWeight.bold, fontSize: 12),
                                );
                              }
                              return LineTooltipItem(
                                '₹${spot.y.toStringAsFixed(2)}',
                                TextStyle(color: chartColor, fontWeight: FontWeight.bold, fontSize: 12),
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
      default: return 15;
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
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
            style: TextStyle(color: _textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsGrid() {
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
              _buildEnhancedStatItem('Open', '₹${_selectedStock['price'] - 2.5}'),
              _buildEnhancedStatItem('Prev. Close', '₹${_selectedStock['price'] - _selectedStock['change']}'),
              _buildEnhancedStatItem('Day High', '₹${_selectedStock['high']}', Icons.arrow_upward, _green),
              _buildEnhancedStatItem('Day Low', '₹${_selectedStock['low']}', Icons.arrow_downward, _red),
              _buildEnhancedStatItem('Volume', _selectedStock['volume'], Icons.trending_up, _cyan),
              _buildEnhancedStatItem('P/E Ratio', _selectedStock['pe'].toString(), Icons.pie_chart, _violet),
              _buildEnhancedStatItem('Market Cap', _selectedStock['marketCap'], Icons.account_balance, _gold),
              _buildEnhancedStatItem('52W Range', '₹120 - ₹175', Icons.show_chart, _violetLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatItem(String label, String value, [IconData? icon, Color? iconColor]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
                  style: const TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
                  gradient: const LinearGradient(colors: [_violet, _violetDark]),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ...List.generate(_stocks.length, (index) {
            final stock = _stocks[index];
            final isUp = stock['change'] >= 0;
            final color = isUp ? _green : _red;

            return TweenAnimationBuilder(
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
                        gradient: LinearGradient(
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
                                colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                isUp ? Icons.trending_up : Icons.trending_down,
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
                                  stock['symbol'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stock['name'],
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
                                '₹${stock['price']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isUp ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: color,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${isUp ? '+' : ''}${stock['changePercent'].toStringAsFixed(2)}%',
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

      final gradientColor = (i % 3 != 0 ? _violetLight : _gold);
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