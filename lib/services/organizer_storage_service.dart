// Organizer Storage Service - Frontend-only mock layer using SharedPreferences.
// TODO: Replace with backend API integration when available.
//
// This service handles all organizer-related data persistence locally.
// All data is stored in SharedPreferences and will persist across app restarts.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/organizer_models.dart';

class OrganizerStorageService {
  static const String _keyApprovalStatus = 'organizer_approval_status';
  static const String _keyOrganizerRequest = 'organizer_request';
  static const String _keyOrganizerProfile = 'organizer_profile';
  static const String _keyEvents = 'organizer_events';
  static const String _keyOpportunities = 'organizer_opportunities';
  static const String _keyApplications = 'volunteer_applications';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure prefs is initialized
  static Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ============================================================
  // ORGANIZER APPROVAL STATUS
  // ============================================================

  /// Get current organizer approval status
  /// TODO: Replace with API call to check user's organizer status
  static Future<OrganizerApprovalStatus> getApprovalStatus() async {
    final prefs = await _preferences;
    final status = prefs.getString(_keyApprovalStatus);
    return OrganizerApprovalStatus.fromString(status);
  }

  /// Set organizer approval status
  /// TODO: This will be handled by backend after admin approval
  static Future<bool> setApprovalStatus(OrganizerApprovalStatus status) async {
    final prefs = await _preferences;
    return prefs.setString(_keyApprovalStatus, status.toShortString());
  }

  /// Check if user is an approved organizer
  static Future<bool> isApprovedOrganizer() async {
    final status = await getApprovalStatus();
    return status == OrganizerApprovalStatus.approved;
  }

  // ============================================================
  // ORGANIZER REQUEST
  // ============================================================

  /// Get organizer request
  /// TODO: Replace with API call to get pending request
  static Future<OrganizerRequest?> getOrganizerRequest() async {
    final prefs = await _preferences;
    final json = prefs.getString(_keyOrganizerRequest);
    if (json == null) return null;
    return OrganizerRequest.fromJson(jsonDecode(json));
  }

  /// Submit organizer request
  /// TODO: Replace with API POST call
  static Future<bool> submitOrganizerRequest(OrganizerRequest request) async {
    final prefs = await _preferences;
    final json = jsonEncode(request.toJson());
    final saved = await prefs.setString(_keyOrganizerRequest, json);
    if (saved) {
      await setApprovalStatus(OrganizerApprovalStatus.pending);
    }
    return saved;
  }

  /// Clear organizer request (on rejection or reset)
  static Future<bool> clearOrganizerRequest() async {
    final prefs = await _preferences;
    return prefs.remove(_keyOrganizerRequest);
  }

  // ============================================================
  // ORGANIZER PROFILE
  // ============================================================

  /// Get organizer profile
  /// TODO: Replace with API call
  static Future<OrganizerProfile?> getOrganizerProfile() async {
    final prefs = await _preferences;
    final json = prefs.getString(_keyOrganizerProfile);
    if (json == null) return null;
    return OrganizerProfile.fromJson(jsonDecode(json));
  }

  /// Save organizer profile
  /// TODO: Replace with API PUT/PATCH call
  static Future<bool> saveOrganizerProfile(OrganizerProfile profile) async {
    final prefs = await _preferences;
    final json = jsonEncode(profile.toJson());
    return prefs.setString(_keyOrganizerProfile, json);
  }

