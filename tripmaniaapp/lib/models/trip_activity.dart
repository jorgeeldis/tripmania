class TripActivity {
  final String id;
  final String activityName;
  final String location;
  final String category;
  final String categoryId;
  final double? estimatedCost;
  final DateTime date;
  final String notes;
  final double latitude;
  final double longitude;
  final List<String> imagePaths; // Store image paths as strings
  final DateTime createdAt;

  TripActivity({
    required this.id,
    required this.activityName,
    required this.location,
    required this.category,
    required this.categoryId,
    this.estimatedCost,
    required this.date,
    required this.notes,
    required this.latitude,
    required this.longitude,
    required this.imagePaths,
    required this.createdAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityName': activityName,
      'location': location,
      'category': category,
      'categoryId': categoryId,
      'estimatedCost': estimatedCost,
      'date': date.toIso8601String(),
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'imagePaths': imagePaths,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory TripActivity.fromJson(Map<String, dynamic> json) {
    return TripActivity(
      id: json['id'] ?? '',
      activityName: json['activityName'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? '',
      categoryId: json['categoryId'] ?? '',
      estimatedCost: json['estimatedCost']?.toDouble(),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      notes: json['notes'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Helper method to get category name from ID
  static String getCategoryName(String categoryId) {
    const Map<String, String> categoryMap = {
      '1': 'Sightseeing',
      '2': 'Museum',
      '3': 'Transport',
      '4': 'City Walk',
      '5': 'Landmark',
      '6': 'Tour',
      '7': 'Accommodation',
      '8': 'Sports',
      '9': 'Neighborhood',
      '10': 'Food/Sightseeing',
      '11': 'Museum/Art',
      '12': 'Park',
      '13': 'Food',
      '14': 'Shopping/Landmark',
      '15': 'Landmark/Park',
      '16': 'Art/Neighborhood',
      '17': 'Market/Food',
      '18': 'Family',
      '19': 'Food/Experience',
      '20': 'Museum/Food',
      '21': 'Market',
    };
    return categoryMap[categoryId] ?? 'Unknown';
  }
}
