import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/mystery_boxes_section.dart';
import '../models/mystery_box.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../widgets/common_bottom_nav.dart';
import 'mystery_box_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'gold_screen.dart';
import 'getva_coin_screen.dart';
import 'share_market_screen.dart';

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

// ═══════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _bannerImage = '';
  List<MysteryBox> _mysteryBoxes = [];
  bool _isLoading = true;

  // Controllers
  late AnimationController _shimmerCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;

  late Animation<double> _shimmerAnim;
  late Animation<double> _entryAnim;
  late Animation<double> _pulseAnim;
  Animation<double>? _orbAnim;

  // Getter with fallback for null safety
  Animation<double> get _orbAnimSafe => _orbAnim ?? _pulseAnim;

  final GlobalKey<_WalletChipState> _walletChipKey =
  GlobalKey<_WalletChipState>();

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Shimmer
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear),
    );

    // Entry reveal
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutExpo);

    // Particle float
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Pulse glow
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    // Orb drift
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    // Seed particles
    final rng = math.Random(42);
    for (int i = 0; i < 28; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: rng.nextDouble() * 2.0 + 0.6,
        speed: rng.nextDouble() * 0.4 + 0.15,
        opacity: rng.nextDouble() * 0.45 + 0.08,
        phase: rng.nextDouble(),
      ));
    }

    _loadAppConfig();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _entryCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAppConfig() async {
    try {
      final config = await ApiService.getAppConfig();
      if (mounted) {
        setState(() {
          _bannerImage = config['banner_image'] as String? ?? '';
          _mysteryBoxes = (config['mystery_boxes'] as List<dynamic>)
              .map((j) => MysteryBox.fromJson(j as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  void _onBoxTap(MysteryBox box) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => MysteryBoxScreen(box: box),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                begin: const Offset(0, 0.05), end: Offset.zero)
                .animate(CurvedAnimation(
                parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    ).then((_) => _walletChipKey.currentState?.refreshBalance());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _surface,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(size),
          const WalletScreen(showBottomNav: false),
          const ProfileScreen(showBottomNav: false),
        ],
      ),
      bottomNavigationBar: CommonBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeContent(Size size) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // ── Deep background gradient ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF080714), Color(0xFF0A0910), Color(0xFF060512)],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
          ),

          // ── Animated orb 1 ──
          AnimatedBuilder(
            animation: _orbAnimSafe,
            builder: (_, __) => Positioned(
              top: -80 + _orbAnimSafe.value * 40,
              left: size.width / 2 - 200 + _orbAnimSafe.value * 30,
              child: _OrbGlow(
                color: _gold.withOpacity(0.18 + _pulseAnim.value * 0.06),
                size: 420,
              ),
            ),
          ),

          // ── Animated orb 2 ──
          AnimatedBuilder(
            animation: _orbAnimSafe,
            builder: (_, __) => Positioned(
              top: 180 + _orbAnimSafe.value * -30,
              right: -110 + _orbAnimSafe.value * 20,
              child: _OrbGlow(
                color: _violet.withOpacity(0.12 + _pulseAnim.value * 0.04),
                size: 320,
              ),
            ),
          ),

          // ── Orb 3 bottom ──
          AnimatedBuilder(
            animation: _orbAnimSafe,
            builder: (_, __) => Positioned(
              bottom: 140,
              left: -70 + _orbAnimSafe.value * 25,
              child: _OrbGlow(
                color: _violetLight.withOpacity(0.08),
                size: 260,
              ),
            ),
          ),

          // ── Floating particles ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleCtrl.value,
                ),
              ),
            ),
          ),

          // ── Noise/grain overlay ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.025,
              child: CustomPaint(
                painter: _NoisePainter(),
              ),
            ),
          ),

          // ── Main scroll ──
          CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // AppBar
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: _buildAppBar(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 22)),

              // Live Stats Row
              SliverToBoxAdapter(
                child: _buildStatsRow(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Greeting
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _AnimatedReveal(
                    animation: _entryAnim,
                    delay: 0.0,
                    child: _GreetingBanner(pulseAnim: _pulseAnim),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Investment Options
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.15,
                  child: _InvestmentOptionsSection(
                    onGoldTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GoldScreen()),
                      );
                    },
                    onShareMarketTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share market feature coming soon!')),
                      );
                    },
                    onGetvaCoinTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Getva Coin feature coming soon!')),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // Banner
              if (!_isLoading && _bannerImage.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _AnimatedReveal(
                      animation: _entryAnim,
                      delay: 0.1,
                      child: _StyledBanner(imageUrl: _bannerImage),
                    ),
                  ),
                ),

              if (!_isLoading && _bannerImage.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // Section label
              if (!_isLoading && _mysteryBoxes.isNotEmpty)
                SliverToBoxAdapter(
                  child: _AnimatedReveal(
                    animation: _entryAnim,
                    delay: 0.2,
                    child: _SectionLabel(shimmer: _shimmerAnim),
                  ),
                ),

              if (!_isLoading && _mysteryBoxes.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height:0)),

              // Mystery boxes
              if (!_isLoading && _mysteryBoxes.isNotEmpty)
                SliverToBoxAdapter(
                  child: _AnimatedReveal(
                    animation: _entryAnim,
                    delay: 0.3,
                    child: MysteryBoxesSection(
                      boxes: _mysteryBoxes,
                      onBoxTap: _onBoxTap,
                    ),
                  ),
                ),

              // Empty state
              if (!_isLoading && _mysteryBoxes.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: _EmptyState(),
                  ),
                ),

              // Loading skeleton
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _LoadingSkeleton(shimmer: _shimmerAnim),
                  ),
                ),

              // Recent wins marquee
              if (!_isLoading)


                const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          // Logo
          _AnimatedReveal(
            animation: _entryAnim,
            delay: 0.0,
            child: _LogoMark(shimmer: _shimmerAnim),
          ),
          const Spacer(),
          // Wallet chip
          _AnimatedReveal(
            animation: _entryAnim,
            delay: 0.05,
            child: _WalletChip(key: _walletChipKey),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 10),
          // Notification
          _AnimatedReveal(
            animation: _entryAnim,
            delay: 0.08,
            child: _NotifButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return _AnimatedReveal(
      animation: _entryAnim,
      delay: 0.05,
      child: SizedBox(
        height: 72,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: const [
            _StatPill(icon: Icons.emoji_events_rounded, label: 'Winners Today', value: '1,248'),
            SizedBox(width: 10),
            _StatPill(icon: Icons.local_fire_department_rounded, label: 'Boxes Opened', value: '8.3K'),
            SizedBox(width: 10),
            _StatPill(icon: Icons.diamond_rounded, label: 'Top Prize', value: '₹5,000'),
            SizedBox(width: 10),
            _StatPill(icon: Icons.bolt_rounded, label: 'Live Players', value: '432'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ANIMATED REVEAL WRAPPER
// ═══════════════════════════════════════════════════════════════
class _AnimatedReveal extends StatelessWidget {
  final Animation<double> animation;
  final double delay;
  final Widget child;

  const _AnimatedReveal({
    Key? key,
    required this.animation,
    required this.delay,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = ((animation.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutExpo.transform(t);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - curve)),
            child: child,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LOGO MARK
// ═══════════════════════════════════════════════════════════════
class _LogoMark extends StatelessWidget {
  final Animation<double> shimmer;
  const _LogoMark({Key? key, required this.shimmer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon mark
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_gold, _goldBright],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text('G',
                style: TextStyle(
                    color: Color(0xFF1A1200),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1)),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: shimmer,
              builder: (_, child) => ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(-1.5 + shimmer.value * 4, 0),
                  end: Alignment(-0.5 + shimmer.value * 4, 0),
                  colors: const [_gold, _goldBright, _gold],
                ).createShader(bounds),
                child: child!,
              ),
              child: const Text(
                'GETVA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              'SCRATCH & WIN',
              style: TextStyle(
                color: _gold.withOpacity(0.5),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STAT PILL
// ═══════════════════════════════════════════════════════════════
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _gold, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: _textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GREETING BANNER
// ═══════════════════════════════════════════════════════════════
class _GreetingBanner extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _GreetingBanner({Key? key, required this.pulseAnim}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    final emoji = hour < 12 ? '☀️' : hour < 17 ? '🌤️' : '🌙';

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, child) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _cardBg,
              Color.lerp(_cardBg, _cardBg2, 0.6 + pulseAnim.value * 0.4)!,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Color.lerp(
                _border, _gold.withOpacity(0.2), pulseAnim.value)!,
          ),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.04 + pulseAnim.value * 0.04),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ready to win big today?',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '432 players online now',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _PulsePlayButton(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PULSE PLAY BUTTON
// ═══════════════════════════════════════════════════════════════
class _PulsePlayButton extends StatefulWidget {
  @override
  State<_PulsePlayButton> createState() => _PulsePlayButtonState();
}

class _PulsePlayButtonState extends State<_PulsePlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.stop(),
        onTapUp: (_) => _ctrl.repeat(reverse: true),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Container(
                width: 72 + _ctrl.value * 8,
                height: 72 + _ctrl.value * 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gold.withOpacity(0.15 + _ctrl.value * 0.1),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Button
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, _goldBright, _goldDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFF1A1200), size: 22),
                  Text(
                    'PLAY',
                    style: TextStyle(
                      color: Color(0xFF1A1200),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
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
}

// ═══════════════════════════════════════════════════════════════
//  STYLED BANNER
// ═══════════════════════════════════════════════════════════════
class _StyledBanner extends StatefulWidget {
  final String imageUrl;
  const _StyledBanner({Key? key, required this.imageUrl}) : super(key: key);

  @override
  State<_StyledBanner> createState() => _StyledBannerState();
}

class _StyledBannerState extends State<_StyledBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1C1726), Color(0xFF2A1F3D)],
                  ),
                ),
              ),
            ),
            // Dark overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.72),
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            // Diagonal gold sheen
            AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-2 + _shimmerAnim.value * 4, -1),
                    end: Alignment(-1.5 + _shimmerAnim.value * 4, 1),
                    colors: [
                      Colors.transparent,
                      _gold.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 20,
              bottom: 18,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _gold.withOpacity(0.5), width: 1),
                        ),
                        child: const Row(
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 10)),
                            SizedBox(width: 4),
                            Text(
                              'LIMITED OFFER',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.red.withOpacity(0.4), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Win up to ₹5,000 today!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New mystery boxes drop every hour',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
}

