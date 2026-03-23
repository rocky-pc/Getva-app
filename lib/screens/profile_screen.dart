import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_manager.dart';
import '../widgets/common_bottom_nav.dart';
import 'settings_screen.dart';
import 'scratch_history_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS  (mirrors home_screen.dart)
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
const _green       = Color(0xFF22C55E);

// ═══════════════════════════════════════════════════════════════
//  PROFILE SCREEN
// ═══════════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  final bool showBottomNav;
  final int? selectedIndex;
  final Function(int)? onNavTap;

  const ProfileScreen({
    Key? key,
    this.showBottomNav = true,
    this.selectedIndex,
    this.onNavTap,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 2;
  String _userName = 'Lucky Winner';
  String _userEmail = 'Loading...';

  late AnimationController _entryCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _entryAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _pulseAnim;

  bool _animationsInitialized = false;

  final List<_Particle> _particles = [];

  // Fake stats for the profile
  final int _totalScratch   = 128;
  final int _totalWins      = 47;
  final String _totalEarned = '₹12,450';
  final String _rank        = 'Gold';

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutExpo);

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear),
    );

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat();

    final rng = math.Random(17);
    for (int i = 0; i < 22; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: rng.nextDouble() * 1.8 + 0.5,
        speed: rng.nextDouble() * 0.35 + 0.12,
        opacity: rng.nextDouble() * 0.4 + 0.07,
        phase: rng.nextDouble(),
      ));
    }

    _animationsInitialized = true;

    _loadUserData();
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) _entryCtrl.forward(); });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    _orbCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final name  = await SessionManager.getUserName();
    final email = await SessionManager.getUserEmail();
    if (mounted) {
      setState(() {
        _userName  = name  ?? 'Lucky Winner';
        _userEmail = email ?? 'winner@example.com';
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    if (widget.onNavTap != null) { widget.onNavTap!(index); return; }
    if (index == 0) Navigator.pushReplacementNamed(context, '/');
    else if (index == 1) Navigator.pushReplacementNamed(context, '/wallet');
    else setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    final ok = await _showLogoutDialog();
    if (ok == true) {
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (r) => false);
      }
    }
  }

  Future<bool?> _showLogoutDialog() {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.red, size: 26),
                ),
                const SizedBox(height: 18),
                const Text('Log Out?',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text("You'll need to sign back in to continue.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _textMuted, fontSize: 13, height: 1.5)),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: const Center(
                            child: Text('Cancel',
                                style: TextStyle(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.red.withOpacity(0.35)),
                          ),
                          child: const Center(
                            child: Text('Log Out',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Guard against accessing uninitialized late variables
    if (!_animationsInitialized) {
      return const Scaffold(
        backgroundColor: _surface,
        body: Center(
          child: CircularProgressIndicator(color: _gold),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _surface,
      extendBody: true,
      body: Stack(
        children: [
          // ── Background gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF080714), Color(0xFF0A0910), Color(0xFF060512)],
                stops: [0, 0.5, 1],
              ),
            ),
          ),

          // ── Orbs ──
          AnimatedBuilder(
            animation: _orbAnim,
            builder: (_, __) => Positioned(
              top: -60 + _orbAnim.value * 30,
              left: size.width / 2 - 180 + _orbAnim.value * 20,
              child: _OrbGlow(
                color: _gold.withOpacity(0.14 + _pulseAnim.value * 0.05),
                size: 380,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _orbAnim,
            builder: (_, __) => Positioned(
              top: 260 + _orbAnim.value * -25,
              right: -90 + _orbAnim.value * 15,
              child: _OrbGlow(
                color: _violet.withOpacity(0.10 + _pulseAnim.value * 0.03),
                size: 280,
              ),
            ),
          ),

          // ── Particles ──
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(
                particles: _particles,
                progress: _particleCtrl.value,
              ),
            ),
          ),

          // ── Noise ──
          Opacity(
            opacity: 0.022,
            child: CustomPaint(
              size: size,
              painter: _NoisePainter(),
            ),
          ),

          // ── Scroll content ──
          CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // ── Hero header ──
              SliverToBoxAdapter(child: _buildHero(size)),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Stats row ──
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.15,
                  child: _buildStatsRow(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Rank badge ──
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.22,
                  child: _buildRankBadge(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Section: General ──
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.28,
                  child: _SectionLabel(title: 'General'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.32,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MenuCard(
                      items: [
                        _MenuItem(
                          icon: Icons.history_rounded,
                          iconColor: _gold,
                          iconBg: _gold.withOpacity(0.12),
                          title: 'Scratch History',
                          subtitle: 'View your past wins',
                          onTap: () => Navigator.push(context,
                              _buildRoute(const ScratchHistoryScreen())),
                        ),
                        _MenuItem(
                          icon: Icons.settings_outlined,
                          iconColor: _violetLight,
                          iconBg: _violetLight.withOpacity(0.12),
                          title: 'Settings',
                          subtitle: 'Edit profile & password',
                          onTap: () => Navigator.push(context,
                              _buildRoute(const SettingsScreen())),
                        ),
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xFF38BDF8),
                          iconBg: const Color(0xFF38BDF8).withOpacity(0.1),
                          title: 'Help & Support',
                          subtitle: 'Get help with your account',
                        ),
                        _MenuItem(
                          icon: Icons.info_outline_rounded,
                          iconColor: _textMuted,
                          iconBg: _textMuted.withOpacity(0.1),
                          title: 'About',
                          subtitle: 'App version and licenses',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Section: More ──
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.38,
                  child: _SectionLabel(title: 'More'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.42,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MenuCard(
                      items: [
                        _MenuItem(
                          icon: Icons.share_rounded,
                          iconColor: _green,
                          iconBg: _green.withOpacity(0.1),
                          title: 'Refer & Earn',
                          subtitle: 'Earn ₹50 per referral',
                          badge: 'NEW',
                        ),
                        _MenuItem(
                          icon: Icons.star_rounded,
                          iconColor: _gold,
                          iconBg: _gold.withOpacity(0.1),
                          title: 'Rate Us',
                          subtitle: 'Love the app? Let us know!',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ── Logout ──
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.48,
                  child: _buildLogoutButton(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CommonBottomNav(
              selectedIndex: widget.selectedIndex ?? _selectedIndex,
              onTap: _onItemTapped,
            )
          : null,
    );
  }

  // ── Hero ──
  Widget _buildHero(Size size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Header background
        Container(
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF13102A), Color(0xFF1A1535), Color(0xFF0E0C1E)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative arcs
              Positioned(
                top: -60,
                right: -60,
                child: _OrbGlow(
                    color: _gold.withOpacity(0.08), size: 280),
              ),
              Positioned(
                bottom: -30,
                left: -40,
                child: _OrbGlow(
                    color: _violet.withOpacity(0.1), size: 200),
              ),
              // Grid lines (subtle)
              CustomPaint(
                size: Size(size.width, 260),
                painter: _GridPainter(),
              ),
            ],
          ),
        ),

        // Safe area + back arrow (if standalone)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                if (widget.showBottomNav) ...[
                  // Logo text
                  AnimatedBuilder(
                    animation: _shimmerAnim,
                    builder: (_, child) => ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: const [_gold, _goldBright, _gold],
                        begin: Alignment(-1.5 + _shimmerAnim.value * 4, 0),
                        end: Alignment(-0.5 + _shimmerAnim.value * 4, 0),
                      ).createShader(b),
                      child: child!,
                    ),
                    child: const Text('Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4)),
                  ),
                ] else ...[
                  const Text('Profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4)),
                ],
                const Spacer(),
                // Edit button
                _GlassButton(
                  onTap: () => Navigator.push(
                      context, _buildRoute(const SettingsScreen())),
                  child: Icon(Icons.edit_outlined,
                      color: Colors.white.withOpacity(0.75), size: 18),
                ),
              ],
            ),
          ),
        ),

        // Avatar + name block
        Positioned(
          left: 0,
          right: 0,
          top: 80,
          child: _AnimatedReveal(
            animation: _entryAnim,
            delay: 0.0,
            child: Column(
              children: [
                // Avatar ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        width: 96 + _pulseAnim.value * 8,
                        height: 96 + _pulseAnim.value * 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              _gold.withOpacity(0.6),
                              _violet.withOpacity(0.4),
                              _gold.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // White gap ring
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _surface,
                      ),
                    ),
                    // Avatar
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1A38), Color(0xFF2C2650)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                          Icons.person_rounded, size: 42, color: _gold),
                    ),
                    // Online badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _surface,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Name
                AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (_, child) => ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: const [_gold, _goldBright, _gold],
                      begin: Alignment(-1.5 + _shimmerAnim.value * 4, 0),
                      end: Alignment(-0.5 + _shimmerAnim.value * 4, 0),
                    ).createShader(b),
                    child: child!,
                  ),
                  child: Text(_userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3)),
                ),
                const SizedBox(height: 5),
                Text(_userEmail,
                    style: const TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats Row ──
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
              child: _StatCard(
                  value: '$_totalScratch',
                  label: 'Scratched',
                  icon: Icons.layers_rounded,
                  iconColor: _violetLight)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  value: '$_totalWins',
                  label: 'Wins',
                  icon: Icons.emoji_events_rounded,
                  iconColor: _gold)),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  value: _totalEarned,
                  label: 'Earned',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: _green)),
        ],
      ),
    );
  }

  // ── Rank badge ──
  Widget _buildRankBadge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(_cardBg, _cardBg2, 0.5 + _pulseAnim.value * 0.5)!,
                _cardBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: Color.lerp(_border, _gold.withOpacity(0.3),
                    _pulseAnim.value)!),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.05 + _pulseAnim.value * 0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
        child: Row(
          children: [
            // Rank icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, _goldBright],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🏅',
                    style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$_rank Member',
                          style: const TextStyle(
                              color: _gold,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _gold.withOpacity(0.3)),
                        ),
                        child: const Text('ELITE',
                            style: TextStyle(
                                color: _gold,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.68,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_gold),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('680 / 1000 XP to Platinum',
                      style: const TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout button ──
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _PressableButton(
        onTap: _logout,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded,
                  color: Colors.red.withOpacity(0.9), size: 20),
              const SizedBox(width: 10),
              Text('Log Out',
                  style: TextStyle(
                      color: Colors.red.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  PageRoute _buildRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, anim, __) => page,
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
        transitionDuration: const Duration(milliseconds: 350),
      );
}

// ═══════════════════════════════════════════════════════════════
//  STAT CARD
// ═══════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    Key? key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: _textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SECTION LABEL
// ═══════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
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
              boxShadow: [
                BoxShadow(
                    color: _gold.withOpacity(0.5), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(title.toUpperCase(),
              style: const TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MENU CARD  +  MENU ITEM
// ═══════════════════════════════════════════════════════════════
class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? badge;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.badge,
    this.isLast = false,
  });
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: items.map((item) {
          final idx = items.indexOf(item);
          return Column(
            children: [
              _MenuItemTile(item: item),
              if (!item.isLast)
                Divider(
                  height: 1,
                  color: _border,
                  indent: 64,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItemTile extends StatefulWidget {
  final _MenuItem item;
  const _MenuItemTile({Key? key, required this.item}) : super(key: key);

  @override
  State<_MenuItemTile> createState() => _MenuItemTileState();
}

class _MenuItemTileState extends State<_MenuItemTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.item.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _pressed
            ? Colors.white.withOpacity(0.03)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.item.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.item.icon,
                  color: widget.item.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.item.title,
                          style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      if (widget.item.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: _green.withOpacity(0.35)),
                          ),
                          child: Text(widget.item.badge!,
                              style: const TextStyle(
                                  color: _green,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(widget.item.subtitle,
                      style: const TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right_rounded,
                color: _textMuted.withOpacity(0.6), size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PRESSABLE BUTTON
// ═══════════════════════════════════════════════════════════════
class _PressableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _PressableButton(
      {Key? key, required this.onTap, required this.child})
      : super(key: key);

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
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
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _ctrl.value * 0.03,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ANIMATED REVEAL
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
            offset: Offset(0, 26 * (1 - curve)),
            child: child,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GLASS BUTTON
// ═══════════════════════════════════════════════════════════════
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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
            colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GRID PAINTER  (decorative header lines)
// ═══════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ═══════════════════════════════════════════════════════════════
//  PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════════
class _Particle {
  final double x, y, radius, speed, opacity, phase;
  const _Particle({
    required this.x, required this.y, required this.radius,
    required this.speed, required this.opacity, required this.phase,
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
      final fade = (1 - (y < 0.15 ? (0.15 - y) / 0.15 : 0)) *
          (y > 0.85 ? (1.0 - y) / 0.15 : 1);
      paint.color = (i % 3 != 0 ? _gold : _violetLight)
          .withOpacity(p.opacity * fade);
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
//  NOISE PAINTER
// ═══════════════════════════════════════════════════════════════
class _NoisePainter extends CustomPainter {
  final _rng = math.Random(77);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 1600; i++) {
      paint.color = Colors.white.withOpacity(_rng.nextDouble() * 0.5);
      canvas.drawCircle(
        Offset(_rng.nextDouble() * size.width,
            _rng.nextDouble() * size.height),
        _rng.nextDouble() * 0.65,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_NoisePainter _) => false;
}