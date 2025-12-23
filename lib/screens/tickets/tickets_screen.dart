import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/ticket_dto.dart';
import '../../services/tickets_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/login_prompt.dart';
import '../../config.dart';

/// Main Tickets Screen with tabs for My Tickets and Scan Ticket (organizer).
///
/// Features:
/// - Display user's tickets from GET /api/my-tickets
/// - Show QR code for each ticket
/// - Buy ticket functionality via POST /api/events/{event}/checkout
/// - Scan ticket for organizers via POST /api/organizer/tickets/scan
class TicketsScreen extends StatefulWidget {
  /// Whether the current user is an organizer (enables scan tab)
  final bool isOrganizer;

  const TicketsScreen({
    super.key,
    this.isOrganizer = false,
  });

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // My Tickets state
  List<TicketDto> _tickets = [];
  bool _isLoadingTickets = true;
  String? _ticketsError;

  // Buy Ticket state
  List<EventForPurchase> _availableEvents = [];
  bool _isLoadingEvents = false;
  EventForPurchase? _selectedEvent;
  bool _isProcessingCheckout = false;

  // Scan state
  bool _isScanning = false;
  ScanResult? _lastScanResult;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isOrganizer ? 2 : 1,
      vsync: this,
    );
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    // For guest users, don't try to load tickets - show empty state
    if (AuthHelper.isGuest) {
      setState(() {
        _tickets = [];
        _isLoadingTickets = false;
      });
      return;
    }

    setState(() {
      _isLoadingTickets = true;
      _ticketsError = null;
    });

    try {
      final tickets = await TicketsApiService.getMyTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoadingTickets = false;
        });
      }
    } on TicketApiException catch (e) {
      if (mounted) {
        setState(() {
          _ticketsError = e.message;
          _isLoadingTickets = false;
        });
      }
    }
  }

  Future<void> _loadAvailableEvents() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final events = await TicketsApiService.getAvailableEvents();
      if (mounted) {
        setState(() {
          _availableEvents = events;
          _isLoadingEvents = false;
        });
      }
    } on TicketApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
        });
        _showSnackBar(e.message, isError: true);
      }
    }
  }

  Future<void> _initiateCheckout(int eventId) async {
    setState(() {
      _isProcessingCheckout = true;
    });

    try {
      final session = await TicketsApiService.createCheckoutForEvent(eventId);

      // Open Stripe checkout URL
      final uri = Uri.parse(session.checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          _showSnackBar(
            'Complete payment in browser, then refresh tickets',
            isError: false,
          );
        }
      } else {
        throw TicketApiException(
          'Could not open payment page',
          statusCode: 0,
        );
      }
    } on TicketApiException catch (e) {
      if (mounted) {
        _showSnackBar(e.message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingCheckout = false;
          _selectedEvent = null;
        });
      }
    }
  }

  Future<void> _scanQrCode(String qrCode) async {
    // Prevent multiple scans
    if (!_isScanning) return;

    setState(() {
      _isScanning = false;
    });

    _scannerController?.stop();

    try {
      final result = await TicketsApiService.scanTicket(qrCode);

      if (mounted) {
        setState(() {
          _lastScanResult = result;
        });
        _showScanResultDialog(result);
      }
    } on TicketApiException catch (e) {
      if (mounted) {
        setState(() {
          _lastScanResult = ScanResult(
            success: false,
            message: e.message,
            errorCode: 'error',
          );
        });
        _showSnackBar(e.message, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tickets',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: widget.isOrganizer
            ? TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.confirmation_number_outlined),
                    text: 'My Tickets',
                  ),
                  Tab(
                    icon: Icon(Icons.qr_code_scanner),
                    text: 'Scan Ticket',
                  ),
                ],
              )
            : null,
        actions: [
          IconButton(
            onPressed: () => _showBuyTicketDialog(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            tooltip: 'Buy Ticket',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.isOrganizer
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildMyTicketsTab(),
                _buildScanTicketTab(),
              ],
            )
          : _buildMyTicketsTab(),
    );
  }

  // ==================== MY TICKETS TAB ====================

  Widget _buildMyTicketsTab() {
    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: AppTheme.primaryColor,
      child: _isLoadingTickets
          ? _buildLoadingState()
          : _ticketsError != null
              ? _buildErrorState()
              : _tickets.isEmpty
                  ? _buildEmptyState()
                  : _buildTicketsList(),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(4, (index) => const TicketCardShimmer()),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _ticketsError ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTickets,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 56,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Tickets Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your purchased tickets will appear here.\nStart exploring events to get your first ticket!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showBuyTicketDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Buy a Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    // Separate tickets by status
    final paidTickets = _tickets.where((t) => t.isPaid).toList();
    final pendingTickets = _tickets.where((t) => t.isPending).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildSummarySection(),
          const SizedBox(height: 24),

          // Pending tickets (if any)
          if (pendingTickets.isNotEmpty) ...[
            _buildSectionHeader(
                'Pending Payment', pendingTickets.length, AppTheme.pendingColor),
            const SizedBox(height: 12),
            ...pendingTickets.map((ticket) => _buildTicketCard(ticket)),
            const SizedBox(height: 24),
          ],

          // Paid tickets
          if (paidTickets.isNotEmpty) ...[
            _buildSectionHeader(
                'My Tickets', paidTickets.length, AppTheme.primaryColor),
            const SizedBox(height: 12),
            ...paidTickets.map((ticket) => _buildTicketCard(ticket)),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final totalTickets = _tickets.length;
    final validTickets = _tickets.where((t) => t.isValid).length;
    final usedTickets = _tickets.where((t) => t.isUsed).length;
    final pendingTickets = _tickets.where((t) => t.isPending).length;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalTickets total',
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
                child: _buildSummaryCard(
                  'Valid',
                  validTickets,
                  AppTheme.successColor,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Used',
                  usedTickets,
                  AppTheme.textSecondary,
                  Icons.event_available_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Pending',
                  pendingTickets,
                  AppTheme.pendingColor,
                  Icons.schedule_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, int count, Color color, IconData icon) {
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
            count.toString(),
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

  Widget _buildTicketCard(TicketDto ticket) {
    return GestureDetector(
      onTap: () => _showTicketDetails(ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
            // Header with event name and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.event.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${ticket.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(ticket),
              ],
            ),
            const SizedBox(height: 16),

            // Divider
            Container(
              height: 1,
              color: AppTheme.textLight.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),

            // Event details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.location_on_outlined,
                    ticket.event.fullLocation,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.calendar_today_outlined,
                    _formatDateTime(ticket.event.startTime),
                  ),
                ),
              ],
            ),

            // Scanned info if applicable
            if (ticket.isScanned && ticket.scannedAt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Used on ${_formatDateTime(ticket.scannedAt!)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // QR Code button
            if (ticket.isPaid) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showQrCodeDialog(ticket),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Show QR Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TicketDto ticket) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    if (ticket.isPending) {
      backgroundColor = AppTheme.pendingColor.withValues(alpha: 0.1);
      textColor = AppTheme.pendingColor;
      text = 'Pending';
      icon = Icons.schedule;
    } else if (ticket.isScanned) {
      backgroundColor = AppTheme.textSecondary.withValues(alpha: 0.1);
      textColor = AppTheme.textSecondary;
      text = 'Used';
      icon = Icons.event_available;
    } else {
      backgroundColor = AppTheme.successColor.withValues(alpha: 0.1);
      textColor = AppTheme.successColor;
      text = 'Valid';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==================== DIALOGS ====================

  void _showTicketDetails(TicketDto ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TicketDetailsSheet(ticket: ticket),
    );
  }

  void _showQrCodeDialog(TicketDto ticket) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Ticket QR Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticket.event.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Image.network(
                  ticket.qrCodeImageUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Show this code at the event entrance',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBuyTicketDialog() async {
    // Check if user is guest
    if (AuthHelper.isGuest) {
      await showLoginPrompt(
        context,
        title: 'Buy Tickets',
        message: 'Please log in or create an account to purchase tickets.',
      );
      return;
    }

    _loadAvailableEvents();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text(
                        'Buy a Ticket',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: _isLoadingEvents
                      ? const Center(child: CircularProgressIndicator())
                      : _availableEvents.isEmpty
                          ? _buildNoEventsAvailable()
                          : _buildEventsList(setSheetState),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoEventsAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Events Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no upcoming events\navailable for purchase right now.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(StateSetter setSheetState) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _availableEvents.length,
      itemBuilder: (context, index) {
        final event = _availableEvents[index];
        final isSelected = _selectedEvent?.id == event.id;

        return GestureDetector(
          onTap: () {
            setSheetState(() {
              _selectedEvent = event;
            });
            setState(() {
              _selectedEvent = event;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textLight.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.city ?? 'Location TBA'} - ${_formatDate(event.startTime)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      event.isFree ? 'FREE' : '\$${event.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: event.isFree
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== SCAN TICKET TAB ====================

  Widget _buildScanTicketTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Attendee Tickets',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Point your camera at the attendee\'s QR code to validate their ticket.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Scanner or result
          Expanded(
            child: _isScanning ? _buildScanner() : _buildScanButton(),
          ),

          // Last scan result
          if (_lastScanResult != null) ...[
            const SizedBox(height: 16),
            _buildLastScanResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 56,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startScanning,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanning'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _scanQrCode(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _stopScanning,
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorColor,
            side: const BorderSide(color: AppTheme.errorColor),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastScanResult() {
    final result = _lastScanResult!;
    final color = result.success ? AppTheme.successColor : AppTheme.errorColor;
    final icon = result.success ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.success ? 'Ticket Valid!' : 'Scan Failed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startScanning() {
    HapticFeedback.mediumImpact();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    setState(() {
      _isScanning = true;
      _lastScanResult = null;
    });
  }

  void _stopScanning() {
    _scannerController?.stop();
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      _isScanning = false;
    });
  }

  void _showScanResultDialog(ScanResult result) {
    final color = result.success ? AppTheme.successColor : AppTheme.errorColor;
    final icon = result.success ? Icons.check_circle : Icons.cancel;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                result.success ? 'Ticket Accepted!' : 'Invalid Ticket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (result.scannedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Scanned at: ${_formatDateTime(result.scannedAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.textSecondary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startScanning();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Scan Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}


// ==================== TICKET DETAILS SHEET ====================

class _TicketDetailsSheet extends StatelessWidget {
  final TicketDto ticket;

  const _TicketDetailsSheet({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        size: 48,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Event info
                  _buildSection('Event Details', [
                    _buildInfoRow('Event', ticket.event.name),
                    _buildInfoRow('Location', ticket.event.fullLocation),
                    _buildInfoRow('Date', _formatDateTime(ticket.event.startTime)),
                    if (ticket.event.price != null)
                      _buildInfoRow('Price', '\$${ticket.event.price!.toStringAsFixed(2)}'),
                  ]),
                  const SizedBox(height: 24),

                  // Ticket info
                  _buildSection('Ticket Details', [
                    _buildInfoRow('Ticket ID', '#${ticket.id}'),
                    _buildInfoRow('Payment Status', ticket.paymentStatus.toUpperCase()),
                    if (ticket.isScanned && ticket.scannedAt != null)
                      _buildInfoRow('Scanned At', _formatDateTime(ticket.scannedAt!)),
                  ]),

                  // QR Code
                  if (ticket.isPaid) ...[
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Your QR Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.network(
                              ticket.qrCodeImageUrl,
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (ticket.isPending) return AppTheme.pendingColor;
    if (ticket.isScanned) return AppTheme.textSecondary;
    return AppTheme.successColor;
  }

  IconData _getStatusIcon() {
    if (ticket.isPending) return Icons.schedule;
    if (ticket.isScanned) return Icons.event_available;
    return Icons.check_circle;
  }

  String _getStatusText() {
    if (ticket.isPending) return 'Payment Pending';
    if (ticket.isScanned) return 'Ticket Used';
    return 'Valid Ticket';
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }
}
