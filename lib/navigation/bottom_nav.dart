import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../screens/events/events_home_screen.dart';
import '../screens/tickets/tickets_screen.dart';
import '../screens/volunteer/volunteer_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/organizer/organizer_dashboard_screen.dart';
import '../screens/auth_screen.dart';
import '../providers/profile_provider.dart';
import '../config.dart';

class MainNavigation extends StatefulWidget {
  final VoidCallback? onLogout;

  const MainNavigation({super.key, this.onLogout});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<Widget> _screens = [];
  List<AnimationController> _animationControllers = [];
  bool _isOrganizer = false;
  bool _isGuest = false;
  bool _isInitialized = false;
  bool _didInitialize = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[BottomNav] initState called');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize screens on first dependency change (safe to access context here)
    if (!_didInitialize) {
      _didInitialize = true;
      _initializeFromProvider();
    }
  }

  void _initializeFromProvider() {
    final provider = context.read<ProfileProvider>();
    final profile = provider.profile;
    final isOrganizer = profile?.isOrganizer ?? false;
    final isGuest = AuthHelper.isGuest;

    debugPrint('[BottomNav] _initializeFromProvider: profile=${profile != null}, isOrganizer=$isOrganizer, isGuest=$isGuest');

    _isOrganizer = isOrganizer;
    _isGuest = isGuest;
    _initializeScreens();
    _isInitialized = true;
  }

  void _updateOrganizerStatus(bool isOrganizer) {
    if (_isOrganizer != isOrganizer) {
      debugPrint('[BottomNav] Organizer status changed: $_isOrganizer -> $isOrganizer');
      setState(() {
        _isOrganizer = isOrganizer;
        _initializeScreens();
      });
    }
  }

  void _initializeScreens() {
    debugPrint('[BottomNav] _initializeScreens: isOrganizer=$_isOrganizer, isGuest=$_isGuest');

    // Dispose old controllers if any
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers = [];

    if (_isGuest) {
      // Guest mode: 3 tabs + Login button
      // Events -> Tickets -> Volunteer -> Login
      _screens = [
        const EventsHomeScreen(),
        const TicketsScreen(),
        const VolunteerListScreen(),
        const _GuestLoginPlaceholder(), // Placeholder, Login button navigates away
      ];
      _animationControllers = List.generate(
        4,
        (index) => AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        ),
      );
    } else if (_isOrganizer) {
      // 5 tabs: Events -> Tickets -> Volunteer -> Organizer -> Profile
      _screens = [
        const EventsHomeScreen(),
        const TicketsScreen(),
        const VolunteerListScreen(),
        const OrganizerDashboardScreen(),
        ProfileScreen(onLogout: widget.onLogout),
      ];
      _animationControllers = List.generate(
        5,
        (index) => AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        ),
      );
    } else {
      // 4 tabs: Events -> Tickets -> Volunteer -> Profile
      _screens = [
        const EventsHomeScreen(),
        const TicketsScreen(),
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
    }

    // Reset current index if it's out of bounds
    if (_currentIndex >= _screens.length) {
      _currentIndex = 0;
    }

    // Set initial animation state
    if (_animationControllers.isNotEmpty && _currentIndex < _animationControllers.length) {
      _animationControllers[_currentIndex].value = 1.0;
    }

    debugPrint('[BottomNav] _initializeScreens: screens=${_screens.length}, controllers=${_animationControllers.length}');
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    // For guest mode, if tapping Login button (last tab), navigate to auth screen
    if (_isGuest && index == 3) {
      HapticFeedback.selectionClick();
      _navigateToLogin();
      return;
    }

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

  void _navigateToLogin() {
    AuthHelper.exitGuestMode();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch profile changes to detect organizer status updates
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;
    final isOrganizer = profile?.isOrganizer ?? false;

    // Schedule organizer status update after build if changed
    if (_isInitialized && _isOrganizer != isOrganizer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateOrganizerStatus(isOrganizer);
        }
      });
    }

    // If not initialized yet, show loading briefly
    // (should be initialized by didChangeDependencies)
    if (!_isInitialized || _screens.isEmpty) {
      debugPrint('[BottomNav] build: not initialized yet, showing loading');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

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
                if (_isOrganizer && !_isGuest)
                  _buildNavItem(
                    index: 3,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Organizer',
                  ),
                if (_isGuest)
                  _buildNavItem(
                    index: 3,
                    icon: Icons.login_rounded,
                    activeIcon: Icons.login_rounded,
                    label: 'Login',
                  )
                else
                  _buildNavItem(
                    index: _isOrganizer ? 4 : 3,
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

/// Placeholder screen shown for guests when they tap the Login tab.
/// This shouldn't be visible as the Login button navigates away.
class _GuestLoginPlaceholder extends StatelessWidget {
  const _GuestLoginPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.login_rounded,
                color: AppTheme.primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Eventy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Log in or create an account to unlock all features',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                AuthHelper.exitGuestMode();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Log In / Sign Up',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
