import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

// ── Design tokens (local to this file) ──────────────────────────
const _gold        = Color(0xFFD4A847);
const _goldBright  = Color(0xFFFFE066);
const _cardBg      = Color(0xFF110F1E);
const _violet      = Color(0xFF5A3FBF);
const _violetLight = Color(0xFF8B6FE8);
const _green       = Color(0xFF22C55E);
const _red         = Color(0xFFEF4444);
const _orange      = Color(0xFFF97316);
const _textPrimary = Colors.white;
const _textMuted   = Color(0xFF6B6880);
const _border      = Color(0xFF1E1B32);

// ═══════════════════════════════════════════════════════════════
//  RECENT TRANSACTIONS  (public widget)
// ═══════════════════════════════════════════════════════════════
class RecentTransactions extends StatefulWidget {
  const RecentTransactions({Key? key}) : super(key: key);

  @override
  State<RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;
  String _activeFilter = 'All';

  static const _filters = ['All', 'deposit', 'purchase', 'reward', 'withdrawal'];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await ApiService.getRecentTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load transactions';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_activeFilter == 'All') return _transactions;
    return _transactions
        .where((t) => t['type'] == _activeFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // ── Loading skeleton ──
    if (_isLoading) {
      return Column(
        children: List.generate(
          3,
              (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TileSkeleton(),
          ),
        ),
      );
    }

    // ── Error ──
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Center(
          child: Text(_error!,
              style: const TextStyle(color: _red, fontWeight: FontWeight.w600)),
        ),
      );
    }

    // ── Empty state ──
    if (_transactions.isEmpty) {
      return _EmptyState();
    }

    // ── Filter chips ──
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter row
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final label =
                  _filters[i][0].toUpperCase() + _filters[i].substring(1);
              return _FilterChip(
                label: label,
                isActive: _activeFilter == _filters[i],
                onTap: () => setState(() => _activeFilter = _filters[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Empty filtered result
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Text('No $_activeFilter transactions',
                  style: const TextStyle(
                      color: _textMuted, fontWeight: FontWeight.w500)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final tx = filtered[index];
              final type = (tx['type'] ?? 'unknown') as String;
              final rawAmount =
                  double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
              final isPositive =
                  type == 'deposit' || type == 'reward';
              final amount = rawAmount.abs();
              final date = _formatDate(tx['date']?.toString() ?? '');

              return _TransactionTile(
                type: type,
                isPositive: isPositive,
                amount: amount,
                date: date,
                title: _getTransactionTitle(type),
                icon: _getTransactionIcon(type),
                color: _getTransactionColor(type),
                tag: _getTransactionTag(type),
              );
            },
          ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────
  String _formatDate(String raw) {
    try {
      final parts = raw.split('-');
      if (parts.length < 3) return raw;
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final m = int.tryParse(parts[1]) ?? 0;
      return '${parts[2]} ${months[m]}, ${parts[0]}';
    } catch (_) {
      return raw;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'purchase':
        return Icons.shopping_bag_rounded;
      case 'reward':
        return Icons.card_giftcard_rounded;
      case 'withdrawal':
        return Icons.arrow_circle_up_rounded;
      case 'deposit':
        return Icons.arrow_circle_down_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'purchase':
        return _orange;
      case 'reward':
        return _violetLight;
      case 'withdrawal':
        return _red;
      case 'deposit':
        return _green;
      default:
        return _textMuted;
    }
  }

  String _getTransactionTitle(String type) {
    switch (type) {
      case 'purchase':
        return 'Box Purchase';
      case 'reward':
        return 'Won Reward';
      case 'withdrawal':
        return 'Withdrawal';
      case 'deposit':
        return 'Funds Added';
      default:
        return 'Transaction';
    }
  }

  String _getTransactionTag(String type) {
    switch (type) {
      case 'purchase':
        return 'SPENT';
      case 'reward':
        return 'WON';
      case 'withdrawal':
        return 'OUT';
      case 'deposit':
        return 'IN';
      default:
        return 'TXN';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withOpacity(0.15)),
            ),
            child: const Icon(Icons.history_rounded, size: 32, color: _gold),
          ),
          const SizedBox(height: 18),
          const Text('No Transactions Yet',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Your transaction history will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _textMuted, fontSize: 12, height: 1.6)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TRANSACTION TILE
// ═══════════════════════════════════════════════════════════════
class _TransactionTile extends StatefulWidget {
  final String type;
  final bool isPositive;
  final double amount;
  final String date;
  final String title;
  final IconData icon;
  final Color color;
  final String tag;

  const _TransactionTile({
    Key? key,
    required this.type,
    required this.isPositive,
    required this.amount,
    required this.date,
    required this.title,
    required this.icon,
    required this.color,
    required this.tag,
  }) : super(key: key);

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile>
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
    final amountColor = widget.isPositive ? _green : _red;
    final amountPrefix = widget.isPositive ? '+' : '-';

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.selectionClick();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
            scale: 1.0 - _ctrl.value * 0.015, child: child),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Icon ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                  border:
                  Border.all(color: widget.color.withOpacity(0.2)),
                ),
                child:
                Icon(widget.icon, color: widget.color, size: 20),
              ),

              const SizedBox(width: 14),

              // ── Labels ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(widget.tag,
                              style: TextStyle(
                                  color: widget.color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 10,
                            color: _textMuted.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(widget.date,
                            style: TextStyle(
                                color: _textMuted.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Amount ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix₹${widget.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerRight,
                      widthFactor: widget.isPositive ? 1.0 : 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: amountColor,
                          borderRadius: BorderRadius.circular(2),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FILTER CHIP
// ═══════════════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    Key? key,
    required this.label,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
              colors: [_gold, _goldBright],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)
              : null,
          color: isActive ? null : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _gold : _border),
          boxShadow: isActive
              ? [
            BoxShadow(
                color: _gold.withOpacity(0.3), blurRadius: 8)
          ]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                color: isActive
                    ? const Color(0xFF1A1200)
                    : _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TILE SKELETON
// ═══════════════════════════════════════════════════════════════
class _TileSkeleton extends StatefulWidget {
  @override
  State<_TileSkeleton> createState() => _TileSkeletonState();
}

class _TileSkeletonState extends State<_TileSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600))
      ..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _block(double w, double h, {double radius = 8}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _block(44, 44, radius: 13),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(110, 13),
                const SizedBox(height: 8),
                _block(70, 10),
              ],
            ),
          ),
          _block(60, 16),
        ],
      ),
    );
  }
}