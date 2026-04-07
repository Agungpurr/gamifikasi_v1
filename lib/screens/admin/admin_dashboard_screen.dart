// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import 'admin_users_screen.dart';
import 'admin_questions_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        activeIcon: Icons.dashboard),
    _NavItem(
        icon: Icons.people_outline, label: 'Users', activeIcon: Icons.people),
    _NavItem(icon: Icons.quiz_outlined, label: 'Soal', activeIcon: Icons.quiz),
  ];

  final List<Widget> _screens = [
    const AdminStatsScreen(),
    const AdminUsersScreen(),
    const AdminQuestionsScreen(),
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Admin'),
        content: const Text('Yakin ingin keluar dari panel admin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // Layout untuk web/tablet (sidebar)
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 220,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header sidebar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Panel',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Gamifikasi SD',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Nav items
              ...List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final active = _selectedIndex == i;
                return InkWell(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          active ? item.activeIcon : item.icon,
                          color: active ? AppColors.primary : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color:
                                active ? AppColors.primary : Colors.grey[700],
                            fontWeight:
                                active ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const Spacer(),

              // Logout
              InkWell(
                onTap: _logout,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Text('Keluar',
                          style:
                              TextStyle(color: AppColors.error, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Content
        Expanded(child: _screens[_selectedIndex]),
      ],
    );
  }

  // Layout untuk mobile (bottom nav)
  Widget _buildNarrowLayout() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              _navItems[_selectedIndex].label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: _logout,
            tooltip: 'Keluar',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: _navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _NavItem({required this.icon, required this.activeIcon, required this.label});
}
