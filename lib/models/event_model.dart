class EventModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime date;
  final String time;
  final String location;
  final String venue;
  final double price;
  final String category;
  final String organizer;
  final int availableTickets;
  final bool isFeatured;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.time,
    required this.location,
    required this.venue,
    required this.price,
    required this.category,
    required this.organizer,
    required this.availableTickets,
    this.isFeatured = false,
  });

  // Mock data for UI
  static List<EventModel> getMockEvents() {
    return [
      EventModel(
        id: '1',
        title: 'Summer Music Festival 2025',
        description: 'Join us for an unforgettable night of live music featuring top artists from around the world. Experience amazing performances, great food, and incredible atmosphere.',
        imageUrl: 'https://picsum.photos/seed/event1/400/200',
        date: DateTime.now().add(const Duration(days: 15)),
        time: '7:00 PM - 11:00 PM',
        location: 'Damascus, Syria',
        venue: 'Damascus Opera House',
        price: 75.00,
        category: 'Music',
        organizer: 'EventPro Productions',
        availableTickets: 250,
        isFeatured: true,
      ),
      EventModel(
        id: '2',
        title: 'Tech Conference 2025',
        description: 'The biggest technology conference in the region. Learn from industry experts, network with professionals, and discover the latest innovations.',
        imageUrl: 'https://picsum.photos/seed/event2/400/200',
        date: DateTime.now().add(const Duration(days: 30)),
        time: '9:00 AM - 6:00 PM',
        location: 'Aleppo, Syria',
        venue: 'Aleppo Convention Center',
        price: 150.00,
        category: 'Technology',
        organizer: 'TechSyria',
        availableTickets: 500,
        isFeatured: true,
      ),
      EventModel(
        id: '3',
        title: 'Food & Wine Festival',
        description: 'Taste the finest cuisines and wines from local and international chefs. A culinary journey you won\'t forget.',
        imageUrl: 'https://picsum.photos/seed/event3/400/200',
        date: DateTime.now().add(const Duration(days: 7)),
        time: '12:00 PM - 8:00 PM',
        location: 'Latakia, Syria',
        venue: 'Latakia Beach Resort',
        price: 45.00,
        category: 'Food & Drink',
        organizer: 'Gourmet Events',
        availableTickets: 150,
        isFeatured: false,
      ),
      EventModel(
        id: '4',
        title: 'Art Exhibition: Modern Syria',
        description: 'Explore contemporary Syrian art featuring works from emerging and established artists. A celebration of creativity and culture.',
        imageUrl: 'https://picsum.photos/seed/event4/400/200',
        date: DateTime.now().add(const Duration(days: 10)),
        time: '10:00 AM - 7:00 PM',
        location: 'Homs, Syria',
        venue: 'National Art Gallery',
        price: 25.00,
        category: 'Art',
        organizer: 'Syrian Arts Council',
        availableTickets: 100,
        isFeatured: false,
      ),
      EventModel(
        id: '5',
        title: 'Marathon Damascus 2025',
        description: 'Run through the historic streets of Damascus in this annual marathon. Categories for all levels - 5K, 10K, Half Marathon, and Full Marathon.',
        imageUrl: 'https://picsum.photos/seed/event5/400/200',
        date: DateTime.now().add(const Duration(days: 45)),
        time: '6:00 AM - 12:00 PM',
        location: 'Damascus, Syria',
        venue: 'Umayyad Square',
        price: 35.00,
        category: 'Sports',
        organizer: 'Syrian Athletics Federation',
        availableTickets: 1000,
        isFeatured: true,
      ),
      EventModel(
        id: '6',
        title: 'Comedy Night Live',
        description: 'Laugh out loud with the best stand-up comedians in the region. A night of pure entertainment and fun.',
        imageUrl: 'https://picsum.photos/seed/event6/400/200',
        date: DateTime.now().add(const Duration(days: 5)),
        time: '8:00 PM - 11:00 PM',
        location: 'Damascus, Syria',
        venue: 'Comedy Club Damascus',
        price: 30.00,
        category: 'Entertainment',
        organizer: 'Laugh Factory',
        availableTickets: 80,
        isFeatured: false,
      ),
    ];
  }

  static List<String> getCategories() {
    return [
      'All',
      'Music',
      'Technology',
      'Food & Drink',
      'Art',
      'Sports',
      'Entertainment',
      'Business',
      'Education',
    ];
  }
}
