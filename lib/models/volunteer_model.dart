class VolunteerOpportunity {
  final String id;
  final String eventName;
  final String eventCategory;
  final DateTime eventDate;
  final String eventTime;
  final String location;
  final String venue;
  final String roleTitle;
  final String roleDescription;
  final List<String> requirements;
  final String duration;
  final List<String> benefits;
  final int volunteersNeeded;
  final int volunteersApplied;
  final String imageUrl;

  VolunteerOpportunity({
    required this.id,
    required this.eventName,
    required this.eventCategory,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    required this.venue,
    required this.roleTitle,
    required this.roleDescription,
    required this.requirements,
    required this.duration,
    required this.benefits,
    required this.volunteersNeeded,
    required this.volunteersApplied,
    required this.imageUrl,
  });

  int get spotsLeft => volunteersNeeded - volunteersApplied;
  bool get isUrgent => spotsLeft <= 3;

  static List<VolunteerOpportunity> getMockOpportunities() {
    return [
      VolunteerOpportunity(
        id: '1',
        eventName: 'Summer Music Festival 2025',
        eventCategory: 'Music',
        eventDate: DateTime.now().add(const Duration(days: 15)),
        eventTime: '7:00 PM - 11:00 PM',
        location: 'Damascus, Syria',
        venue: 'Damascus Opera House',
        roleTitle: 'Event Organizer',
        roleDescription: 'Help coordinate event activities, manage schedules, and ensure smooth operation of the festival. You will be working closely with the event management team.',
        requirements: [
          'Good communication skills',
          'Able to work in a team',
          'Available for full event duration',
          'Previous event experience preferred',
        ],
        duration: '6 hours',
        benefits: [
          'Free event access',
          'Meal and refreshments provided',
          'Certificate of participation',
          'Networking opportunities',
        ],
        volunteersNeeded: 10,
        volunteersApplied: 7,
        imageUrl: 'https://picsum.photos/seed/vol1/400/200',
      ),
      VolunteerOpportunity(
        id: '2',
        eventName: 'Tech Conference 2025',
        eventCategory: 'Technology',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        eventTime: '9:00 AM - 6:00 PM',
        location: 'Aleppo, Syria',
        venue: 'Aleppo Convention Center',
        roleTitle: 'Registration Desk',
        roleDescription: 'Welcome attendees, check registrations, distribute badges and event materials. Be the first point of contact for all participants.',
        requirements: [
          'Friendly and professional demeanor',
          'Basic computer skills',
          'Fluent in Arabic and English',
          'Punctual and reliable',
        ],
        duration: '8 hours',
        benefits: [
          'Access to all conference sessions',
          'Lunch and snacks provided',
          'Official volunteer t-shirt',
          'Letter of recommendation',
        ],
        volunteersNeeded: 15,
        volunteersApplied: 12,
        imageUrl: 'https://picsum.photos/seed/vol2/400/200',
      ),
      VolunteerOpportunity(
        id: '3',
        eventName: 'Food & Wine Festival',
        eventCategory: 'Food & Drink',
        eventDate: DateTime.now().add(const Duration(days: 7)),
        eventTime: '12:00 PM - 8:00 PM',
        location: 'Latakia, Syria',
        venue: 'Latakia Beach Resort',
        roleTitle: 'Guest Services',
        roleDescription: 'Assist guests with directions, answer questions about vendors and activities, and ensure a positive experience for all attendees.',
        requirements: [
          'Excellent interpersonal skills',
          'Knowledge of the venue layout',
          'Ability to stand for extended periods',
          'Must be 18 years or older',
        ],
        duration: '5 hours',
        benefits: [
          'Free food tastings',
          'Event merchandise',
          'Certificate of appreciation',
          'Future event discounts',
        ],
        volunteersNeeded: 8,
        volunteersApplied: 6,
        imageUrl: 'https://picsum.photos/seed/vol3/400/200',
      ),
      VolunteerOpportunity(
        id: '4',
        eventName: 'Marathon Damascus 2025',
        eventCategory: 'Sports',
        eventDate: DateTime.now().add(const Duration(days: 45)),
        eventTime: '6:00 AM - 12:00 PM',
        location: 'Damascus, Syria',
        venue: 'Umayyad Square',
        roleTitle: 'Water Station Attendant',
        roleDescription: 'Manage water and refreshment stations along the marathon route. Distribute water, sports drinks, and snacks to runners.',
        requirements: [
          'Early morning availability',
          'Physical fitness to stand and move',
          'Team player attitude',
          'No experience required',
        ],
        duration: '6 hours',
        benefits: [
          'Official volunteer kit',
          'Breakfast provided',
          'Medal for volunteers',
          'Free entry to future races',
        ],
        volunteersNeeded: 20,
        volunteersApplied: 8,
        imageUrl: 'https://picsum.photos/seed/vol4/400/200',
      ),
      VolunteerOpportunity(
        id: '5',
        eventName: 'Art Exhibition: Modern Syria',
        eventCategory: 'Art',
        eventDate: DateTime.now().add(const Duration(days: 10)),
        eventTime: '10:00 AM - 7:00 PM',
        location: 'Homs, Syria',
        venue: 'National Art Gallery',
        roleTitle: 'Gallery Guide',
        roleDescription: 'Guide visitors through the exhibition, provide information about artworks and artists, and ensure the safety of displayed pieces.',
        requirements: [
          'Interest in art and culture',
          'Good public speaking skills',
          'Reliable and professional',
          'Training will be provided',
        ],
        duration: '4 hours',
        benefits: [
          'Meet local artists',
          'Exclusive gallery tour',
          'Art appreciation workshop',
          'Volunteer appreciation event',
        ],
        volunteersNeeded: 6,
        volunteersApplied: 4,
        imageUrl: 'https://picsum.photos/seed/vol5/400/200',
      ),
    ];
  }
}
