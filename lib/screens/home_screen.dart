import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../navigation/bottom_nav.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Use the new MainNavigation with all tabs
    return MainNavigation(
      onLogout: () {
        // Navigate back to auth screen on logout
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      },
    );
  }

  // Keep old code below for reference (not used anymore)
  int _currentNavIndex = 0;

  Widget _buildOldHome() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildSectionTitle('Categories'),
              const SizedBox(height: 12),
              _buildCategories(),
              const SizedBox(height: 24),
              _buildSectionTitle('Popular Events'),
              const SizedBox(height: 12),
              _buildPopularEvents(),
              const SizedBox(height: 24),
              _buildSectionTitle('Upcoming'),
              const SizedBox(height: 12),
              _buildUpcomingList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Fever',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D3748),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF718096)),
              const SizedBox(width: 4),
              Text(
                'London',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF718096)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search events...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF718096),
              ),
            ),
          ),
          const Icon(Icons.tune, color: Color(0xFF718096)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'Music', 'icon': Icons.music_note, 'color': const Color(0xFF6A62FF)},
      {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': const Color(0xFF4ECDC4)},
      {'name': 'Food', 'icon': Icons.restaurant, 'color': const Color(0xFFFF6B9D)},
      {'name': 'Arts', 'icon': Icons.palette, 'color': const Color(0xFFFFB74D)},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularEvents() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: const Color(0xFFCBD5E0),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event ${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF718096)),
                          const SizedBox(width: 4),
                          Text(
                            'London',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF718096),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFB74D)),
                          const SizedBox(width: 4),
                          Text(
                            '4.${9 - index}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingList() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.event,
                    color: Color(0xFF6A62FF),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Event ${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dec ${15 + index}, 2024',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: const Color(0xFF718096),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.search_outlined, Icons.search, 'Search'),
              _buildNavItem(2, Icons.favorite_outline, Icons.favorite, 'Favorites'),
              _buildNavItem(3, Icons.confirmation_number_outlined, Icons.confirmation_number, 'Tickets'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? filledIcon : outlinedIcon,
              color: isActive ? const Color(0xFF6A62FF) : const Color(0xFF718096),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? const Color(0xFF6A62FF) : const Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
