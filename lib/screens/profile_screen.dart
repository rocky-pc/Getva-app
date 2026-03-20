import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../widgets/common_bottom_nav.dart';
import 'settings_screen.dart';
import 'scratch_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 2;
  String _userName = 'Lucky Winner';
  String _userEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await SessionManager.getUserName();
    final email = await SessionManager.getUserEmail();
    
    if (mounted) {
      setState(() {
        _userName = name ?? 'Lucky Winner';
        _userEmail = email ?? 'winner@example.com';
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/wallet');
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF141220),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _buildSectionHeader('General'),
              _buildListTile(Icons.history_rounded, 'Scratch History', 'View your past wins', 
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScratchHistoryScreen()),
                ),
                iconColor: const Color(0xFFD4A847),
              ),
              _buildListTile(Icons.settings_outlined, 'Settings', 'Edit profile & password', 
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              _buildListTile(Icons.help_outline_rounded, 'Help & Support', 'Get help with your account'),
              _buildListTile(Icons.info_outline_rounded, 'About', 'App version and licenses'),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: CommonBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, Color? iconColor}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white70),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white54),
      onTap: onTap,
    );
  }
}
