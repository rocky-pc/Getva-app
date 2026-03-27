import 'dart:ui';
import 'package:flutter/material.dart';

// ── Design Tokens (Consistent with the app's theme) ────────────────
const _surface     = Color(0xFF0A0910);
const _cardBg      = Color(0xFF110F1E);
const _cardBg2     = Color(0xFF16132A);
const _violet      = Color(0xFF6366F1);
const _violetLight = Color(0xFF8B6FE8);
const _textMuted   = Color(0xFF6B6880);
const _border      = Color(0xFF1E1B32);
const _green       = Color(0xFF22C55E);
const _red         = Color(0xFFEF4444);
const _gold        = Color(0xFFD4A847);

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Price Alert: TATASTEEL',
        'message': 'TATASTEEL has reached your target price of ₹160.00.',
        'time': '2 mins ago',
        'type': 'alert',
        'icon': Icons.trending_up,
        'color': _green,
      },
      {
        'title': 'Withdrawal Successful',
        'message': '₹5,000 has been successfully withdrawn to your bank account.',
        'time': '1 hour ago',
        'type': 'transaction',
        'icon': Icons.account_balance_wallet,
        'color': _violet,
      },
      {
        'title': 'New Mystery Box Available!',
        'message': 'A rare Golden Mystery Box is waiting to be opened.',
        'time': '3 hours ago',
        'type': 'promo',
        'icon': Icons.card_giftcard,
        'color': _gold,
      },
      {
        'title': 'Market Downturn Alert',
        'message': 'NIFTY 50 is down by 1.2% today. Check your portfolio.',
        'time': '5 hours ago',
        'type': 'alert',
        'icon': Icons.trending_down,
        'color': _red,
      },
      {
        'title': 'Security Login',
        'message': 'New login detected from a Chrome browser on Windows.',
        'time': 'Yesterday',
        'type': 'security',
        'icon': Icons.security,
        'color': _violetLight,
      },
    ];

    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: _GlowOrb(color: _violet.withOpacity(0.1), size: 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _GlowOrb(color: _violetLight.withOpacity(0.05), size: 250),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Text(
                    'Recent Updates',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _NotificationTile(item: item);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mark all read',
              style: TextStyle(color: _violetLight, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardBg, _cardBg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item['icon'], color: item['color'], size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item['time'],
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['message'],
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    height: 1.4,
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

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}
