import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════
const _gold       = Color(0xFFD4A847);
const _goldBright = Color(0xFFFFE066);
const _surface    = Color(0xFF0A0910);
const _cardBg     = Color(0xFF110F1E);
const _border     = Color(0xFF1E1B32);
const _violet     = Color(0xFF5A3FBF);

// ═══════════════════════════════════════════════════════════════
//  COMMON BOTTOM NAV
// ═══════════════════════════════════════════════════════════════
class CommonBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CommonBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  void _onItemTap(int index) {
    HapticFeedback.selectionClick();
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _cardBg.withOpacity(0.85),
                _surface.withOpacity(0.95),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: _border.withOpacity(0.8),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
              BoxShadow(
                color: _gold.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    outlinedIcon: Icons.home_outlined,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    onTap: () => _onItemTap(0),
                  ),
                  _NavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    outlinedIcon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onItemTap(1),
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    outlinedIcon: Icons.person_outline_rounded,
                    label: 'Profile',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onItemTap(2),
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
//  NAV ITEM
// ═══════════════════════════════════════════════════════════════
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon container ──
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow halo (static, no animation)
                if (isSelected)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _gold.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                // Pill background (no animation)
                Container(
                  width: isSelected ? 56 : 44,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      colors: [
                        _gold.withOpacity(0.18),
                        _gold.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? Border.all(
                      color: _gold.withOpacity(0.3),
                      width: 1,
                    )
                        : null,
                  ),
                ),

                // Icon (no animation)
                isSelected
                    ? Icon(
                  icon,
                  color: _gold,
                  size: 22,
                )
                    : Icon(
                  outlinedIcon,
                  color: Colors.white.withOpacity(0.35),
                  size: 22,
                ),
              ],
            ),

            const SizedBox(height: 5),

            // ── Label (no animation) ──
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? _gold
                    : Colors.white.withOpacity(0.35),
                fontSize: isSelected ? 11.5 : 11,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
            ),

            // ── Active dot (no animation) ──
            const SizedBox(height: 4),
            Container(
              width: isSelected ? 16 : 0,
              height: isSelected ? 3 : 0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, _goldBright],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(isSelected ? 0.6 : 0),
                    blurRadius: isSelected ? 6 : 0,
                    offset: const Offset(0, 1),
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