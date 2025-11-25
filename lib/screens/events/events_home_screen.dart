import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/event_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../utils/page_transitions.dart';
import 'event_details_screen.dart';
import 'events_filter_screen.dart';

class EventsHomeScreen extends StatefulWidget {
  const EventsHomeScreen({super.key});

  @override
  State<EventsHomeScreen> createState() => _EventsHomeScreenState();
}

class _EventsHomeScreenState extends State<EventsHomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedCategory = 'All';
  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;

  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    _headerAnimationController.forward();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    // Simulate network delay for realistic UX
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _events = EventModel.getMockEvents();
        _filteredEvents = _events;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadEvents();
  }

  void _filterEvents(String query) {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == query && mounted) {
        setState(() {
          _filteredEvents = _events.where((event) {
            final matchesSearch = event.title.toLowerCase().contains(query.toLowerCase()) ||
                event.location.toLowerCase().contains(query.toLowerCase()) ||
                event.category.toLowerCase().contains(query.toLowerCase());
            final matchesCategory = _selectedCategory == 'All' || event.category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();
        });
      }
    });
  }

  void _selectCategory(String category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
      _filterEvents(_searchController.text);
    });
  }

  void _navigateToEventDetails(EventModel event) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      SlidePageRoute(page: EventDetailsScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featuredEvents = _events.where((e) => e.isFeatured).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryColor,
          backgroundColor: Colors.white,
          displacement: 40,
          strokeWidth: 3,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Animated Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.2),
                      end: Offset.zero,
                    ).animate(_headerAnimation),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Discover Events',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.successColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Find amazing events near you',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              _buildFilterButton(),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSearchBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: _isLoading
                    ? _buildCategoryShimmer()
                    : _buildCategories(),
              ),

              // Featured Events
              if (!_isLoading && featuredEvents.isNotEmpty && _selectedCategory == 'All') ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Featured Events', onSeeAll: () {}),
                ),
                SliverToBoxAdapter(
                  child: _buildFeaturedEvents(featuredEvents),
                ),
              ],

              // All Events Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == 'All' ? 'All Events' : '$_selectedCategory Events',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (!_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredEvents.length} events',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Events List
              _buildEventsList(),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            SlidePageRoute(
              page: EventsFilterScreen(
                selectedCategory: _selectedCategory,
                onCategorySelected: _selectCategory,
              ),
              direction: SlideDirection.up,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _searchFocusNode.hasFocus
                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: _searchFocusNode.hasFocus ? 15 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? AppTheme.primaryColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _filterEvents,
        onTap: () => setState(() {}),
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search events, venues, artists...',
          hintStyle: TextStyle(color: AppTheme.textLight.withValues(alpha: 0.7)),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: _searchFocusNode.hasFocus ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _searchController.clear();
                    _filterEvents('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryShimmer() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        itemBuilder: (context, index) => const CategoryChipShimmer(),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: EventModel.getCategories().length,
        itemBuilder: (context, index) {
          final category = EventModel.getCategories()[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => _selectCategory(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppTheme.textLight.withValues(alpha: 0.3),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Row(
                children: [
                  Text('See All'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedEvents(List<EventModel> featuredEvents) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: featuredEvents.length,
        itemBuilder: (context, index) {
          return Hero(
            tag: 'event_${featuredEvents[index].id}',
            child: EventCard(
              event: featuredEvents[index],
              isCompact: true,
              onTap: () => _navigateToEventDetails(featuredEvents[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsList() {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const EventCardShimmer(),
            childCount: 3,
          ),
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _searchController.text.isNotEmpty
            ? NoSearchResults(
                searchQuery: _searchController.text,
                onClear: () {
                  _searchController.clear();
                  _filterEvents('');
                  setState(() {});
                },
              )
            : NoEventsEmpty(
                onRefresh: () {
                  _selectCategory('All');
                },
              ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Hero(
              tag: 'event_list_${_filteredEvents[index].id}',
              child: EventCard(
                event: _filteredEvents[index],
                onTap: () => _navigateToEventDetails(_filteredEvents[index]),
              ),
            );
          },
          childCount: _filteredEvents.length,
        ),
      ),
    );
  }
}
