import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/event_api_model.dart';
import '../../models/category_api_model.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../utils/page_transitions.dart';
import 'events_api_filter_screen.dart';

class EventsHomeScreen extends StatefulWidget {
  const EventsHomeScreen({super.key});

  @override
  State<EventsHomeScreen> createState() => _EventsHomeScreenState();
}

class _EventsHomeScreenState extends State<EventsHomeScreen> with TickerProviderStateMixin {
  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Filter states
  int? _selectedCategoryId;
  String? _selectedCity;
  String? _selectedPlace;
  DateTime? _selectedDate;
  bool _liveOnly = false;
  String _searchQuery = '';

  // Data states
  List<EventApiModel> _events = [];
  List<CategoryApiModel> _categories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

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

    _loadCategories();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final response = await ApiClient.getCategories();

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final categories = jsonList
            .map((json) => CategoryApiModel.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            _categories = categories;
            _isLoadingCategories = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingCategories = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _loadEvents({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _currentPage >= _totalPages) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    }

    try {
      final response = await ApiClient.browseEvents(
        categoryId: _selectedCategoryId,
        city: _selectedCity,
        place: _selectedPlace,
        date: _selectedDate?.toIso8601String().split('T')[0],
        liveOnly: _liveOnly,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: loadMore ? _currentPage + 1 : 1,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> eventsJson = data['data'] as List<dynamic>;
        final events = eventsJson
            .map((json) => EventApiModel.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            if (loadMore) {
              _events.addAll(events);
              _currentPage++;
              _isLoadingMore = false;
            } else {
              _events = events;
              _isLoading = false;
            }

            // Extract pagination info
            _currentPage = data['current_page'] as int;
            _totalPages = data['last_page'] as int;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            if (loadMore) {
              _isLoadingMore = false;
            } else {
              _isLoading = false;
              _errorMessage = 'Failed to load events. Status: ${response.statusCode}';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (loadMore) {
            _isLoadingMore = false;
          } else {
            _isLoading = false;
            _errorMessage = 'Connection error: ${e.toString()}';
          }
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadEvents();
  }

  void _openFilterScreen() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      SlidePageRoute(
        page: EventsApiFilterScreen(
          categories: _categories,
          selectedCategoryId: _selectedCategoryId,
          selectedCity: _selectedCity,
          selectedPlace: _selectedPlace,
          selectedDate: _selectedDate,
          liveOnly: _liveOnly,
          onApplyFilters: ({categoryId, city, place, date, required liveOnly}) {
            setState(() {
              _selectedCategoryId = categoryId;
              _selectedCity = city;
              _selectedPlace = place;
              _selectedDate = date;
              _liveOnly = liveOnly;
            });
            _loadEvents();
          },
        ),
        direction: SlideDirection.up,
      ),
    );
  }

  void _clearFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategoryId = null;
      _selectedCity = null;
      _selectedPlace = null;
      _selectedDate = null;
      _liveOnly = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadEvents();
  }

  void _onSearchChanged(String query) {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query && mounted) {
        setState(() => _searchQuery = query);
        _loadEvents();
      }
    });
  }

  void _selectCategory(int? categoryId) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategoryId = categoryId);
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
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
                child: _isLoadingCategories
                    ? _buildCategoryShimmer()
                    : _buildCategories(),
              ),

              // Active Filters Summary
              if (_hasActiveFilters()) _buildActiveFiltersSummary(),

              // All Events Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (!_isLoading && _events.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_events.length} events',
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

              // Load More Button
              if (_currentPage < _totalPages && !_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _isLoadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: () => _loadEvents(loadMore: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Load More Events',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),

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
    final hasActiveFilters = _selectedCategoryId != null ||
        _selectedCity != null ||
        _selectedPlace != null ||
        _selectedDate != null ||
        _liveOnly;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openFilterScreen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasActiveFilters
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: hasActiveFilters ? Colors.white : AppTheme.primaryColor,
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
        onChanged: _onSearchChanged,
        onTap: () => setState(() {}),
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search events, venues, cities...',
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
                    _onSearchChanged('');
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
    final allCategories = [
      CategoryApiModel(id: 0, name: 'All'),
      ..._categories,
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = (_selectedCategoryId == null && category.id == 0) ||
              _selectedCategoryId == category.id;

          return GestureDetector(
            onTap: () => _selectCategory(category.id == 0 ? null : category.id),
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
                category.name,
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

  bool _hasActiveFilters() {
    return _selectedCity != null ||
        _selectedPlace != null ||
        _selectedDate != null ||
        _liveOnly;
  }

  Widget _buildActiveFiltersSummary() {
    final filters = <String>[];
    if (_selectedCity != null) filters.add('City: $_selectedCity');
    if (_selectedPlace != null) filters.add('Place: $_selectedPlace');
    if (_selectedDate != null) {
      filters.add('Date: ${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}');
    }
    if (_liveOnly) filters.add('Live only');

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filters.map((filter) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
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

    if (_errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEvents,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: NoEventsEmpty(
          onRefresh: _clearFilters,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = _events[index];
            return _buildEventCard(event);
          },
          childCount: _events.length,
        ),
      ),
    );
  }

  Widget _buildEventCard(EventApiModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          if (event.picture != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                event.fullImageUrl ?? '',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.event,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  );
                },
              ),
            ),

          // Event Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Badge + Live Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.primaryCategory,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    if (event.isEventLive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: AppTheme.successColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Event Title
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Organizer
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.organizer.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date & Time
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.formattedDate} • ${event.formattedTime}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.place,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${event.venueDisplay}, ${event.city}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price
                Text(
                  '\$${event.displayPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
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
