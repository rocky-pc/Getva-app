import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../widgets/mystery_boxes_section.dart';
import '../models/mystery_box.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../widgets/common_bottom_nav.dart';
import 'mystery_box_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _bannerImage = '';
  List<MysteryBox> _mysteryBoxes = [];
  bool _isLoading = true;

  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;
  late AnimationController _navIndicatorCtrl;

  // Key for wallet chip to refresh balance
  final GlobalKey<_WalletChipState> _walletChipKey =
  GlobalKey<_WalletChipState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear),
    );

    _navIndicatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _loadAppConfig();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _navIndicatorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAppConfig() async {
    try {
      final config = await ApiService.getAppConfig();
      if (mounted) {
        setState(() {
          _bannerImage = config['banner_image'] as String? ?? '';
          _mysteryBoxes = (config['mystery_boxes'] as List<dynamic>)
              .map((json) => MysteryBox.fromJson(json as Map<String, dynamic>))
              .toList()
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

    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/wallet');
      return;
    }
    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
      return;
    }
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
            position:
            Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((_) {
      // Refresh wallet balance when returning from mystery box screen
      _walletChipKey.currentState?.refreshBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      extendBody: true,
      body: Stack(
        children: [
          // ── Ambient glows ──
          Positioned(
            top: -120,
            left: size.width / 2 - 180,
            child: _AmbientGlow(
                color: const Color(0xFFD4A847).withOpacity(0.14), size: 360),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: _AmbientGlow(
                color: const Color(0xFF6B3FD4).withOpacity(0.09), size: 280),
          ),
          Positioned(
            bottom: 160,
            left: -60,
            child: _AmbientGlow(
                color: const Color(0xFFD4A847).withOpacity(0.06), size: 220),
          ),

          // ── Main scroll content ──
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        // Logo wordmark
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedBuilder(
                              animation: _shimmerAnim,
                              builder: (_, child) => ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  begin: Alignment(
                                      -1.5 + _shimmerAnim.value * 4, 0),
                                  end: Alignment(
                                      -0.5 + _shimmerAnim.value * 4, 0),
                                  colors: const [
                                    Color(0xFFD4A847),
                                    Color(0xFFFFE87C),
                                    Color(0xFFD4A847),
                                  ],
                                ).createShader(bounds),
                                child: child!,
                              ),
                              child: const Text(
                                'GETVA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Text(
                              'Scratch & Win',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Wallet quick chip
                        _WalletChip(key: _walletChipKey),
                        const SizedBox(width: 10),
                        // Notification button
                        _GlassButton(
                          onTap: () {},
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  color: Colors.white.withOpacity(0.75),
                                  size: 20),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD4A847),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Greeting card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _GreetingBanner(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Banner ──
              if (!_isLoading && _bannerImage.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StyledBanner(imageUrl: _bannerImage),
                  ),
                ),

              if (!_isLoading && _bannerImage.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Section header: Mystery Boxes (commented out as in original) ──
              if (!_isLoading && _mysteryBoxes.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 0),
                ),

              // ── Mystery boxes ──
              if (!_isLoading && _mysteryBoxes.isNotEmpty)
                SliverToBoxAdapter(
                  child: MysteryBoxesSection(
                    boxes: _mysteryBoxes,
                    onBoxTap: _onBoxTap,
                  ),
                ),

              // ── Empty state ──
              if (!_isLoading && _mysteryBoxes.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: _EmptyState(),
                  ),
                ),

              // ── Loading skeleton ──
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _LoadingSkeleton(shimmer: _shimmerAnim),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),

      // ── Bottom Nav ──
      bottomNavigationBar: CommonBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ─── Greeting Banner ──────────────────────────────────────────────────────────

class _GreetingBanner extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _GreetingBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    final emoji = hour < 12 ? '☀️' : hour < 17 ? '🌤️' : '🌙';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting $emoji',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Ready to win big today?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A847), Color(0xFFFFD700)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4A847).withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFF1A1200), size: 15),
                SizedBox(width: 4),
                Text(
                  'Play Now',
                  style: TextStyle(
                    color: Color(0xFF1A1200),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Styled Banner ────────────────────────────────────────────────────────────

class _StyledBanner extends StatelessWidget {
  final String imageUrl;
  const _StyledBanner({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A847).withOpacity(0.15),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1C1726), Color(0xFF2A1F3D)],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A847).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFD4A847).withOpacity(0.5)),
                    ),
                    child: const Text(
                      '🔥 LIMITED OFFER',
                      style: TextStyle(
                        color: Color(0xFFD4A847),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Win up to ₹500 today!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
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

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onAction;

  const _SectionHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A847).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFD4A847).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: Color(0xFFD4A847),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFD4A847), size: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Wallet Chip ──────────────────────────────────────────────────────────────

class _WalletChip extends StatefulWidget {
  const _WalletChip({Key? key}) : super(key: key);

  @override
  State<_WalletChip> createState() => _WalletChipState();
}

class _WalletChipState extends State<_WalletChip> {
  double _balance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
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

  /// Public method called from HomeScreen to refresh after box purchase.
  Future<void> refreshBalance() async {
    if (mounted) setState(() => _isLoading = true);
    await _loadBalance();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/wallet'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF141220),
          borderRadius: BorderRadius.circular(20),
          border:
          Border.all(color: const Color(0xFFD4A847).withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_rounded,
                color: Color(0xFFD4A847), size: 15),
            const SizedBox(width: 6),
            _isLoading
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD4A847),
              ),
            )
                : Text(
              '₹${_balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _EmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF141220),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4A847).withOpacity(0.08),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 34, color: Color(0xFFD4A847)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Mystery Boxes Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'New boxes drop soon — check back later!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.35),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Skeleton ─────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  final Animation<double> shimmer;
  const _LoadingSkeleton({Key? key, required this.shimmer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: 140, height: 18, shimmer: shimmer),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _SkeletonBlock(
                    width: double.infinity, height: 140, shimmer: shimmer)),
            const SizedBox(width: 12),
            Expanded(
                child: _SkeletonBlock(
                    width: double.infinity, height: 140, shimmer: shimmer)),
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
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + shimmer.value * 4, 0),
            end: Alignment(-0.5 + shimmer.value * 4, 0),
            colors: const [
              Color(0xFF1A1727),
              Color(0xFF252035),
              Color(0xFF1A1727),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Supporting Widgets ────────────────────────────────────────────────

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlow({Key? key, required this.color, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _GlassButton({Key? key, required this.onTap, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}