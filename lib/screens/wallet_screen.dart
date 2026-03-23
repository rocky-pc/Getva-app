import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/wallet_balance_card.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/common_bottom_nav.dart';

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
const _green       = Color(0xFF22C55E);
const _red         = Color(0xFFEF4444);
const _textPrimary = Colors.white;
const _textMuted   = Color(0xFF6B6880);
const _border      = Color(0xFF1E1B32);

// ═══════════════════════════════════════════════════════════════
//  WALLET SCREEN
// ═══════════════════════════════════════════════════════════════
class WalletScreen extends StatefulWidget {
  final bool showBottomNav;
  final int? selectedIndex;
  final Function(int)? onNavTap;

  const WalletScreen({
    Key? key,
    this.showBottomNav = true,
    this.selectedIndex,
    this.onNavTap,
  }) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  List<int> _rupeeOptions = [];
  bool _isLoading = true;
  int _selectedIndex = 1;

  late AnimationController _entryCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _fabCtrl;

  late Animation<double> _entryAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _fabAnim;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutExpo);

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

    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _fabAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut);

    // FIX: seed with a fixed value so _NoisePainter and particles are stable
    final rng = math.Random(55);
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: rng.nextDouble() * 1.8 + 0.5,
        speed: rng.nextDouble() * 0.35 + 0.12,
        opacity: rng.nextDouble() * 0.38 + 0.07,
        phase: rng.nextDouble(),
      ));
    }

    _loadRupeeOptions();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    _orbCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRupeeOptions() async {
    try {
      final options = await ApiService.getRupeeOptions();
      if (mounted) {
        setState(() {
          _rupeeOptions = options;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rupeeOptions = [10, 50, 100, 500, 1000, 2000];
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    if (widget.onNavTap != null) {
      widget.onNavTap!(index);
      return;
    }
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                colors: [
                  Color(0xFF080714),
                  Color(0xFF0A0910),
                  Color(0xFF060512)
                ],
                stops: [0, 0.5, 1],
              ),
            ),
          ),

          // ── Orbs — FIX: merge both orbAnim and pulseAnim so both drive rebuilds ──
          AnimatedBuilder(
            animation: Listenable.merge([_orbAnim, _pulseAnim]),
            builder: (_, __) => Stack(
              children: [
                Positioned(
                  top: -80 + _orbAnim.value * 35,
                  left: size.width / 2 - 190 + _orbAnim.value * 25,
                  child: _OrbGlow(
                    color: _gold
                        .withOpacity(0.15 + _pulseAnim.value * 0.05),
                    size: 400,
                  ),
                ),
                Positioned(
                  top: 220 + _orbAnim.value * -28,
                  right: -100 + _orbAnim.value * 18,
                  child: _OrbGlow(
                    color: _violet
                        .withOpacity(0.10 + _pulseAnim.value * 0.03),
                    size: 300,
                  ),
                ),
              ],
            ),
          ),

          // ── Static bottom-left orb ──
          const Positioned(
            bottom: 100,
            left: -60,
            child: _OrbGlow(color: Color(0x0D22C55E), size: 240),
          ),

          // ── Particles ──
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleCtrl.value),
            ),
          ),

          // ── Noise ──
          Opacity(
            opacity: 0.022,
            child: CustomPaint(
                size: size, painter: _NoisePainter(seed: 33)),
          ),

          // ── Scroll content ──
          CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.05,
                  child: _buildQuickActions(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.12,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: WalletBalanceCard(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.20,
                  child: const _SectionLabel(title: 'Recent Transactions'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: _AnimatedReveal(
                  animation: _entryAnim,
                  delay: 0.26,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: RecentTransactions(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ],
      ),

      // ── FAB ──
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, -3 * _fabAnim.value),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _gold
                      .withOpacity(0.35 + _fabAnim.value * 0.15),
                  blurRadius: 20 + _fabAnim.value * 8,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _showFundsSheet(context);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gold, _goldBright, _goldDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded,
                    color: Color(0xFF1A1200), size: 22),
                SizedBox(width: 8),
                Text('Add Funds',
                    style: TextStyle(
                        color: Color(0xFF1A1200),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerFloat,

      bottomNavigationBar: widget.showBottomNav
          ? CommonBottomNav(
        selectedIndex:
        widget.selectedIndex ?? _selectedIndex,
        onTap: _onItemTapped,
      )
          : null,
    );
  }

  // ── AppBar ──
  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Row(
          children: [
            _AnimatedReveal(
              animation: _entryAnim,
              delay: 0.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _shimmerAnim,
                    builder: (_, child) => ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: const [_gold, _goldBright, _gold],
                        begin: Alignment(
                            -1.5 + _shimmerAnim.value * 4, 0),
                        end: Alignment(
                            -0.5 + _shimmerAnim.value * 4, 0),
                      ).createShader(b),
                      child: child!,
                    ),
                    child: const Text('Wallet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                  ),
                  Text('Manage your balance',
                      style: TextStyle(
                          color: _textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Spacer(),
            _AnimatedReveal(
              animation: _entryAnim,
              delay: 0.04,
              child: _GlassButton(
                onTap: () {},
                child: Icon(Icons.notifications_none_rounded,
                    color: Colors.white.withOpacity(0.7), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ──
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.add_rounded,
              label: 'Deposit',
              iconColor: _green,
              borderColor: _green.withOpacity(0.3),
              bgColor: _green.withOpacity(0.08),
              onTap: () {
                HapticFeedback.selectionClick();
                _showDepositSheet(context);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.arrow_upward_rounded,
              label: 'Withdraw',
              iconColor: _red,
              borderColor: _red.withOpacity(0.3),
              bgColor: _red.withOpacity(0.08),
              onTap: () {
                HapticFeedback.selectionClick();
                _showComingSoon('Withdrawal');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.history_rounded,
              label: 'History',
              iconColor: _violetLight,
              borderColor: _violetLight.withOpacity(0.3),
              bgColor: _violetLight.withOpacity(0.08),
              onTap: () => HapticFeedback.selectionClick(),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon',
            style: const TextStyle(
                color: _textPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: _cardBg2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _border)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      ),
    );
  }

  // ── Funds sheet ──
  void _showFundsSheet(BuildContext context) {
    _showDarkSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          const _SheetTitle(
              title: 'Manage Funds',
              subtitle: 'Choose an action below'),
          const SizedBox(height: 24),
          _SheetActionTile(
            icon: Icons.add_circle_rounded,
            iconColor: _green,
            iconBg: _green.withOpacity(0.1),
            title: 'Deposit',
            subtitle: 'Add money to your wallet',
            onTap: () {
              Navigator.pop(context);
              _showDepositSheet(context);
            },
          ),
          const SizedBox(height: 10),
          _SheetActionTile(
            icon: Icons.remove_circle_rounded,
            iconColor: _red,
            iconBg: _red.withOpacity(0.1),
            title: 'Withdraw',
            subtitle: 'Transfer to your bank account',
            onTap: () {
              Navigator.pop(context);
              _showComingSoon('Withdrawal');
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ── Deposit sheet ──
  void _showDepositSheet(BuildContext context) {
    if (_isLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                  color: _gold, strokeWidth: 2.5),
            ),
          ),
        ),
      );
      return;
    }

    _showDarkSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHandle(),
          const SizedBox(height: 20),
          const _SheetTitle(
              title: 'Add Money',
              subtitle: 'Select an amount to deposit'),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: _rupeeOptions.map((amount) {
              return _AmountChip(
                amount: amount,
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon('Deposit ₹$amount');
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: _gold, size: 18),
                ),
                const SizedBox(width: 14),
                const Text('Enter custom amount',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: _textMuted, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  void _showDarkSheet(
      {required BuildContext context, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ClipRRect(
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding:
              const EdgeInsets.fromLTRB(20, 0, 20, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF16132E), Color(0xFF0E0C1D)],
                ),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32)),
                // FIX: use const border instead of withOpacity on _border
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0x661E1B32)),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  QUICK ACTION BUTTON
// ═══════════════════════════════════════════════════════════════
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color borderColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.borderColor,
    required this.bgColor,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
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
          scale: 1.0 - _ctrl.value * 0.04,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child:
                Icon(widget.icon, color: widget.iconColor, size: 18),
              ),
              const SizedBox(height: 8),
              Text(widget.label,
                  style: TextStyle(
                      color: widget.iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  AMOUNT CHIP
// ═══════════════════════════════════════════════════════════════
class _AmountChip extends StatefulWidget {
  final int amount;
  final VoidCallback onTap;
  const _AmountChip({Key? key, required this.amount, required this.onTap})
      : super(key: key);

  @override
  State<_AmountChip> createState() => _AmountChipState();
}

class _AmountChipState extends State<_AmountChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.forward();
        setState(() => _selected = true);
      },
      onTapUp: (_) {
        _ctrl.reverse();
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) setState(() => _selected = false);
        });
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () {
        _ctrl.reverse();
        setState(() => _selected = false);
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _ctrl.value * 0.04,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            gradient: _selected
                ? const LinearGradient(
                colors: [_gold, _goldBright],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
                : null,
            color: _selected ? null : _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _selected ? _gold : _border,
              width: _selected ? 1.5 : 1,
            ),
            boxShadow: _selected
                ? [
              BoxShadow(
                  color: _gold.withOpacity(0.3), blurRadius: 12)
            ]
                : null,
          ),
          child: Center(
            child: Text(
              '₹${widget.amount}',
              style: TextStyle(
                color: _selected
                    ? const Color(0xFF1A1200)
                    : _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHEET HELPERS
// ═══════════════════════════════════════════════════════════════
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SheetTitle(
      {Key? key, required this.title, required this.subtitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                color: _textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SheetActionTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetActionTile({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_SheetActionTile> createState() => _SheetActionTileState();
}

class _SheetActionTileState extends State<_SheetActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
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
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
            scale: 1.0 - _ctrl.value * 0.02, child: child),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(widget.icon,
                    color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(widget.subtitle,
                        style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: _textMuted.withOpacity(0.5), size: 16),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
//  ANIMATED REVEAL — FIX: guard against delay == 1.0 (div-by-zero)
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
        final denominator = (1.0 - delay).clamp(0.001, 1.0); // prevent div/0
        final t = ((animation.value - delay) / denominator).clamp(0.0, 1.0);
        final curve = Curves.easeOutExpo.transform(t);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
              offset: Offset(0, 26 * (1 - curve)), child: child),
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
//  ORB GLOW — FIX: make const-constructible
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
//  PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════════
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
      final x =
          p.x + math.sin(t * math.pi * 2 + p.phase * 6) * 0.04;
      final fade = (1 -
          (y < 0.15 ? (0.15 - y) / 0.15 : 0)) *
          (y > 0.85 ? (1.0 - y) / 0.15 : 1);
      paint.color = (i % 3 != 0 ? _gold : _violetLight)
          .withOpacity(p.opacity * fade);
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
//  NOISE PAINTER — FIX: seed passed in, no mutable field
// ═══════════════════════════════════════════════════════════════
class _NoisePainter extends CustomPainter {
  final int seed;
  const _NoisePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed); // local, deterministic
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 1600; i++) {
      paint.color =
          Colors.white.withOpacity(rng.nextDouble() * 0.5);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width,
            rng.nextDouble() * size.height),
        rng.nextDouble() * 0.65,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_NoisePainter old) => old.seed != seed;
}