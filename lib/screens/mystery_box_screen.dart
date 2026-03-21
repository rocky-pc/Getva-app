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
  int _scratchCardLimit = 5;
  bool _isPurchased = false;
  bool _isLoadingPurchase = false;
  double _userBalance = 0.0;
  bool _isLoading = true;
  bool _limitReached = false; // Track if scratch limit is reached

  Map<int, double> get _giftRewards => widget.box.giftRewards;

  late AnimationController _headerPulseCtrl;
  late Animation<double> _headerPulseAnim;
  late AnimationController _bgShimmerCtrl;
  late Animation<double> _bgShimmerAnim;
  late AnimationController _pageEnterCtrl;
  late Animation<double> _pageEnterAnim;

  final Map<int, AnimationController> _cardControllers = {};

  // Luxury color palette
  static const Color _gold = Color(0xFFD4A847);
  static const Color _goldLight = Color(0xFFE8C976);
  static const Color _darkBg = Color(0xFF080810);
  static const Color _cardBg = Color(0xFF10101C);
  static const Color _surface = Color(0xFF1A1A28);
  static const Color _surfaceLight = Color(0xFF22223A);
  static const Color _accentBlue = Color(0xFF4A7BF5);
  static const Color _accentTeal = Color(0xFF00D4AA);
  static const Color _accentPurple = Color(0xFF9B6FFF);

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadScratchCardLimit();

    _headerPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _headerPulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _headerPulseCtrl, curve: Curves.easeInOut),
    );

    _bgShimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _bgShimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgShimmerCtrl, curve: Curves.linear),
    );

    _pageEnterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _pageEnterAnim = CurvedAnimation(parent: _pageEnterCtrl, curve: Curves.easeOutCubic);

    for (int i = 1; i <= 15; i++) {
      _cardControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    }
  }

  Future<void> _refreshPurchaseStatus() async {
    if (_userId == null) return;
    try {
      final purchased = await ApiService.hasUserPurchasedBox(_userId!, widget.box.id);
      if (mounted && purchased && !_isPurchased) {
        setState(() {
          _isPurchased = true;
        });
        _showSuccessSnackBar('Box restored from previous purchase! 🎉');
      }
    } catch (e) {
      debugPrint('Error refreshing purchase status: $e');
    }
  }

  Future<void> _loadUserBalance() async {
    if (_userId == null) return;
    try {
      final balance = await ApiService.getUserWalletBalance(_userId!);
      if (mounted) setState(() => _userBalance = balance);
    } catch (e) {
      debugPrint('Error loading balance: $e');
    }
  }

  Future<void> _purchaseBox() async {
    if (_userId == null || widget.box.price <= 0) return;
    setState(() => _isLoadingPurchase = true);
    try {
      final result = await ApiService.purchaseMysteryBox(
        userId: _userId!,
        boxId: widget.box.id,
        boxPrice: widget.box.price,
      );
      
      // Debug: Print the actual response
      debugPrint('Purchase response: $result');
      
      // Check for success - handle both boolean true and string 'true'
      final isSuccess = result['success'] == true || result['success'] == 'true';
      
      if (isSuccess) {
        if (mounted) {
          setState(() {
            _isPurchased = true;
            _userBalance = double.tryParse(
                    result['new_balance']?.toString() ?? '0') ??
                0.0;
          });
          _showSuccessSnackBar('Box purchased successfully! 🎉');
        }
      } else {
        // If purchase failed but money was deducted, we have a problem
        // Check if there's an error in the response
        final errorMsg = result['error'] ?? result['message'] ?? 'Purchase failed. Please try again.';
        debugPrint('Purchase error: $errorMsg');
        if (mounted) {
          _showErrorSnackBar(errorMsg);
        }
      }
    } catch (e) {
      // If exception occurs, check if purchase might have gone through
      // by verifying the purchase status
      debugPrint('Purchase exception: $e');
      if (mounted) {
        // Try to verify purchase status
        final wasPurchased = await ApiService.hasUserPurchasedBox(_userId!, widget.box.id);
        if (wasPurchased) {
          setState(() {
            _isPurchased = true;
          });
          _showSuccessSnackBar('Box purchased successfully! 🎉');
        } else {
          _showErrorSnackBar('Something went wrong. Please try again.');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingPurchase = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF1DB954),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

void _showPurchaseDialog() {
  final bool hasBalance = _userBalance >= widget.box.price;
  showGeneralDialog(
    context: context,
    barrierDismissible: false,  // ← Change to false
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.75),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionBuilder: (ctx, anim, _, __) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: anim,
          child: _PurchaseDialog(
            box: widget.box,
            userBalance: _userBalance,
            hasBalance: hasBalance,
            isLoading: _isLoadingPurchase,
            onPurchase: () {
              Navigator.pop(ctx);
              _purchaseBox();
            },
            onCancel: () {
              Navigator.pop(ctx);         // close dialog
              Navigator.pop(context);     // ← navigate back
            },
          ),
        ),
      );
    },
  );
}

  // ─── FIX: Separate dialog for insufficient balance that navigates back properly ───
  void _showInsufficientBalanceDialog() {
    final double needed = widget.box.price - _userBalance;

    // Use WidgetsBinding to show dialog after frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: '',
        barrierColor: Colors.black.withOpacity(0.85),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const SizedBox(),
        transitionBuilder: (ctx, anim, _, __) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: FadeTransition(
              opacity: anim,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.15),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.redAccent,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        const Text(
                          'Insufficient Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.box.name,
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Balance breakdown container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Column(
                            children: [
                              _BalanceRow(
                                label: 'Box Price',
                                value: '₹${widget.box.price.toStringAsFixed(0)}',
                                valueColor: Colors.white,
                              ),
                              const SizedBox(height: 10),
                              _BalanceRow(
                                label: 'Your Balance',
                                value: '₹${_userBalance.toStringAsFixed(0)}',
                                valueColor: Colors.redAccent,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Colors.white.withOpacity(0.08),
                                  height: 1,
                                ),
                              ),
                              _BalanceRow(
                                label: 'Amount Needed',
                                value: '₹${needed.toStringAsFixed(0)}',
                                valueColor: _gold,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please add funds to your wallet to unlock this box.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop(); // close dialog
                              // Navigate back after dialog closes
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) Navigator.of(context).pop();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Go Back to Add Funds',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
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
        },
      );
    });
  }

  Future<void> _loadUserId() async {
    final userId = await SessionManager.getUserId();
    if (!mounted) return;

    setState(() => _userId = userId);

    if (userId != null) {
      await _loadUserBalance();
      await _loadScratchHistory();

      bool alreadyPurchased = false;
      
      // For free boxes, no purchase needed
      if (widget.box.price <= 0) {
        alreadyPurchased = true;
      } else {
        try {
          alreadyPurchased = await ApiService.hasUserPurchasedBox(userId, widget.box.id);
          debugPrint('hasUserPurchasedBox result for box ${widget.box.id}: $alreadyPurchased');
        } catch (e) {
          debugPrint('Error checking purchase status: $e');
          // On error, assume not purchased to be safe
          alreadyPurchased = false;
        }
      }

      if (!mounted) return;

      if (alreadyPurchased) {
        setState(() {
          _isPurchased = true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        // FIX: Check balance BEFORE showing any dialog
        if (_userBalance >= widget.box.price) {
          _showPurchaseDialog();
        } else {
          _showInsufficientBalanceDialog();
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadScratchHistory() async {
    if (_userId == null) return;
    try {
      final history = await ApiService.getScratchHistory(
          userId: _userId!, mysteryBoxId: widget.box.id);
      if (mounted && history.isNotEmpty) {
        setState(() {
          for (var item in history) {
            final pos = item['card_position'] as int;
            _revealedCards.add(pos);
            _cardControllers[pos]?.forward();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading scratch history: $e');
    }
  }

  Future<void> _loadScratchCardLimit() async {
    try {
      final limit = await ApiService.getScratchCardLimit();
      if (mounted) setState(() => _scratchCardLimit = limit);
    } catch (e) {
      debugPrint('Error loading scratch limit: $e');
    }
  }

  Future<void> _onCardRevealed(int position) async {
    if (!_isPurchased) {
      _showErrorSnackBar('Please purchase this box first!');
      return;
    }

    if (_revealedCards.length >= _scratchCardLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Scratch limit reached! Purchase a new box to continue.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE67E22),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_revealedCards.contains(position)) return;

    final isGift = widget.box.giftPositions.contains(position);
    final reward = isGift
        ? (widget.box.giftRewards[position] ?? _giftRewards[position] ?? 0.0)
        : 0.0;

    setState(() => _revealedCards.add(position));

    try {
      await ApiService.saveScratchHistory(
        userId: _userId!,
        mysteryBoxId: widget.box.id,
        cardPosition: position,
        isGift: isGift,
        rewardAmount: reward,
      );
    } catch (e) {
      debugPrint('Error saving scratch history: $e');
    }

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) _showResultDialog(position, isGift, reward);

    if (_revealedCards.length >= _scratchCardLimit) {
      setState(() => _limitReached = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _showLimitReachedDialog();
    }
  }

  void _showLimitReachedDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (ctx, anim, _, __) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: _gold.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(0.12),
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            colors: [Color(0xFF2A2200), Color(0xFF1A1200)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: _gold.withOpacity(0.4), width: 1.5),
                        ),
                        child: const Icon(Icons.celebration_rounded,
                            color: _gold, size: 34),
                      ),
                      const SizedBox(height: 20),
                      const Text('All Cards Scratched!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          children: [
                            const Text('🎉',
                                style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 8),
                            Text(
                              'You\'ve revealed all $_scratchCardLimit cards!',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Purchase a new box to get fresh cards with new reward positions.',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                              ),
                              child: const Text('Back',
                                  style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showPurchaseDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _gold,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Buy New Box',
                                  style: TextStyle(
                                      color: Color(0xFF1A1200),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResultDialog(int position, bool isGift, double reward) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (ctx, anim, _, __) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim,
            child: _ResultDialog(
                isGift: isGift,
                reward: reward,
                onContinue: () => Navigator.pop(ctx)),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _headerPulseCtrl.dispose();
    _bgShimmerCtrl.dispose();
    _pageEnterCtrl.dispose();
    for (final c in _cardControllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // Ambient background glow
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accentPurple.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _pageEnterAnim,
              child: Column(
                children: [
                  _buildTopBar(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: _HeaderBanner(
                      box: widget.box,
                      giftsFound: _revealedCards
                          .where((p) => widget.box.giftPositions.contains(p))
                          .length,
                      totalGifts: widget.box.giftPositions.length,
                      pulseAnim: _headerPulseAnim,
                      shimmerAnim: _bgShimmerAnim,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: 15,
                        itemBuilder: (context, index) {
                          final pos = index + 1;
                          // Staggered entrance
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 400 + (index * 40)),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                              );
                            },
                            child: _MysteryCard(
                              position: pos,
                              isRevealed: _revealedCards.contains(pos),
                              isGift: widget.box.giftPositions.contains(pos),
                              reward: widget.box.giftRewards[pos] ?? _giftRewards[pos],
                              onRevealed: () => _onCardRevealed(pos),
                              isLocked: !_isPurchased || _limitReached,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: _darkBg.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: _gold,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 16),
                    Text('Loading...',
                        style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _GlassButton(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
          const Expanded(
            child: Text(
              'Mystery Rewards',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          _GlassButton(
            onTap: () {
              HapticFeedback.selectionClick();
              // Info / help action
            },
            child: const Icon(Icons.info_outline_rounded,
                color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final giftsFound = _revealedCards
        .where((p) => widget.box.giftPositions.contains(p))
        .length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.grid_4x4_rounded,
              value: '${_revealedCards.length}',
              total: '$_scratchCardLimit',
              label: 'SCRATCHED',
              color: _accentBlue,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withOpacity(0.08),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.auto_awesome_rounded,
              value: '$giftsFound',
              total: '${widget.box.giftPositions.length}',
              label: 'REWARDS',
              color: _gold,
              highlight: true,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withOpacity(0.08),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.account_balance_wallet_rounded,
              value: '₹${_userBalance.toStringAsFixed(0)}',
              total: '',
              label: 'BALANCE',
              color: _accentTeal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(
            color: _accentBlue,
            label: 'Unscratched',
          ),
          const SizedBox(width: 20),
          _LegendItem(
            color: Colors.white.withOpacity(0.8),
            label: 'Revealed',
          ),
          const SizedBox(width: 20),
          _LegendItem(
            color: _gold,
            label: 'Reward',
          ),
        ],
      ),
    );
  }
}

// ─── Balance Row Helper ───
class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Purchase Dialog ───
class _PurchaseDialog extends StatelessWidget {
  final MysteryBox box;
  final double userBalance;
  final bool hasBalance;
  final bool isLoading;
  final VoidCallback onPurchase;
  final VoidCallback onCancel;

  static const Color _gold = Color(0xFFD4A847);
  static const Color _cardBg = Color(0xFF10101C);
  static const Color _surface = Color(0xFF1A1A28);

  const _PurchaseDialog({
    required this.box,
    required this.userBalance,
    required this.hasBalance,
    required this.isLoading,
    required this.onPurchase,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _gold.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFF2A2000), Color(0xFF1A1000)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold.withOpacity(0.4), width: 1.5),
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: _gold, size: 32),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unlock Mystery Box',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                box.name,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              // Price container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    Text(
                      '₹${box.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BalanceRow(
                      label: 'Your Balance',
                      value: '₹${userBalance.toStringAsFixed(0)}',
                      valueColor: hasBalance ? Colors.greenAccent : Colors.redAccent,
                    ),
                    if (!hasBalance) ...[
                      const SizedBox(height: 6),
                      _BalanceRow(
                        label: 'Required',
                        value: '₹${(box.price - userBalance).toStringAsFixed(0)} more',
                        valueColor: Colors.orange,
                        isBold: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                      child: const Text('Later',
                          style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: hasBalance && !isLoading ? onPurchase : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasBalance ? _gold : Colors.grey.shade700,
                        disabledBackgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              hasBalance ? 'Purchase Now' : 'Insufficient',
                              style: TextStyle(
                                color: hasBalance
                                    ? const Color(0xFF1A1200)
                                    : Colors.white38,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
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

// ─── Mystery Card ───
class _MysteryCard extends StatelessWidget {
  final int position;
  final bool isRevealed;
  final bool isGift;
  final double? reward;
  final VoidCallback onRevealed;
  final bool isLocked;

  static const List<List<Color>> _cardGradients = [
    [Color(0xFF1A73E8), Color(0xFF0D47A1)],
    [Color(0xFF00BFA5), Color(0xFF00695C)],
    [Color(0xFF7C4DFF), Color(0xFF4A148C)],
    [Color(0xFFFF6D00), Color(0xFFBF360C)],
    [Color(0xFF00B0FF), Color(0xFF0277BD)],
  ];

  const _MysteryCard({
    required this.position,
    required this.isRevealed,
    required this.isGift,
    required this.reward,
    required this.onRevealed,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isRevealed) {
      return _CardBack(isGift: isGift, reward: reward);
    }

    final gradientIndex = (position - 1) % _cardGradients.length;
    final gradient = _cardGradients[gradientIndex];

    return SimpleScratchCard(
      baseColor: gradient[0],
      revealedContent: _CardBack(isGift: isGift, reward: reward),
      onRevealed: onRevealed,
    );
  }
}

// ─── Card Back ───
class _CardBack extends StatelessWidget {
  final bool isGift;
  final double? reward;

  const _CardBack({required this.isGift, required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isGift ? const Color(0xFFFFFDE7) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGift
              ? const Color(0xFFD4A847).withOpacity(0.4)
              : Colors.grey.shade200,
          width: isGift ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isGift
                ? const Color(0xFFD4A847).withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: isGift ? 12 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isGift) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1),
                shape: BoxShape.circle,
              ),
              child: Image.network(
                'https://cdn-icons-png.flaticon.com/512/625/625599.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFD4A847),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '₹${(reward ?? 0).toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF1A1200),
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'CASHBACK',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w800,
                fontSize: 7.5,
                letterSpacing: 0.8,
              ),
            ),
          ] else ...[
            Icon(
              Icons.sentiment_neutral_rounded,
              color: Colors.grey.shade300,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'BETTER\nLUCK',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w700,
                fontSize: 7.5,
                letterSpacing: 0.5,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Header Banner ───
class _HeaderBanner extends StatelessWidget {
  final MysteryBox box;
  final int giftsFound;
  final int totalGifts;
  final Animation<double> pulseAnim;
  final Animation<double> shimmerAnim;

  static const Color _gold = Color(0xFFD4A847);

  const _HeaderBanner({
    required this.box,
    required this.giftsFound,
    required this.totalGifts,
    required this.pulseAnim,
    required this.shimmerAnim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalGifts > 0 ? giftsFound / totalGifts : 0.0;

    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (context, child) {
        return Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1C2E), Color(0xFF141224), Color(0xFF1A1622)],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Shimmer layer
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      final pos = shimmerAnim.value;
                      return LinearGradient(
                        begin: Alignment(-2 + pos * 4, 0),
                        end: Alignment(-1 + pos * 4, 0),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.04),
                          Colors.transparent,
                        ],
                      ).createShader(bounds);
                    },
                    child: Container(color: Colors.white),
                  ),
                ),
                // Stars decoration
                Positioned(
                  right: -10,
                  top: -10,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 90,
                    color: _gold.withOpacity(0.04),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: -15,
                  child: Icon(
                    Icons.stars_rounded,
                    size: 60,
                    color: Colors.white.withOpacity(0.02),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_rounded,
                              color: _gold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            box.name.toUpperCase(),
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scratch to Discover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _gold.withOpacity(0.3)),
                            ),
                            child: Text(
                              '$giftsFound/$totalGifts',
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

// ─── Result Dialog ───
class _ResultDialog extends StatefulWidget {
  final bool isGift;
  final double reward;
  final VoidCallback onContinue;

  const _ResultDialog({
    required this.isGift,
    required this.reward,
    required this.onContinue,
  });

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _bounceAnim = CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _bounceAnim,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: widget.isGift
                      ? const Color(0xFFD4A847).withOpacity(0.3)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isGift) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8E1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/625/625599.png',
                      width: 64,
                      height: 64,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFFD4A847),
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '🎉 Congratulations!',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You won cashback!',
                    style: TextStyle(
                      color: Color(0xFF5F6368),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${widget.reward.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF1A1200),
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Added to your wallet ✓',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      color: Colors.grey.shade400,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Not this time',
                    style: TextStyle(
                      color: Color(0xFF2D2D2D),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep scratching — a reward\nmight be just around the corner!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isGift
                          ? const Color(0xFFD4A847)
                          : const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
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

// ─── Reusable UI Components ───

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String total;
  final String label;
  final Color color;
  final bool highlight;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.total,
    required this.label,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (total.isNotEmpty)
              Text(
                '/$total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}