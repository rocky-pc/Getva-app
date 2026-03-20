import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Getva'),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle),
          tooltip: 'Profile',
          onPressed: () {
            // Navigate to profile screen
            Navigator.of(context).pushNamed('/profile');
          },
        ),
        IconButton(
          icon: const Icon(Icons.account_balance_wallet),
          tooltip: 'Wallet',
          onPressed: () {
            // Navigate to wallet screen
            Navigator.of(context).pushNamed('/wallet');
          },
        ),
      ],
    );
  }
}