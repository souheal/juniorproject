import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/organizer_storage_service.dart';
import '../../models/organizer_models.dart';

class EventVolunteerManagementScreen extends StatefulWidget {
  final OrganizerEvent event;

  const EventVolunteerManagementScreen({super.key, required this.event});

  @override
  State<EventVolunteerManagementScreen> createState() =>
      _EventVolunteerManagementScreenState();
}

class _EventVolunteerManagementScreenState
    extends State<EventVolunteerManagementScreen>
    with SingleTickerProviderStateMixin {
  List<OrganizerVolunteerOpportunity> _opportunities = [];
  Map<String, List<VolunteerApplication>> _applicationsByOpportunity = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final opportunities =
        await OrganizerStorageService.getOpportunitiesForEvent(widget.event.id);
    final Map<String, List<VolunteerApplication>> appsByOpp = {};

    for (final opp in opportunities) {
      final apps =
          await OrganizerStorageService.getApplicationsForOpportunity(opp.id);
      appsByOpp[opp.id] = apps;
    }

    if (mounted) {
      setState(() {
        _opportunities = opportunities;
        _applicationsByOpportunity = appsByOpp;
        _isLoading = false;
      });
    }
  }

  void _showAddOpportunityModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddOpportunityModal(
        eventId: widget.event.id,
        onSave: (opp) async {
          await OrganizerStorageService.saveOpportunity(opp);
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteOpportunity(OrganizerVolunteerOpportunity opp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Opportunity'),
        content: Text('Are you sure you want to delete "${opp.roleName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await OrganizerStorageService.deleteOpportunity(opp.id);
      _loadData();
    }
  }

  Future<void> _toggleOpportunityStatus(OrganizerVolunteerOpportunity opp) async {
    final newStatus = opp.status == OpportunityStatus.draft
        ? OpportunityStatus.published
        : OpportunityStatus.draft;

    final updated = opp.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    await OrganizerStorageService.saveOpportunity(updated);
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == OpportunityStatus.published
                ? 'Opportunity published!'
                : 'Opportunity set to draft',
          ),
          backgroundColor: newStatus == OpportunityStatus.published
              ? AppTheme.successColor
              : AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _addMockApplicant(String opportunityId) async {
    await OrganizerStorageService.addMockApplicant(
      widget.event.id,
      opportunityId,
    );
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mock applicant added!'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleApplication(
    VolunteerApplication app,
    bool accept,
  ) async {
    bool success;
    if (accept) {
      success = await OrganizerStorageService.acceptApplication(app.id);
    } else {
      success = await OrganizerStorageService.rejectApplication(app.id);
    }

    if (success) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Volunteer accepted!' : 'Volunteer rejected'),
            backgroundColor: accept ? AppTheme.successColor : AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Volunteer Management'),
            Text(
              widget.event.title,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Opportunities'),
            Tab(text: 'Applications'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOpportunitiesTab(),
                  _buildApplicationsTab(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOpportunityModal,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Role'),
      ),
    );
  }

  Widget _buildOpportunitiesTab() {
    if (_opportunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'No volunteer roles yet',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create roles for volunteers to apply',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _opportunities.length,
      itemBuilder: (context, index) {
        final opp = _opportunities[index];
        final apps = _applicationsByOpportunity[opp.id] ?? [];
        return _buildOpportunityCard(opp, apps);
      },
    );
  }

  Widget _buildOpportunityCard(
    OrganizerVolunteerOpportunity opp,
    List<VolunteerApplication> apps,
  ) {
    final pendingCount = apps.where((a) => a.status == ApplicationStatus.pending).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(opp.derivedStatus).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.work_outline,
                  color: _getStatusColor(opp.derivedStatus),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opp.roleName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${opp.spotsAvailable}/${opp.spotsTotal} spots available',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(opp.derivedStatus),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opp.derivedStatus.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (opp.description != null) ...[
            const SizedBox(height: 12),
            Text(
              opp.description!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (opp.duration != null || opp.requirements != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (opp.duration != null)
                  _buildInfoChip(Icons.access_time, opp.duration!),
                if (pendingCount > 0)
                  _buildInfoChip(
                    Icons.pending_actions,
                    '$pendingCount pending',
                    color: AppTheme.warningColor,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (opp.derivedStatus != OpportunityStatus.closed)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _toggleOpportunityStatus(opp),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: opp.status == OpportunityStatus.draft
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                      side: BorderSide(
                        color: opp.status == OpportunityStatus.draft
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      opp.status == OpportunityStatus.draft ? 'Publish' : 'Unpublish',
                    ),
                  ),
                ),
              if (opp.derivedStatus != OpportunityStatus.closed)
                const SizedBox(width: 8),
              // DEV ONLY: Add mock applicant
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: opp.derivedStatus == OpportunityStatus.published
                      ? () => _addMockApplicant(opp.id)
                      : null,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Mock Apply'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _deleteOpportunity(opp),
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.textSecondary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
    final allApplications = <VolunteerApplication>[];
    for (final apps in _applicationsByOpportunity.values) {
      allApplications.addAll(apps);
    }

    if (allApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'No applications yet',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Publish opportunities to receive applications',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      );
    }

    // Group by opportunity
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _opportunities.length,
      itemBuilder: (context, index) {
        final opp = _opportunities[index];
        final apps = _applicationsByOpportunity[opp.id] ?? [];
        if (apps.isEmpty) return const SizedBox.shrink();
        return _buildApplicationsSection(opp, apps);
      },
    );
  }

  Widget _buildApplicationsSection(
    OrganizerVolunteerOpportunity opp,
    List<VolunteerApplication> apps,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            opp.roleName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        ...apps.map((app) => _buildApplicationCard(app, opp)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildApplicationCard(
    VolunteerApplication app,
    OrganizerVolunteerOpportunity opp,
  ) {
    final canAcceptReject = app.status == ApplicationStatus.pending &&
        opp.derivedStatus == OpportunityStatus.published;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  app.volunteerName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.volunteerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (app.volunteerEmail != null)
                      Text(
                        app.volunteerEmail!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getAppStatusColor(app.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  app.status.displayName,
                  style: TextStyle(
                    color: _getAppStatusColor(app.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (app.message != null) ...[
            const SizedBox(height: 12),
            Text(
              app.message!,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (canAcceptReject) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleApplication(app, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: opp.spotsAvailable > 0
                        ? () => _handleApplication(app, true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(OpportunityStatus status) {
    switch (status) {
      case OpportunityStatus.draft:
        return AppTheme.warningColor;
      case OpportunityStatus.published:
        return AppTheme.successColor;
      case OpportunityStatus.closed:
        return AppTheme.textSecondary;
    }
  }

  Color _getAppStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppTheme.warningColor;
      case ApplicationStatus.accepted:
        return AppTheme.successColor;
      case ApplicationStatus.rejected:
        return AppTheme.errorColor;
    }
  }
}

/// Modal for adding a new volunteer opportunity
class _AddOpportunityModal extends StatefulWidget {
  final String eventId;
  final Function(OrganizerVolunteerOpportunity) onSave;

  const _AddOpportunityModal({
    required this.eventId,
    required this.onSave,
  });

  @override
  State<_AddOpportunityModal> createState() => _AddOpportunityModalState();
}

class _AddOpportunityModalState extends State<_AddOpportunityModal> {
  final _formKey = GlobalKey<FormState>();
  final _roleNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _spotsController = TextEditingController(text: '5');
  final _durationController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();

  @override
  void dispose() {
    _roleNameController.dispose();
    _descriptionController.dispose();
    _spotsController.dispose();
    _durationController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final opp = OrganizerVolunteerOpportunity(
      id: OrganizerStorageService.generateId('opp'),
      eventId: widget.eventId,
      roleName: _roleNameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      spotsTotal: int.parse(_spotsController.text),
      duration: _durationController.text.trim().isEmpty
          ? null
          : _durationController.text.trim(),
      requirements: _requirementsController.text.trim().isEmpty
          ? null
          : _requirementsController.text.trim(),
      benefits: _benefitsController.text.trim().isEmpty
          ? null
          : _benefitsController.text.trim(),
      status: OpportunityStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(opp);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Volunteer Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _roleNameController,
                decoration: const InputDecoration(
                  labelText: 'Role Name *',
                  hintText: 'e.g., Registration Desk, Guide',
                ),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Role name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _spotsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Spots *',
                  hintText: 'How many volunteers needed',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  final num = int.tryParse(v!);
                  if (num == null || num < 1) return 'Must be at least 1';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (optional)',
                  hintText: 'e.g., 4 hours, 9 AM - 1 PM',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What will volunteers do?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Requirements (optional)',
                  hintText: 'Skills or qualifications needed',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _benefitsController,
                decoration: const InputDecoration(
                  labelText: 'Benefits (optional)',
                  hintText: 'What volunteers will receive',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Role'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
