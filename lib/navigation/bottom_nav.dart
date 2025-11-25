import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../screens/events/events_home_screen.dart';
import '../screens/tickets/tickets_list_screen.dart';
import '../screens/volunteer/volunteer_list_screen.dart';
import '../screens/profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainNavigation({super.key, this.onLogout});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final List<AnimationController> _animationControllers;

  @override
  void initState() {
    super.initState();
    _screens = [
      const EventsHomeScreen(),
      const TicketsListScreen(),
      const VolunteerListScreen(),
      ProfileScreen(onLogout: widget.onLogout),
    ];

    _animationControllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
    _animationControllers[0].value = 1.0;
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    HapticFeedback.selectionClick();

    // Animate out old selection
    _animationControllers[_currentIndex].reverse();
    // Animate in new selection
    _animationControllers[index].forward();

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: 'Events',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.confirmation_number_outlined,
                  activeIcon: Icons.confirmation_number,
                  label: 'Tickets',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.volunteer_activism_outlined,
                  activeIcon: Icons.volunteer_activism,
                  label: 'Volunteer',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animationControllers[index],
        builder: (context, child) {
          final progress = _animationControllers[index].value;
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 + (progress * 6),
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.transparent,
                AppTheme.primaryColor.withValues(alpha: 0.12),
                progress,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color: Color.lerp(
                      AppTheme.textSecondary,
                      AppTheme.primaryColor,
                      progress,
                    ),
                    size: 24,
                  ),
                ),
                ClipRect(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? null : 0,
                    child: Row(
                      children: [
                        SizedBox(width: isSelected ? 6 : 0),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isSelected ? 1.0 : 0.0,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
