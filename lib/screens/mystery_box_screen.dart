import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math';
import '../models/mystery_box.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../widgets/scratch_card_widget.dart';

class MysteryBoxScreen extends StatefulWidget {
  final MysteryBox box;

  const MysteryBoxScreen({Key? key, required this.box}) : super(key: key);

  @override
  State<MysteryBoxScreen> createState() => _MysteryBoxScreenState();
}

class _MysteryBoxScreenState extends State<MysteryBoxScreen>
    with TickerProviderStateMixin {
  final Set<int> _revealedCards = {};
  int? _userId;
  double _userBalance = 0.0;
  bool _isPurchased = false;
  int _scratchLimit = 0;
  int _usedScratches = 0;
  int _purchaseCount = 0;
  int _perPurchaseLimit = 0;

  final Map<int, double> _giftRewards = {
    1: 10.0,
    5: 25.0,
    12: 50.0,
  };

  late AnimationController _headerPulseCtrl;
  late Animation<double> _headerPulseAnim;

  @override
  void initState() {
    super.initState();
    _loadUserId();

    _headerPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _headerPulseAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _headerPulseCtrl, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserId() async {
    final userId = await SessionManager.getUserId();
    if (mounted) {
      setState(() => _userId = userId);
      if (userId != null) {
        await _loadUserBalance();

        final purchaseCount =
        await ApiService.getBoxPurchaseCount(userId, widget.box.id);
        final apiScratchLimit = await ApiService.getScratchCardLimit();

        final perPurchaseLimit =
        apiScratchLimit > 0 ? apiScratchLimit : widget.box.scratchLimit;

        setState(() {
          _purchaseCount = purchaseCount;
          _perPurchaseLimit = perPurchaseLimit;
          _scratchLimit = _purchaseCount * perPurchaseLimit;
        });

        await _loadScratchHistory();

        bool alreadyPurchased =
            widget.box.price <= 0 || purchaseCount > 0;
        if (!alreadyPurchased) {
          _showPurchaseDialog();
        } else {
          setState(() => _isPurchased = true);
        }
      }
    }
  }

  Future<void> _loadUserBalance() async {
    if (_userId == null) return;
    try {
      final balance = await ApiService.getUserWalletBalance(_userId!);
      if (mounted) setState(() => _userBalance = balance);
    } catch (e) {}
  }

  Future<void> _loadScratchHistory() async {
    if (_userId == null) return;
    try {
      final history = await ApiService.getScratchHistory(
          userId: _userId!, mysteryBoxId: widget.box.id);
      if (mounted) {
        setState(() {
          _usedScratches = history.length;
          for (var item in history) {
            _revealedCards.add(item['card_position'] as int);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usedScratches = _revealedCards.length;
        });
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PURCHASE DIALOG – redesigned for mobile
  // ──────────────────────────────────────────────────────────────────────────
  void _showPurchaseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: _PurchaseBottomSheet(
          box: widget.box,
          userBalance: _userBalance,
          purchaseCount: _purchaseCount,
          perPurchaseLimit: _perPurchaseLimit,
          onLater: () => Navigator.pop(context),
          onPurchase: () {
            Navigator.pop(context);
            _purchaseBox();
          },
        ),
      ),
    );
  }

  Future<void> _purchaseBox() async {
    if (_userId == null) return;
    try {
      final result = await ApiService.purchaseMysteryBox(
          userId: _userId!, boxId: widget.box.id, boxPrice: widget.box.price);
      if (result['success'] == true) {
        if (mounted) {
          final newPurchaseCount =
          await ApiService.getBoxPurchaseCount(_userId!, widget.box.id);
          final apiScratchLimit = await ApiService.getScratchCardLimit();
          final perPurchaseLimit =
          apiScratchLimit > 0 ? apiScratchLimit : widget.box.scratchLimit;

          setState(() {
            _isPurchased = true;
            _purchaseCount = newPurchaseCount;
            _perPurchaseLimit = perPurchaseLimit;
            _scratchLimit = _purchaseCount * perPurchaseLimit;
          });
          _loadUserBalance();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              backgroundColor: const Color(0xFF00BFA5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Purchased successfully!',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {}
  }

  void _onCardTapped(int position) {
    if (_revealedCards.contains(position)) return;

    if (_usedScratches >= _scratchLimit) {
      _showLimitReachedDialog();
      return;
    }

    final isGift = widget.box.giftPositions.contains(position);
    final reward = isGift ? (_giftRewards[position] ?? 0.0) : 0.0;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.9),
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ScratchView(
            position: position,
            isGift: isGift,
            reward: reward,
            baseColor: _getCardColor(position),
            onRevealed: () => _onCardRevealed(position, isGift, reward),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  LIMIT REACHED DIALOG – redesigned for mobile
  // ──────────────────────────────────────────────────────────────────────────
  void _showLimitReachedDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: _LimitReachedBottomSheet(
          box: widget.box,
          userBalance: _userBalance,
          usedScratches: _usedScratches,
          scratchLimit: _scratchLimit,
          perPurchaseLimit: _perPurchaseLimit,
          onLater: () => Navigator.pop(context),
          onBuyNow: () {
            Navigator.pop(context);
            _purchaseBox();
          },
        ),
      ),
    );
  }

  Color _getCardColor(int position) {
    if (position % 3 == 0) return const Color(0xFF1A73E8);
    if (position % 2 == 0) return const Color(0xFF00BFA5);
    return const Color(0xFF7C4DFF);
  }

  Future<void> _onCardRevealed(
      int position, bool isGift, double reward) async {
    if (_revealedCards.contains(position)) return;

    setState(() {
      _revealedCards.add(position);
      _usedScratches++;
    });

    await ApiService.saveScratchHistory(
      userId: _userId!,
      mysteryBoxId: widget.box.id,
      cardPosition: position,
      isGift: isGift,
      rewardAmount: reward,
    );

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.pop(context);
      _showResultDialog(position, isGift, reward);
    }
  }

  void _showResultDialog(int position, bool isGift, double reward) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, anim, _, __) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim,
            child: _ResultDialog(
                isGift: isGift,
                reward: reward,
                onContinue: () => Navigator.pop(context)),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _headerPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _HeaderBanner(
                box: widget.box,
                giftsFound: _revealedCards
                    .where((p) => widget.box.giftPositions.contains(p))
                    .length,
                totalGifts: widget.box.giftPositions.length,
                pulseAnim: _headerPulseAnim,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 15,
                  itemBuilder: (context, index) {
                    final pos = index + 1;
                    return _MysteryCard(
                      position: pos,
                      isRevealed: _revealedCards.contains(pos),
                      isGift: widget.box.giftPositions.contains(pos),
                      reward: _giftRewards[pos],
                      baseColor: _getCardColor(pos),
                      onTap: () => _onCardTapped(pos),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Mystery Rewards',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final remainingScratches = _scratchLimit - _usedScratches;
    final isLimitReached = remainingScratches <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isLimitReached
                  ? Colors.red.withOpacity(0.5)
                  : Colors.white.withOpacity(0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            label: 'SCRATCHES',
            value: '$remainingScratches / $_scratchLimit',
            icon: Icons.grid_4x4_rounded,
            highlight: isLimitReached,
          ),
          Container(width: 1, height: 30, color: Colors.white10),
          _StatChip(
            label: 'WINS',
            value:
            '${_revealedCards.where((p) => widget.box.giftPositions.contains(p)).length}',
            icon: Icons.stars_rounded,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//  PURCHASE BOTTOM SHEET
// ============================================================================
class _PurchaseBottomSheet extends StatelessWidget {
  final MysteryBox box;
  final double userBalance;
  final int purchaseCount;
  final int perPurchaseLimit;
  final VoidCallback onLater;
  final VoidCallback onPurchase;

  const _PurchaseBottomSheet({
    required this.box,
    required this.userBalance,
    required this.purchaseCount,
    required this.perPurchaseLimit,
    required this.onLater,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final bool canAfford = userBalance >= box.price;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.88),
      decoration: const BoxDecoration(
        color: Color(0xFF12111C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),

          // Glowing icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFFD4A847).withOpacity(0.35),
                    const Color(0xFFD4A847).withOpacity(0.0),
                  ]),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1B2E),
                  border: Border.all(
                      color: const Color(0xFFD4A847).withOpacity(0.6), width: 2),
                ),
                child: const Icon(Icons.redeem_rounded,
                    color: Color(0xFFD4A847), size: 30),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'Unlock Mystery Box',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            box.name,
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 28),

          // Price card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4A847).withOpacity(0.12),
                    const Color(0xFFD4A847).withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: const Color(0xFFD4A847).withOpacity(0.25), width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Box Price',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${box.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Color(0xFFD4A847),
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Your Balance',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${userBalance.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: canAfford
                                ? const Color(0xFF00BFA5)
                                : Colors.redAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Scratch info chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF00BFA5).withOpacity(0.08),
                border: Border.all(
                    color: const Color(0xFF00BFA5).withOpacity(0.25), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.grid_4x4_rounded,
                        color: Color(0xFF00BFA5), size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: perPurchaseLimit > 0
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$perPurchaseLimit Scratches Included',
                          style: const TextStyle(
                              color: Color(0xFF00BFA5),
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                        if (purchaseCount > 0)
                          Text(
                            'Purchase #${purchaseCount + 1} · ${(purchaseCount + 1) * perPurchaseLimit} total scratches',
                            style: TextStyle(
                                color:
                                Colors.white.withOpacity(0.4),
                                fontSize: 12),
                          ),
                      ],
                    )
                        : Text(
                      'Scratch limit not set by admin',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextButton(
                    onPressed: onLater,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                    ),
                    child: const Text(
                      'Later',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: ElevatedButton(
                    onPressed: canAfford ? onPurchase : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A847),
                      disabledBackgroundColor:
                      const Color(0xFFD4A847).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      canAfford ? 'Purchase Now' : 'Insufficient Balance',
                      style: TextStyle(
                          color: canAfford
                              ? const Color(0xFF1A1200)
                              : Colors.white38,
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ============================================================================
//  LIMIT REACHED BOTTOM SHEET
// ============================================================================
class _LimitReachedBottomSheet extends StatelessWidget {
  final MysteryBox box;
  final double userBalance;
  final int usedScratches;
  final int scratchLimit;
  final int perPurchaseLimit;
  final VoidCallback onLater;
  final VoidCallback onBuyNow;

  const _LimitReachedBottomSheet({
    required this.box,
    required this.userBalance,
    required this.usedScratches,
    required this.scratchLimit,
    required this.perPurchaseLimit,
    required this.onLater,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final bool canAfford = userBalance >= box.price;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.88),
      decoration: const BoxDecoration(
        color: Color(0xFF12111C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 28),

          // Lock icon with red glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.redAccent.withOpacity(0.3),
                    Colors.transparent,
                  ]),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1B2E),
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.5), width: 2),
                ),
                child: const Icon(Icons.lock_rounded,
                    color: Colors.redAccent, size: 28),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'Scratch Limit Reached',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            'All your scratch attempts have been used',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
                fontWeight: FontWeight.w400),
          ),

          const SizedBox(height: 28),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scratches Used',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$usedScratches',
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: ' / $scratchLimit',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: scratchLimit > 0
                          ? (usedScratches / scratchLimit).clamp(0.0, 1.0)
                          : 1.0,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Buy more card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4A847).withOpacity(0.10),
                    const Color(0xFFD4A847).withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: const Color(0xFFD4A847).withOpacity(0.22), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD4A847).withOpacity(0.12),
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded,
                        color: Color(0xFFD4A847), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buy Again & Unlock More',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          perPurchaseLimit > 0
                              ? '₹${box.price.toStringAsFixed(0)} · +$perPurchaseLimit scratches'
                              : 'Contact admin to set scratch limit',
                          style: TextStyle(
                              color: const Color(0xFFD4A847).withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextButton(
                    onPressed: onLater,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                    ),
                    child: const Text(
                      'Later',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: ElevatedButton(
                    onPressed: canAfford ? onBuyNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A847),
                      disabledBackgroundColor:
                      const Color(0xFFD4A847).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      canAfford ? 'Buy Now' : 'Insufficient Balance',
                      style: TextStyle(
                          color: canAfford
                              ? const Color(0xFF1A1200)
                              : Colors.white38,
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ============================================================================
//  RESULT DIALOG  (unchanged logic, refined visual)
// ============================================================================
class _ResultDialog extends StatelessWidget {
  final bool isGift;
  final double reward;
  final VoidCallback onContinue;

  const _ResultDialog(
      {required this.isGift,
        required this.reward,
        required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            decoration: BoxDecoration(
              color: const Color(0xFF12111C),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isGift
                    ? const Color(0xFFD4A847).withOpacity(0.3)
                    : Colors.white.withOpacity(0.07),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isGift
                      ? const Color(0xFFD4A847).withOpacity(0.15)
                      : Colors.black.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGift) ...[
                  // Gold glow + star
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            Colors.amber.withOpacity(0.35),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E1B2E),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.5), width: 2),
                        ),
                        child:
                        const Icon(Icons.stars, color: Colors.amber, size: 38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '🎉 Cashback Won!',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${reward.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFFD4A847),
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Added to your wallet',
                    style: TextStyle(
                        color: const Color(0xFF00BFA5).withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ] else ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E1B2E),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08), width: 1.5),
                    ),
                    child: Icon(Icons.sentiment_dissatisfied_rounded,
                        color: Colors.white.withOpacity(0.3), size: 38),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Not this time!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Better luck on the next scratch',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGift
                          ? const Color(0xFFD4A847)
                          : const Color(0xFF1A73E8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isGift ? 'AWESOME!' : 'CONTINUE',
                      style: TextStyle(
                          color: isGift
                              ? const Color(0xFF1A1200)
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  UNCHANGED WIDGETS BELOW
// ============================================================================

class _MysteryCard extends StatelessWidget {
  final int position;
  final bool isRevealed;
  final bool isGift;
  final double? reward;
  final Color baseColor;
  final VoidCallback onTap;

  const _MysteryCard(
      {required this.position,
        required this.isRevealed,
        required this.isGift,
        required this.reward,
        required this.baseColor,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'card_hero_$position',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: isRevealed
              ? _CardBack(isGift: isGift, reward: reward)
              : _CardCover(baseColor: baseColor, position: position),
        ),
      ),
    );
  }
}

