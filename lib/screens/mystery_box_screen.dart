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
  int _scratchLimit = 5; // Total scratch limit available
  int _usedScratches = 0; // Number of scratches used

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

    // Initialize scratch limit from box settings
    _scratchLimit = widget.box.scratchLimit;

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
        await _loadScratchHistory();
        bool alreadyPurchased = widget.box.price <= 0 || await ApiService.hasUserPurchasedBox(userId, widget.box.id);
        if (!alreadyPurchased) _showPurchaseDialog(); else setState(() => _isPurchased = true);
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
      // First, try to get scratch limit from API settings
      final apiScratchLimit = await ApiService.getScratchCardLimit();
      
      final history = await ApiService.getScratchHistory(userId: _userId!, mysteryBoxId: widget.box.id);
      if (mounted) {
        setState(() {
          // Use API scratch limit if available, otherwise use box setting
          _scratchLimit = apiScratchLimit > 0 ? apiScratchLimit : widget.box.scratchLimit;
          _usedScratches = history.length; // Track how many scratches have been used
          for (var item in history) {
            _revealedCards.add(item['card_position'] as int);
          }
        });
      }
    } catch (e) {
      // On error, use box setting
      if (mounted) {
        setState(() {
          _scratchLimit = widget.box.scratchLimit;
          _usedScratches = _revealedCards.length;
        });
      }
    }
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Strict: User cannot dismiss by tapping outside
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AlertDialog(
          backgroundColor: const Color(0xFF141220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.redeem_rounded, color: Color(0xFFD4A847), size: 28),
              SizedBox(width: 12),
              Text('Unlock Mystery Box', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text(widget.box.name, style: const TextStyle(color: Color(0xFFD4A847), fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text('₹${widget.box.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00BFA5).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_4x4_rounded, color: Color(0xFF00BFA5), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.box.scratchLimit} Scratch Attempts',
                      style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: _userBalance >= widget.box.price
                  ? () {
                      Navigator.pop(context);
                      _purchaseBox();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A847),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _userBalance >= widget.box.price ? 'Purchase' : 'Insufficient Balance',
                style: const TextStyle(color: Color(0xFF1A1200), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseBox() async {
    if (_userId == null) return;
    try {
      final result = await ApiService.purchaseMysteryBox(userId: _userId!, boxId: widget.box.id, boxPrice: widget.box.price);
      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            _isPurchased = true;
            // Extend scratch limit by box's scratch limit (e.g., +5 scratches)
            _scratchLimit = _scratchLimit + widget.box.scratchLimit;
          });
          _loadUserBalance();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchased successfully! +${widget.box.scratchLimit} scratches added'),
              backgroundColor: const Color(0xFF00BFA5),
            ),
          );
        }
      }
    } catch (e) {}
  }

  void _onCardTapped(int position) {
    if (_revealedCards.contains(position)) return;

    // Check if scratch limit is reached
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

  // Show strict popup when scratch limit is reached
  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Strict: User cannot dismiss by tapping outside
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AlertDialog(
          backgroundColor: const Color(0xFF141220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Color(0xFFD4A847), size: 28),
              SizedBox(width: 12),
              Text('Scratch Limit Reached', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'You have used all your scratch attempts!',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Remaining: ',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        Text(
                          '$_usedScratches / $_scratchLimit',
                          style: const TextStyle(color: Color(0xFFD4A847), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Buy again to get more scratches!',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${widget.box.price.toStringAsFixed(0)} + $_scratchLimit scratches',
                      style: const TextStyle(color: Color(0xFFD4A847), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Still cannot dismiss easily
              child: const Text('Later', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: _userBalance >= widget.box.price
                  ? () {
                      Navigator.pop(context);
                      _purchaseBox();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A847),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _userBalance >= widget.box.price ? 'Buy Now' : 'Insufficient Balance',
                style: const TextStyle(color: Color(0xFF1A1200), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(int position) {
    if (position % 3 == 0) return const Color(0xFF1A73E8);
    if (position % 2 == 0) return const Color(0xFF00BFA5);
    return const Color(0xFF7C4DFF);
  }

  Future<void> _onCardRevealed(int position, bool isGift, double reward) async {
    if (_revealedCards.contains(position)) return;
    
    setState(() {
      _revealedCards.add(position);
      _usedScratches++; // Increment used scratches
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
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, anim, _, __) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim,
            child: _ResultDialog(isGift: isGift, reward: reward, onContinue: () => Navigator.pop(context)),
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
                giftsFound: _revealedCards.where((p) => widget.box.giftPositions.contains(p)).length,
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Mystery Rewards', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
        border: Border.all(color: isLimitReached ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.05))
      ),
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
            value: '${_revealedCards.where((p) => widget.box.giftPositions.contains(p)).length}', 
            icon: Icons.stars_rounded, 
            highlight: true
          ),
        ],
      ),
    );
  }
}

class _MysteryCard extends StatelessWidget {
  final int position;
  final bool isRevealed;
  final bool isGift;
  final double? reward;
  final Color baseColor;
  final VoidCallback onTap;

  const _MysteryCard({required this.position, required this.isRevealed, required this.isGift, required this.reward, required this.baseColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'card_hero_$position',
      // Add Material here for Hero stability
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
      child: const Center(child: Icon(Icons.redeem_rounded, color: Colors.white54, size: 28)),
    );
  }
}

class _ScratchView extends StatelessWidget {
  final int position;
  final bool isGift;
  final double reward;
  final Color baseColor;
  final VoidCallback onRevealed;

  const _ScratchView({required this.position, required this.isGift, required this.reward, required this.baseColor, required this.onRevealed});

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
                    revealedContent: _CardBack(isGift: isGift, reward: reward, isLarge: true),
                    onRevealed: onRevealed,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 32),
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

  const _CardBack({required this.isGift, required this.reward, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isGift) ...[
            Icon(Icons.stars, color: Colors.amber, size: isLarge ? 48 : 24),
            SizedBox(height: isLarge ? 12 : 6),
            Text('₹${(reward ?? 0).toStringAsFixed(0)}', style: TextStyle(color: const Color(0xFF202124), fontWeight: FontWeight.w900, fontSize: isLarge ? 32 : 16)),
            Text('CASHBACK', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: isLarge ? 12 : 8)),
          ] else ...[
            Icon(Icons.sentiment_neutral_rounded, color: Colors.grey.shade300, size: isLarge ? 64 : 32),
            Text('BETTER LUCK', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: isLarge ? 14 : 8)),
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

  const _HeaderBanner({required this.box, required this.giftsFound, required this.totalGifts, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: pulseAnim,
      child: Container(
        height: 100,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF2D2C3D), Color(0xFF1A1A24)])),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(box.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text('Find all $totalGifts rewards!', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('$giftsFound FOUND', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12))),
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

  const _StatChip({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Icon(icon, color: highlight ? Colors.amber : Colors.white38, size: 20), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))]);
  }
}

class _ResultDialog extends StatelessWidget {
  final bool isGift;
  final double reward;
  final VoidCallback onContinue;

  const _ResultDialog({required this.isGift, required this.reward, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isGift) ...[
                const Icon(Icons.stars, color: Colors.amber, size: 80),
                const SizedBox(height: 24),
                const Text('Cashback won!', style: TextStyle(color: Color(0xFF5F6368), fontSize: 18, fontWeight: FontWeight.w500)),
                Text('₹${reward.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF202124), fontSize: 48, fontWeight: FontWeight.w900)),
              ] else ...[
                const Icon(Icons.sentiment_dissatisfied_rounded, color: Colors.grey, size: 80),
                const SizedBox(height: 24),
                const Text('Better luck next time', style: TextStyle(color: Color(0xFF5F6368), fontSize: 20, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onContinue, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('CONTINUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }
}
