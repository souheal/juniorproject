import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/volunteer_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import 'volunteer_details_screen.dart';

class VolunteerListScreen extends StatefulWidget {
  const VolunteerListScreen({super.key});

  @override
  State<VolunteerListScreen> createState() => _VolunteerListScreenState();
}

class _VolunteerListScreenState extends State<VolunteerListScreen> {
  List<VolunteerOpportunity> _opportunities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOpportunities();
  }

  Future<void> _loadOpportunities() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _opportunities = VolunteerOpportunity.getMockOpportunities();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Volunteer Opportunities',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.filter_list_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOpportunities,
        color: AppTheme.primaryColor,
        child: _isLoading
            ? _buildLoadingState()
            : _opportunities.isEmpty
                ? _buildEmptyState()
                : _buildOpportunitiesList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) => const EventCardShimmer(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        icon: Icons.volunteer_activism_outlined,
        title: 'No Opportunities Available',
        subtitle: 'There are no volunteer opportunities at the moment.\nCheck back later for new openings!',
      ),
    );
  }

  Widget _buildOpportunitiesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: _opportunities.length,
      itemBuilder: (context, index) {
        final opportunity = _opportunities[index];
        return _buildOpportunityCard(opportunity);
      },
    );
  }

  Widget _buildOpportunityCard(VolunteerOpportunity opportunity) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VolunteerDetailsScreen(opportunity: opportunity),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    opportunity.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: const Center(
                          child: Icon(Icons.volunteer_activism, size: 50, color: AppTheme.primaryColor),
                        ),
                      );
                    },
                  ),
                ),
                // Category badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      opportunity.eventCategory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Volunteers needed badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: opportunity.isUrgent ? AppTheme.warningColor : AppTheme.successColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${opportunity.spotsLeft} spots left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event name
                  Text(
                    opportunity.eventName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Role title chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opportunity.roleTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date and location
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(opportunity.eventDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          opportunity.duration,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          opportunity.venue,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
