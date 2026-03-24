import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

// ── Design tokens ────────────────────────────────────────────────
const _gold        = Color(0xFFD4A847);
const _goldBright  = Color(0xFFFFE066);
const _surface     = Color(0xFF0A0910);
const _cardBg      = Color(0xFF110F1E);
const _cardBg2     = Color(0xFF16132A);
const _violet      = Color(0xFF5A3FBF);
const _violetLight = Color(0xFF8B6FE8);
const _green       = Color(0xFF22C55E);
const _red         = Color(0xFFEF4444);
const _textPrimary = Colors.white;
const _textMuted   = Color(0xFF6B6880);
const _border      = Color(0xFF1E1B32);

class ShareMarketScreen extends StatefulWidget {
  const ShareMarketScreen({super.key});

  @override
  State<ShareMarketScreen> createState() => _ShareMarketScreenState();
}

class _ShareMarketScreenState extends State<ShareMarketScreen> with TickerProviderStateMixin {
  String _selectedPeriod = '1D';
  bool _isLoading = true;
  
  // Mock data for a selected stock
  final Map<String, dynamic> _selectedStock = {
    'symbol': 'TATASTEEL',
    'name': 'Tata Steel Ltd.',
    'price': 158.45,
    'change': 2.35,
    'changePercent': 1.50,
    'high': 160.20,
    'low': 155.80,
    'volume': '12.4M',
  };

  final List<Map<String, dynamic>> _trendingStocks = [
    {'symbol': 'RELIANCE', 'price': 2950.20, 'change': 15.40, 'isUp': true},
    {'symbol': 'HDFCBANK', 'price': 1445.60, 'change': -5.20, 'isUp': false},
    {'symbol': 'INFY', 'price': 1620.00, 'change': 12.80, 'isUp': true},
    {'symbol': 'TCS', 'price': 3890.45, 'change': -20.10, 'isUp': false},
  ];

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

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _shimmerAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);

    final rng = math.Random(77);
    for (int i = 0; i < 25; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(), y: rng.nextDouble(),
        radius: rng.nextDouble() * 1.5 + 0.5,
        speed: rng.nextDouble() * 0.3 + 0.1,
        opacity: rng.nextDouble() * 0.3 + 0.05,
        phase: rng.nextDouble(),
      ));
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _entryCtrl.forward(); });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _orbCtrl.dispose(); 
    _particleCtrl.dispose(); _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Background components (similar to GoldScreen)
          Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF080714), Color(0xFF0A0910), Color(0xFF060512)])))),
          Positioned.fill(child: AnimatedBuilder(animation: _orbAnim, builder: (context, child) => Stack(children: [Positioned(top: -100 + _orbAnim.value * 40, left: size.width / 2 - 200, child: _OrbGlow(color: _violet.withOpacity(0.12 + _pulseAnim.value * 0.04), size: 400)), Positioned(bottom: 100 + _orbAnim.value * -30, right: -100, child: _OrbGlow(color: _gold.withOpacity(0.08), size: 300))]))),
          Positioned.fill(child: AnimatedBuilder(animation: _particleCtrl, builder: (context, child) => CustomPaint(painter: _ParticlePainter(particles: _particles, progress: _particleCtrl.value)))),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(child: _AnimatedReveal(animation: _entryAnim, delay: 0.0, child: _buildHeroCard())),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: _AnimatedReveal(animation: _entryAnim, delay: 0.1, child: _buildPeriodSelector())),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: _AnimatedReveal(animation: _entryAnim, delay: 0.2, child: _buildChartSection())),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: _AnimatedReveal(animation: _entryAnim, delay: 0.3, child: _buildStatsGrid())),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(child: _AnimatedReveal(animation: _entryAnim, delay: 0.4, child: _buildTrendingSection())),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            _GlassButton(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedStock['symbol'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text(_selectedStock['name'], style: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            _GlassButton(onTap: () {}, child: const Icon(Icons.search_rounded, color: Colors.white, size: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final bool isUp = _selectedStock['change'] >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Price', style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('₹${_selectedStock['price']}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isUp ? _green : _red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (isUp ? _green : _red).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: isUp ? _green : _red, size: 16),
                      const SizedBox(width: 4),
                      Text('${isUp ? '+' : ''}${_selectedStock['changePercent']}%', style: TextStyle(color: isUp ? _green : _red, fontWeight: FontWeight.w800, fontSize: 14)),
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

  Widget _buildPeriodSelector() {
    final periods = ['1D', '1W', '1M', '1Y', 'ALL'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: periods.map((p) => GestureDetector(
          onTap: () => setState(() => _selectedPeriod = p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _selectedPeriod == p ? _violet : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _selectedPeriod == p ? _violetLight : _border),
            ),
            child: Text(p, style: TextStyle(color: _selectedPeriod == p ? Colors.white : _textMuted, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildChartSection() {
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
        child: _isLoading ? const Center(child: CircularProgressIndicator(color: _violet)) : LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  const FlSpot(0, 155), const FlSpot(1, 157), const FlSpot(2, 156),
                  const FlSpot(3, 159), const FlSpot(4, 158), const FlSpot(5, 160),
                  const FlSpot(6, 158.45),
                ],
                isCurved: true,
                color: _violetLight,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_violetLight.withOpacity(0.2), Colors.transparent],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market Stats', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatItem('Open', '₹156.20'),
              _buildStatItem('Prev. Close', '₹156.10'),
              _buildStatItem('Day High', '₹${_selectedStock['high']}'),
              _buildStatItem('Day Low', '₹${_selectedStock['low']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trending Stocks', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ..._trendingStocks.map((stock) => _buildTrendingItem(stock)).toList(),
        ],
      ),
    );
  }

  Widget _buildTrendingItem(Map<String, dynamic> stock) {
    final bool isUp = stock['isUp'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _violet.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Icon(Icons.business_rounded, color: _violetLight, size: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock['symbol'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                const Text('NSE', style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${stock['price']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              Text('${isUp ? '+' : ''}${stock['change']}', style: TextStyle(color: isUp ? _green : _red, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Helper Widgets (Copy/adapted from GoldScreen)
// ─────────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap; final Widget child; const _GlassButton({required this.onTap, required this.child});
  @override Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.08))), child: Center(child: child))); }
}

class _OrbGlow extends StatelessWidget {
  final Color color; final double size;
  const _OrbGlow({required this.color, required this.size});
  @override Widget build(BuildContext context) { return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)]))); }
}

class _Particle { final double x, y, radius, speed, opacity, phase; const _Particle({required this.x, required this.y, required this.radius, required this.speed, required this.opacity, required this.phase}); }
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles; final double progress;
  const _ParticlePainter({required this.particles, required this.progress});
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i]; final t = (progress * p.speed + p.phase) % 1.0; final y = (p.y - t) % 1.0; final x = p.x + math.sin(t * math.pi * 2 + p.phase * 6) * 0.04;
      paint.color = (i % 3 != 0 ? _violetLight : _gold).withOpacity(p.opacity); canvas.drawCircle(Offset(x * size.width, y * size.height), p.radius, paint);
    }
  }
  @override bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _AnimatedReveal extends StatelessWidget {
  final Animation<double> animation; final double delay; final Widget child;
  const _AnimatedReveal({required this.animation, required this.delay, required this.child});
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = ((animation.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Opacity(opacity: curve, child: Transform.translate(offset: Offset(0, 20 * (1 - curve)), child: child));
      },
      child: child,
    );
  }
}
