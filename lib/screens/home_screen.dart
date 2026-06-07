import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'resources_screen.dart';
import 'my_bookings_screen.dart';
import 'waitlist_screen.dart';
import 'qr_screen.dart';
import 'notifications_screen.dart';
import 'analytics_screen.dart';
import 'maintenance_screen.dart';
import 'admin_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _page = 0;
  int _unread = 0;

  final List<_NavItem> _allItems = [
    _NavItem('dashboard', Icons.dashboard_rounded, 'Dashboard', null),
    _NavItem('resources', Icons.business_rounded, 'Resources', null),
    _NavItem('my-bookings', Icons.assignment_rounded, 'My Bookings', null),
    _NavItem('qr', Icons.qr_code_scanner_rounded, 'Check-In', null),
    _NavItem(
        'notifications', Icons.notifications_rounded, 'Notifications', null),
    // Admin / More
    _NavItem('waitlist', Icons.hourglass_empty_rounded, 'Waitlist', null),
    _NavItem('analytics', Icons.bar_chart_rounded, 'Analytics',
        ['facility_manager', 'super_admin']),
    _NavItem('all-bookings', Icons.event_note_rounded, 'All Bookings',
        ['facility_manager', 'super_admin']),
    _NavItem('manage-resources', Icons.folder_shared_rounded,
        'Manage Resources', ['facility_manager', 'super_admin']),
    _NavItem('maintenance', Icons.build_circle_rounded, 'Maintenance',
        ['maintenance', 'facility_manager', 'super_admin']),
    _NavItem('users', Icons.people_alt_rounded, 'Users', ['super_admin']),
    _NavItem('audit', Icons.admin_panel_settings_rounded, 'Audit Ledger',
        ['facility_manager', 'super_admin']),
  ];

  @override
  void initState() {
    super.initState();
    _pollNotifs();
  }

  Future<void> _pollNotifs() async {
    final u = await ApiService.me();
    if (mounted && u != null) setState(() => _unread = u.unread);
    await Future.delayed(const Duration(seconds: 30));
    if (mounted) _pollNotifs();
  }

  List<_NavItem> _visibleItems(String role) {
    return _allItems.where((item) {
      if (item.roles == null) return true;
      return item.roles!.contains(role);
    }).toList();
  }

  Widget _buildPage(String id, bool active) => switch (id) {
        'dashboard' => const DashboardScreen(),
        'resources' => const ResourcesScreen(),
        'my-bookings' => const MyBookingsScreen(),
        'waitlist' => const WaitlistScreen(),
        'qr' => QrScreen(active: active),
        'notifications' => const NotificationsScreen(),
        'analytics' => const AnalyticsScreen(),
        'all-bookings' => const AllBookingsScreen(),
        'manage-resources' => const ManageResourcesScreen(),
        'maintenance' => const MaintenanceScreen(),
        'users' => const UsersScreen(),
        'audit' => const AuditScreen(),
        _ => const DashboardScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final items = _visibleItems(user.role);
    if (items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final maxI = items.length - 1;
    final pageIndex = _page.clamp(0, maxI);
    if (_page != pageIndex) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _page = pageIndex);
      });
    }
    final current = items[pageIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(current.label),
        actions: [
          badges.Badge(
            showBadge: _unread > 0,
            badgeContent: Text(
              _unread.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeStyle: const badges.BadgeStyle(badgeColor: AppTheme.red),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 24),
              onPressed: () {
                final idx = items.indexWhere((i) => i.id == 'notifications');
                if (idx >= 0) {
                  setState(() {
                    _page = idx;
                    _unread = 0;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(user, items, pageIndex),
      body: IndexedStack(
        index: pageIndex,
        children: items.asMap().entries.map((e) => _buildPage(e.value.id, pageIndex == e.key)).toList(),
      ),
      bottomNavigationBar: items.length >= 5
          ? BottomNavigationBar(
              currentIndex: pageIndex < 5 ? pageIndex : 0,
              onTap: (i) => setState(() => _page = i),
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              selectedItemColor: AppTheme.teal,
              unselectedItemColor: AppTheme.textSecondary,
              items: items
                  .take(5)
                  .map((item) => BottomNavigationBarItem(
                        icon: Icon(item.icon, size: 22),
                        label: item.label,
                      ))
                  .toList(),
            )
          : null,
    );
  }

  Widget _buildDrawer(User user, List<_NavItem> items, int pageIndex) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2540), AppTheme.bgCard],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row(
                //   children: [
                //     Container(
                //       width: 44,
                //       height: 44,
                //       decoration: BoxDecoration(
                //         color: AppTheme.teal.withValues(alpha: 0.15),
                //         borderRadius: BorderRadius.circular(12),
                //         border: Border.all(
                //             color: AppTheme.teal.withValues(alpha: 0.4)),
                //       ),
                //       child: const Center(
                //           child: Icon(Icons.account_balance_rounded,
                //               color: AppTheme.teal, size: 22)),
                //     ),
                //     const SizedBox(width: 10),
                //   ],
                // ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.teal.withValues(alpha: 0.15),
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                            color: AppTheme.teal,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Good Day 👋',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          Text(user.fullName,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.teal.withValues(alpha: 0.3)),
                            ),
                            child: Text(user.roleLabel,
                                style: const TextStyle(
                                    color: AppTheme.teal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (items.length > 5) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 16, 8),
                    child: Text('MANAGEMENT & MORE',
                        style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0)),
                  ),
                  ...items.asMap().entries.where((e) => e.key >= 5).map((e) {
                    final i = e.key;
                    final item = e.value;
                    final selected = pageIndex == i;
                    return ListTile(
                      leading: Icon(item.icon,
                          size: 22,
                          color: selected
                              ? AppTheme.teal
                              : AppTheme.textSecondary),
                      title: Text(item.label,
                          style: TextStyle(
                              color: selected
                                  ? AppTheme.teal
                                  : AppTheme.textPrimary,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _page = i);
                      },
                    );
                  }),
                ],
                const Divider(color: AppTheme.bgCardBorder),
                ListTile(
                  leading: const Icon(Icons.logout_rounded,
                      size: 22, color: AppTheme.red),
                  title: const Text('Sign Out',
                      style: TextStyle(
                          color: AppTheme.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  onTap: () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String id, label;
  final IconData icon;
  final List<String>? roles;
  _NavItem(this.id, this.icon, this.label, this.roles);
}