  /// Create initial organizer profile from request (on approval)
  static Future<OrganizerProfile?> createProfileFromRequest() async {
    final request = await getOrganizerRequest();
    if (request == null) return null;

    final profile = OrganizerProfile(
      id: 'org_${DateTime.now().millisecondsSinceEpoch}',
      organizerName: request.organizationName,
      description: request.description,
      contactEmail: '', // User will fill this later
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveOrganizerProfile(profile);
    return profile;
  }

  // ============================================================
  // EVENTS
  // ============================================================

  /// Get all events for current organizer
  /// TODO: Replace with API call with organizer filter
  static Future<List<OrganizerEvent>> getEvents() async {
    final prefs = await _preferences;
    final json = prefs.getString(_keyEvents);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => OrganizerEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get event by ID
  static Future<OrganizerEvent?> getEventById(String id) async {
    final events = await getEvents();
    try {
      return events.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save/Create event
  /// TODO: Replace with API POST/PUT call
  static Future<bool> saveEvent(OrganizerEvent event) async {
    final prefs = await _preferences;
    final events = await getEvents();

    final index = events.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      events[index] = event;
    } else {
      events.add(event);
    }

    final json = jsonEncode(events.map((e) => e.toJson()).toList());
    return prefs.setString(_keyEvents, json);
  }

  /// Delete event
  /// TODO: Replace with API DELETE call
  static Future<bool> deleteEvent(String eventId) async {
    final prefs = await _preferences;
    final events = await getEvents();

    events.removeWhere((e) => e.id == eventId);

    // Also delete related opportunities and applications
    await _deleteOpportunitiesForEvent(eventId);
    await _deleteApplicationsForEvent(eventId);

    final json = jsonEncode(events.map((e) => e.toJson()).toList());
    return prefs.setString(_keyEvents, json);
  }

  /// Get event stats (mock data)
  static Future<Map<String, dynamic>> getEventStats(String eventId) async {
    final event = await getEventById(eventId);
    if (event == null) {
      return {'viewCount': 0, 'ticketsSold': 0, 'revenue': 0.0};
    }

    return {
      'viewCount': event.viewCount,
      'ticketsSold': event.totalTicketsSold,
      'revenue': event.tickets.fold<double>(
        0,
        (sum, t) => sum + (t.price * t.soldCount),
      ),
    };
  }

  /// Get dashboard stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final events = await getEvents();
    final now = DateTime.now();

    final totalEvents = events.length;
    final upcomingEvents = events.where((e) => e.startDateTime.isAfter(now)).length;
    final ticketsSold = events.fold<int>(0, (sum, e) => sum + e.totalTicketsSold);

    return {
      'totalEvents': totalEvents,
      'upcomingEvents': upcomingEvents,
      'ticketsSold': ticketsSold,
    };
  }

  // ============================================================
  // VOLUNTEER OPPORTUNITIES
  // ============================================================

  /// Get all opportunities
  static Future<List<OrganizerVolunteerOpportunity>> getOpportunities() async {
    final prefs = await _preferences;
    final json = prefs.getString(_keyOpportunities);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => OrganizerVolunteerOpportunity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get opportunities for a specific event
  static Future<List<OrganizerVolunteerOpportunity>> getOpportunitiesForEvent(
    String eventId,
  ) async {
    final opportunities = await getOpportunities();
    return opportunities.where((o) => o.eventId == eventId).toList();
  }

  /// Get opportunity by ID
  static Future<OrganizerVolunteerOpportunity?> getOpportunityById(String id) async {
    final opportunities = await getOpportunities();
    try {
      return opportunities.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save/Create opportunity
  /// TODO: Replace with API call
  static Future<bool> saveOpportunity(OrganizerVolunteerOpportunity opportunity) async {
    final prefs = await _preferences;
    final opportunities = await getOpportunities();

    final index = opportunities.indexWhere((o) => o.id == opportunity.id);
    if (index >= 0) {
      opportunities[index] = opportunity;
    } else {
      opportunities.add(opportunity);
    }

    final json = jsonEncode(opportunities.map((o) => o.toJson()).toList());
    return prefs.setString(_keyOpportunities, json);
  }

  /// Delete opportunity
  static Future<bool> deleteOpportunity(String opportunityId) async {
    final prefs = await _preferences;
    final opportunities = await getOpportunities();

    opportunities.removeWhere((o) => o.id == opportunityId);

    // Also delete related applications
    await _deleteApplicationsForOpportunity(opportunityId);

    final json = jsonEncode(opportunities.map((o) => o.toJson()).toList());
    return prefs.setString(_keyOpportunities, json);
  }

  /// Delete all opportunities for an event
  static Future<void> _deleteOpportunitiesForEvent(String eventId) async {
    final prefs = await _preferences;
    final opportunities = await getOpportunities();

    opportunities.removeWhere((o) => o.eventId == eventId);

    final json = jsonEncode(opportunities.map((o) => o.toJson()).toList());
    await prefs.setString(_keyOpportunities, json);
  }

  // ============================================================
  // VOLUNTEER APPLICATIONS
  // ============================================================

  /// Get all applications
  static Future<List<VolunteerApplication>> getApplications() async {
    final prefs = await _preferences;
    final json = prefs.getString(_keyApplications);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => VolunteerApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get applications for a specific opportunity
  static Future<List<VolunteerApplication>> getApplicationsForOpportunity(
    String opportunityId,
  ) async {
    final applications = await getApplications();
    return applications.where((a) => a.opportunityId == opportunityId).toList();
  }

  /// Get applications for a specific event
  static Future<List<VolunteerApplication>> getApplicationsForEvent(
    String eventId,
  ) async {
    final applications = await getApplications();
    return applications.where((a) => a.eventId == eventId).toList();
  }

  /// Get application by ID
  static Future<VolunteerApplication?> getApplicationById(String id) async {
    final applications = await getApplications();
    try {
      return applications.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save/Create application
  /// TODO: Replace with API call
  static Future<bool> saveApplication(VolunteerApplication application) async {
    final prefs = await _preferences;
    final applications = await getApplications();

    final index = applications.indexWhere((a) => a.id == application.id);
    if (index >= 0) {
      applications[index] = application;
    } else {
      applications.add(application);
    }

    final json = jsonEncode(applications.map((a) => a.toJson()).toList());
    return prefs.setString(_keyApplications, json);
  }

  /// Accept application
  static Future<bool> acceptApplication(String applicationId) async {
    final application = await getApplicationById(applicationId);
    if (application == null) return false;
    if (application.status != ApplicationStatus.pending) return false;

    // Get the opportunity and check spots
    final opportunity = await getOpportunityById(application.opportunityId);
    if (opportunity == null) return false;
    if (opportunity.derivedStatus == OpportunityStatus.closed) return false;
    if (opportunity.spotsAvailable <= 0) return false;

    // Update application status
    final updatedApplication = application.copyWith(
      status: ApplicationStatus.accepted,
      updatedAt: DateTime.now(),
    );
    await saveApplication(updatedApplication);

    // Update opportunity spots
    final updatedOpportunity = opportunity.copyWith(
      spotsFilled: opportunity.spotsFilled + 1,
      updatedAt: DateTime.now(),
    );
    await saveOpportunity(updatedOpportunity);

    return true;
  }

  /// Reject application
  static Future<bool> rejectApplication(String applicationId) async {
    final application = await getApplicationById(applicationId);
    if (application == null) return false;
    if (application.status != ApplicationStatus.pending) return false;

    final updatedApplication = application.copyWith(
      status: ApplicationStatus.rejected,
      updatedAt: DateTime.now(),
    );

    return saveApplication(updatedApplication);
  }

  /// Delete applications for an event
  static Future<void> _deleteApplicationsForEvent(String eventId) async {
    final prefs = await _preferences;
    final applications = await getApplications();

    applications.removeWhere((a) => a.eventId == eventId);

    final json = jsonEncode(applications.map((a) => a.toJson()).toList());
    await prefs.setString(_keyApplications, json);
  }

  /// Delete applications for an opportunity
  static Future<void> _deleteApplicationsForOpportunity(String opportunityId) async {
    final prefs = await _preferences;
    final applications = await getApplications();

    applications.removeWhere((a) => a.opportunityId == opportunityId);

    final json = jsonEncode(applications.map((a) => a.toJson()).toList());
    await prefs.setString(_keyApplications, json);
  }

  /// Add mock applicant (DEV HELPER)
  static Future<bool> addMockApplicant(String eventId, String opportunityId) async {
    final application = VolunteerApplication(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      opportunityId: opportunityId,
      volunteerId: 'mock_vol_${DateTime.now().millisecondsSinceEpoch}',
      volunteerName: _mockNames[DateTime.now().millisecond % _mockNames.length],
      volunteerEmail: 'volunteer${DateTime.now().millisecond}@example.com',
      message: 'I would love to help with this event!',
      status: ApplicationStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return saveApplication(application);
  }

  static const List<String> _mockNames = [
    'Ahmed Hassan',
    'Sarah Ali',
    'Mohammad Omar',
    'Fatima Khalil',
    'Youssef Ibrahim',
    'Layla Mahmoud',
    'Omar Nasser',
    'Nour Abdullah',
  ];

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Generate unique ID
  static String generateId(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Clear all organizer data (for testing/reset)
  static Future<void> clearAllData() async {
    final prefs = await _preferences;
    await prefs.remove(_keyApprovalStatus);
    await prefs.remove(_keyOrganizerRequest);
    await prefs.remove(_keyOrganizerProfile);
    await prefs.remove(_keyEvents);
    await prefs.remove(_keyOpportunities);
    await prefs.remove(_keyApplications);
  }

  /// Initialize with sample data (DEV ONLY)
  static Future<void> initializeSampleData() async {
    final events = await getEvents();
    if (events.isNotEmpty) return; // Don't overwrite existing data

    final now = DateTime.now();
    final organizerId = 'org_sample';

    // Sample events
    final sampleEvents = [
      OrganizerEvent(
        id: 'evt_sample_1',
        organizerId: organizerId,
        title: 'Tech Conference 2025',
        description: 'Annual technology conference featuring the latest innovations.',
        category: 'Technology',
        startDateTime: now.add(const Duration(days: 30)),
        endDateTime: now.add(const Duration(days: 30, hours: 8)),
        location: 'Damascus Convention Center',
        city: 'Damascus',
        status: OrganizerEventStatus.published,
        tickets: [
          EventTicket(
            id: 'tkt_1',
            name: 'General Admission',
            price: 25.0,
            quantity: 100,
            soldCount: 45,
            isFree: false,
          ),
          EventTicket(
            id: 'tkt_2',
            name: 'VIP Pass',
            price: 75.0,
            quantity: 20,
            soldCount: 8,
            isFree: false,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
        viewCount: 234,
        ticketsSold: 53,
      ),
      OrganizerEvent(
        id: 'evt_sample_2',
        organizerId: organizerId,
        title: 'Community Cleanup Day',
        description: 'Join us for a day of community service and environmental action.',
        category: 'Community',
        startDateTime: now.add(const Duration(days: 7)),
        endDateTime: now.add(const Duration(days: 7, hours: 4)),
        location: 'Central Park',
        city: 'Damascus',
        status: OrganizerEventStatus.published,
        tickets: [
          EventTicket(
            id: 'tkt_3',
            name: 'Free Registration',
            price: 0.0,
            quantity: 50,
            soldCount: 23,
            isFree: true,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        viewCount: 89,
        ticketsSold: 23,
      ),
    ];

    for (final event in sampleEvents) {
      await saveEvent(event);
    }

    // Sample opportunities
    final sampleOpportunities = [
      OrganizerVolunteerOpportunity(
        id: 'opp_sample_1',
        eventId: 'evt_sample_1',
        roleName: 'Registration Desk',
        description: 'Help attendees check in and receive their badges.',
        spotsTotal: 5,
        spotsFilled: 2,
        duration: '4 hours',
        requirements: 'Good communication skills, punctual',
        benefits: 'Free event access, lunch provided',
        status: OpportunityStatus.published,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now,
      ),
      OrganizerVolunteerOpportunity(
        id: 'opp_sample_2',
        eventId: 'evt_sample_2',
        roleName: 'Team Leader',
        description: 'Lead a group of volunteers in cleanup activities.',
        spotsTotal: 3,
        spotsFilled: 1,
        duration: '4 hours',
        requirements: 'Leadership experience preferred',
        benefits: 'Certificate of appreciation, refreshments',
        status: OpportunityStatus.published,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now,
      ),
    ];

    for (final opp in sampleOpportunities) {
      await saveOpportunity(opp);
    }
  }
}