// ═══════════════════════════════════════════════════════════════
//  SECTION LABEL
// ═══════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final Animation<double> shimmer;
  const _SectionLabel({Key? key, required this.shimmer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Gold accent line
          Container(
            width: 3,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gold, _goldBright],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: shimmer,
                builder: (_, child) => ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: const [_gold, _goldBright, _gold],
                    begin: Alignment(-1.5 + shimmer.value * 4, 0),
                    end: Alignment(-0.5 + shimmer.value * 4, 0),
                  ).createShader(b),
                  child: child!,
                ),
                child: const Text(
                  'Mystery Boxes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const Text(
                'Scratch to reveal your prize',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, color: _gold, size: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════
//  WALLET CHIP
// ═══════════════════════════════════════════════════════════════
class _WalletChip extends StatefulWidget {
  const _WalletChip({Key? key}) : super(key: key);

  @override
  State<_WalletChip> createState() => _WalletChipState();
}

class _WalletChipState extends State<_WalletChip>
    with SingleTickerProviderStateMixin {
  double _balance = 0.0;
  bool _isLoading = true;

  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _loadBalance();
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final balance = await ApiService.getUserWalletBalance(userId);
      if (mounted) {
        setState(() {
          _balance = balance;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> refreshBalance() async {
    if (mounted) setState(() => _isLoading = true);
    await _loadBalance();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        Navigator.pushNamed(context, '/wallet');
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _pressCtrl.value * 0.04,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_cardBg, _cardBg2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: _gold, size: 12),
              ),
              const SizedBox(width: 7),
              _isLoading
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.8, color: _gold),
              )
                  : Text(
                '₹${_balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  NOTIFICATION BUTTON
// ═══════════════════════════════════════════════════════════════
class _NotifButton extends StatefulWidget {
  @override
  State<_NotifButton> createState() => _NotifButtonState();
}

class _NotifButtonState extends State<_NotifButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.10, end: -0.10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // Auto shake every 5s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _ctrl.forward().then((_) => _ctrl.reset());
        Future.doWhile(() async {
          await Future.delayed(const Duration(seconds: 5));
          if (!mounted) return false;
          _ctrl.forward().then((_) => _ctrl.reset());
          return true;
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.rotate(
        angle: _shakeAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: () {},
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      color: Colors.white.withOpacity(0.75), size: 20),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _gold,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  _EmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(44),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_cardBg, _cardBg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withOpacity(0.08),
              border: Border.all(color: _gold.withOpacity(0.15)),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 36, color: _gold),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Mystery Boxes Yet',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New boxes drop soon — check back later!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.3),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LOADING SKELETON
// ═══════════════════════════════════════════════════════════════
class _LoadingSkeleton extends StatelessWidget {
  final Animation<double> shimmer;
  const _LoadingSkeleton({Key? key, required this.shimmer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: 160, height: 20, shimmer: shimmer),
        const SizedBox(height: 20),
        _SkeletonBlock(width: double.infinity, height: 155, shimmer: shimmer),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
                child: _SkeletonBlock(
                    width: double.infinity, height: 160, shimmer: shimmer)),
            const SizedBox(width: 14),
            Expanded(
                child: _SkeletonBlock(
                    width: double.infinity, height: 160, shimmer: shimmer)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final Animation<double> shimmer;

  const _SkeletonBlock({
    Key? key,
    required this.width,
    required this.height,
    required this.shimmer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + shimmer.value * 4, 0),
            end: Alignment(-0.5 + shimmer.value * 4, 0),
            colors: const [
              Color(0xFF120F22),
              Color(0xFF1E1930),
              Color(0xFF120F22),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ORB GLOW
// ═══════════════════════════════════════════════════════════════
class _OrbGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _OrbGlow({Key? key, required this.color, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════════
class _Particle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double opacity;
  final double phase;

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

  const _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = (p.y - t) % 1.0;
      final x = p.x + math.sin(t * math.pi * 2 + p.phase * 6) * 0.04;
      final opacity = p.opacity *
          (1 - (y < 0.15 ? (0.15 - y) / 0.15 : 0)) *
          (y > 0.85 ? (1.0 - y) / 0.15 : 1);

      // Alternate: gold or violet
      final isGold = (particles.indexOf(p) % 3 != 0);
      paint.color = isGold
          ? _gold.withOpacity(opacity)
          : _violetLight.withOpacity(opacity * 0.7);

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

// ═══════════════════════════════════════════════════════════════
//  NOISE PAINTER (grain texture)
// ═══════════════════════════════════════════════════════════════
class _NoisePainter extends CustomPainter {
  final _rng = math.Random(99);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 2000; i++) {
      paint.color = Colors.white.withOpacity(_rng.nextDouble() * 0.5);
      canvas.drawCircle(
        Offset(
          _rng.nextDouble() * size.width,
          _rng.nextDouble() * size.height,
        ),
        _rng.nextDouble() * 0.7,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_NoisePainter _) => false;
}

// ═══════════════════════════════════════════════════════════════
//  INVESTMENT OPTIONS SECTION
// ═══════════════════════════════════════════════════════════════
class _InvestmentOptionsSection extends StatelessWidget {
  final VoidCallback onGoldTap;
  final VoidCallback onShareMarketTap;
  final VoidCallback onGetvaCoinTap;

  const _InvestmentOptionsSection({
    Key? key,
    required this.onGoldTap,
    required this.onShareMarketTap,
    required this.onGetvaCoinTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Investment Options',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InvestmentCard(
                  title: 'Gold',
                  // subtitle: 'Digital Gold',
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: const LinearGradient(
                    colors: [_gold, _goldBright],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: onGoldTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InvestmentCard(
                  title: 'Share Market',
                  // subtitle: 'Coming Soon',
                  icon: Icons.trending_up_rounded,
                  gradient: const LinearGradient(
                    colors: [_violet, _violetLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ShareMarketScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InvestmentCard(
                  title: 'Getva Coin',
                  // subtitle: 'Coming Soon',
                  icon: Icons.currency_bitcoin_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GetvaCoinScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  INVESTMENT CARD
// ═══════════════════════════════════════════════════════════════
class _InvestmentCard extends StatelessWidget {
  final String title;
  // final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _InvestmentCard({
    Key? key,
    required this.title,
    // required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _cardBg,
              _cardBg2,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Text(
            //   subtitle,
            //   style: TextStyle(
            //     color: _textMuted,
            //     fontSize: 10,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
