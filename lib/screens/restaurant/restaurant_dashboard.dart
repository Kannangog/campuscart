// ignore_for_file: deprecated_member_use

import 'package:campuscart/screens/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_screen.dart';
import 'menu_management_screen.dart';
import 'orders_management_screen.dart';
import 'orders_location/oders_location_screen.dart';
import 'restaurant_profile.dart';

// Provider to manage notification counts across the app
final notificationCountProvider = StateProvider<int>((ref) => 3);

class RestaurantDashboard extends ConsumerStatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  ConsumerState<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends ConsumerState<RestaurantDashboard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    const AnalyticsScreen(),
    const MenuManagementScreen(),
    const OrdersManagementScreen(),
    const OrdersLocation(),
    const RestaurantProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _animationController.reset();
      _currentIndex = index;
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationCount = ref.watch(notificationCountProvider);
    
    return Scaffold(
      appBar: _currentIndex == 4 ? null : _buildAppBar(notificationCount),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildAnimatedNavBar(notificationCount),
    );
  }

  Widget _buildAnimatedNavBar(int notificationCount) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          backgroundColor: Colors.white,
          indicatorColor: Colors.lightGreen.withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 800),
          destinations: [
            NavigationDestination(
              icon: _AnimatedNavIcon(
                index: 0,
                currentIndex: _currentIndex,
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
              ),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: _AnimatedNavIcon(
                index: 1,
                currentIndex: _currentIndex,
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu,
              ),
              label: 'Menu',
            ),
            NavigationDestination(
              icon: _BadgeNavIcon(
                index: 2,
                currentIndex: _currentIndex,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                badgeCount: notificationCount,
              ),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: _BadgeNavIcon(
                index: 3,
                currentIndex: _currentIndex,
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on,
                badgeCount: notificationCount,
              ),
              label: 'Location',
            ),
            NavigationDestination(
              icon: _AnimatedNavIcon(
                index: 4,
                currentIndex: _currentIndex,
                icon: Icons.person_outlined,
                activeIcon: Icons.person,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  AppBar? _buildAppBar(int notificationCount) {
    final Map<int, String> titles = {
      0: 'Analytics Dashboard',
      1: 'Menu Management',
      2: 'Orders Management',
      3: 'Orders Location',
    };

    return AppBar(
      title: Text(
        titles[_currentIndex] ?? '',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.lightGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(15),
        ),
      ),
      actions: [
        // Notification icon with badge (always shown except on profile screen)
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_none_rounded),
              if (notificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            ).then((_) {
              // Reset notification count when returning from notifications
              ref.read(notificationCountProvider.notifier).state = 0;
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _AnimatedNavIcon extends StatefulWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;

  const _AnimatedNavIcon({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
  });

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.lightGreen,
    ).animate(_controller);

    if (widget.index == widget.currentIndex) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == widget.currentIndex) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.index == widget.currentIndex ? widget.activeIcon : widget.icon,
        color: _colorAnimation.value,
      ),
    );
  }
}

class _BadgeNavIcon extends StatefulWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final int badgeCount;

  const _BadgeNavIcon({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.badgeCount,
  });

  @override
  State<_BadgeNavIcon> createState() => _BadgeNavIconState();
}

class _BadgeNavIconState extends State<_BadgeNavIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.lightGreen,
    ).animate(_controller);

    if (widget.index == widget.currentIndex) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _BadgeNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == widget.currentIndex) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        children: [
          Icon(
            widget.index == widget.currentIndex ? widget.activeIcon : widget.icon,
            color: _colorAnimation.value,
          ),
          if (widget.badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 247, 97, 95),
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  widget.badgeCount > 9 ? '9+' : widget.badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
        ],
      ),
    );
  }
}