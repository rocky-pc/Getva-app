import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

// ── Design tokens ────────────────────────────────────────────────
const _gold        = Color(0xFFD4A847);
const _goldBright  = Color(0xFFFFE066);
const _violetLight = Color(0xFF8B6FE8);
const _green       = Color(0xFF22C55E);
const _red         = Color(0xFFEF4444);
const _border      = Color(0xFF1E1B32);

// ═══════════════════════════════════════════════════════════════
//  WALLET BALANCE CARD
// ═══════════════════════════════════════════════════════════════
class WalletBalanceCard extends StatefulWidget {
  const WalletBalanceCard({Key? key}) : super(key: key);

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard>
    with TickerProviderStateMixin {
  double _balance        = 0.0;
  double _displayBalance = 0.0;
  bool   _isLoading      = true;
  bool   _balanceVisible = true;

  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _countCtrl;

  late Animation<double> _shimmerAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _orbAnim;

  @override
  void initState() {
    super.initState();

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear),
    );

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _countCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _countCtrl.addListener(() {
      if (mounted) {
        setState(() =>
        _displayBalance = Curves.easeOutExpo.transform(_countCtrl.value) * _balance);
      }
    });

    _loadWalletBalance();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWalletBalance() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _displayBalance = 0; });
    try {
      final balance = await ApiService.getWalletBalance();
      if (mounted) {
        setState(() { _balance = balance; _isLoading = false; });
        _countCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerAnim, _pulseAnim, _orbAnim]),
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.10 + _pulseAnim.value * 0.06),
                blurRadius: 36 + _pulseAnim.value * 12,
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
                // ── Base gradient (Wrapped in Positioned.fill to avoid infinite size) ──
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFF1C1735),
                              const Color(0xFF221A45), _pulseAnim.value)!,
                          const Color(0xFF13102A),
                          const Color(0xFF0E0C1C),
                        ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
                  ),
                ),

                // ── Gold orb top-right ──
                Positioned(
                  top: -50 + _orbAnim.value * 18,
                  right: -40 + _orbAnim.value * 12,
                  child: Container(
                    width: 190, height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _gold.withOpacity(0.13 + _pulseAnim.value * 0.05),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),

                // ── Violet orb bottom-left ──
                Positioned(
                  bottom: -30 + _orbAnim.value * -10,
                  left: -20,
                  child: Container(
                    width: 130, height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _violetLight.withOpacity(0.1),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),

                // ── Shimmer sweep ──
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-2 + _shimmerAnim.value * 4.5, -1),
                        end: Alignment(-1.5 + _shimmerAnim.value * 4.5, 1),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Grid (Wrapped in Positioned.fill to fix size.isFinite error) ──
                Positioned.fill(
                  child: CustomPaint(
                      painter: _CardGridPainter(), child: const SizedBox.expand()),
                ),

                // ── Border (Wrapped in Positioned.fill) ──
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Color.lerp(
                            _border, _gold.withOpacity(0.35), _pulseAnim.value)!,
                      ),
                    ),
                  ),
                ),

                // ── Content (Determines the Stack's size) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopRow(),
                      const SizedBox(height: 18),
                      _buildBalanceRow(),
                      const SizedBox(height: 4),
                      _buildSubtitle(),
                      const SizedBox(height: 22),

                      // ── Divider ──
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            _gold.withOpacity(0.15),
                            Colors.transparent,
                          ]),
                        ),
                      ),

                      // ── Action strip ──
                      _buildActionStrip(),
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

  // ... rest of the widget methods remain the same ...

  Widget _buildTopRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: _green, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _green, blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 6),
              const Text('GETVA Wallet',
                  style: TextStyle(
                      color: _gold, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _balanceVisible = !_balanceVisible);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(
              _balanceVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withOpacity(0.5), size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ShaderMask(
            shaderCallback: (b) =>
                const LinearGradient(colors: [_gold, _goldBright]).createShader(b),
            child: const Text('₹',
                style: TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 4),
        _isLoading
            ? Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _SkeletonPulse(width: 140, height: 46),
        )
            : AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _balanceVisible
              ? ShaderMask(
            key: const ValueKey('v'),
            shaderCallback: (b) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE8E0FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(b),
            child: Text(
              _displayBalance.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44, fontWeight: FontWeight.w900,
                letterSpacing: -1.5, height: 1.0,
              ),
            ),
          )
              : const Text('••••••',
              key: ValueKey('h'),
              style: TextStyle(
                color: Colors.white54, fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 4, height: 1.0,
              )),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text('Total Balance',
        style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5));
  }

  Widget _buildActionStrip() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.add_rounded,
              label: 'Add Money',
              color: _green,
              onTap: () {},
            ),
          ),
          _StripDivider(),
          Expanded(
            child: _ActionButton(
              icon: Icons.arrow_circle_up_rounded,
              label: 'Withdraw',
              color: _red,
              onTap: () {},
            ),
          ),
          _StripDivider(),
          Expanded(
            child: _ActionButton(
              icon: Icons.refresh_rounded,
              label: 'Refresh',
              color: _violetLight,
              onTap: _loadWalletBalance,
            ),
          ),
        ],
      ),
    );
  }
}

// Keeping the rest of the private helper classes (_ActionButton, _StripDivider, etc.)
// from the original file...

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { _ctrl.forward(); setState(() => _pressed = true); },
      onTapUp: (_) {
        _ctrl.reverse();
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () { _ctrl.reverse(); setState(() => _pressed = false); },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _ctrl.value * 0.06, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _pressed
              ? widget.color.withOpacity(0.06)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withOpacity(0.28)),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.07),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _SkeletonPulse extends StatefulWidget {
  final double width;
  final double height;
  const _SkeletonPulse({Key? key, required this.width, required this.height})
      : super(key: key);

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _anim.value * 4, 0),
            end: Alignment(-0.5 + _anim.value * 4, 0),
            colors: const [
              Color(0xFF1E1A35),
              Color(0xFF2E2850),
              Color(0xFF1E1A35),
            ],
          ),
        ),
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
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final arcPaint = Paint()
      ..color = _gold.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width, 0), radius: 80),
      math.pi / 2, math.pi / 2, false, arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, 0), radius: 60),
      0, math.pi / 2, false, arcPaint,
    );
  }

  @override
  bool shouldRepaint(_CardGridPainter _) => false;
}
