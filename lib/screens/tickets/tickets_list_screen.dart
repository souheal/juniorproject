import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/my_ticket_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/my_ticket_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../utils/page_transitions.dart';
import 'ticket_details_screen.dart';
import 'ticket_request_screen.dart';

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> with SingleTickerProviderStateMixin {
  List<MyTicketModel> _tickets = [];
  bool _isLoading = true;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadTickets();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _tickets = MyTicketModel.getMockTickets();
        _isLoading = false;
      });
      _fabAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Tickets',
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
        onRefresh: _loadTickets,
        color: AppTheme.primaryColor,
        child: _isLoading
            ? _buildLoadingState()
            : _tickets.isEmpty
                ? _buildEmptyState()
                : _buildTicketsList(),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              SlidePageRoute(
                page: const TicketRequestScreen(),
                direction: SlideDirection.up,
              ),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Add Ticket',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  child: const TicketCardShimmer(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(4, (index) => const TicketCardShimmer()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: NoTicketsEmpty(),
    );
  }

  Widget _buildTicketsList() {
    final pending = _tickets.where((t) => t.isPending).toList();
    final processed = _tickets.where((t) => !t.isPending).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(pending.length),
          const SizedBox(height: 28),

          if (pending.isNotEmpty) ...[
            _buildSectionHeader('Pending', pending.length, AppTheme.pendingColor),
            const SizedBox(height: 16),
            ...pending.map((ticket) => _buildTicketItem(ticket)),
            const SizedBox(height: 24),
          ],

          if (processed.isNotEmpty) ...[
            _buildSectionHeader('Processed', processed.length, AppTheme.textSecondary),
            const SizedBox(height: 16),
            ...processed.map((ticket) => _buildTicketItem(ticket)),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSummarySection(int pendingCount) {
    final approvedCount = _tickets.where((t) => t.isApproved).length;
    final rejectedCount = _tickets.where((t) => t.isRejected).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_tickets.length} total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAnimatedSummaryCard(
                  'Pending',
                  pendingCount,
                  AppTheme.pendingColor,
                  Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnimatedSummaryCard(
                  'Approved',
                  approvedCount,
                  AppTheme.successColor,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnimatedSummaryCard(
                  'Rejected',
                  rejectedCount,
                  AppTheme.errorColor,
                  Icons.cancel_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSummaryCard(String title, int count, Color color, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: count.toDouble()),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
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
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketItem(MyTicketModel ticket) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MyTicketCard(
        ticket: ticket,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            SlidePageRoute(
              page: TicketDetailsScreen(ticket: ticket),
            ),
          );
        },
      ),
    );
  }
}