class _CardCover extends StatelessWidget {
  final Color baseColor;
  final int position;

  const _CardCover({required this.baseColor, required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
          child:
          Icon(Icons.redeem_rounded, color: Colors.white54, size: 28)),
    );
  }
}

class _ScratchView extends StatelessWidget {
  final int position;
  final bool isGift;
  final double reward;
  final Color baseColor;
  final VoidCallback onRevealed;

  const _ScratchView(
      {required this.position,
        required this.isGift,
        required this.reward,
        required this.baseColor,
        required this.onRevealed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AspectRatio(
                aspectRatio: 1,
                child: Hero(
                  tag: 'card_hero_$position',
                  child: SimpleScratchCard(
                    baseColor: baseColor,
                    revealedContent:
                    _CardBack(isGift: isGift, reward: reward, isLarge: true),
                    onRevealed: onRevealed,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white54, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final bool isGift;
  final double? reward;
  final bool isLarge;

  const _CardBack(
      {required this.isGift, required this.reward, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isGift) ...[
            Icon(Icons.stars, color: Colors.amber, size: isLarge ? 48 : 24),
            SizedBox(height: isLarge ? 12 : 6),
            Text('₹${(reward ?? 0).toStringAsFixed(0)}',
                style: TextStyle(
                    color: const Color(0xFF202124),
                    fontWeight: FontWeight.w900,
                    fontSize: isLarge ? 32 : 16)),
            Text('CASHBACK',
                style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: isLarge ? 12 : 8)),
          ] else ...[
            Icon(Icons.sentiment_neutral_rounded,
                color: Colors.grey.shade300, size: isLarge ? 64 : 32),
            Text('BETTER LUCK',
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: isLarge ? 14 : 8)),
          ],
        ],
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final MysteryBox box;
  final int giftsFound;
  final int totalGifts;
  final Animation<double> pulseAnim;

  const _HeaderBanner(
      {required this.box,
        required this.giftsFound,
        required this.totalGifts,
        required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: pulseAnim,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
                colors: [Color(0xFF2D2C3D), Color(0xFF1A1A24)])),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(box.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Find all $totalGifts rewards!',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5), fontSize: 12))
                    ])),
            Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$giftsFound FOUND',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatChip(
      {required this.label,
        required this.value,
        required this.icon,
        this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: highlight ? Colors.amber : Colors.white38, size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label,
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold))
    ]);
  }
}