import 'package:flutter/material.dart';
import 'package:tripmaniaapp/screens/form.dart';
import 'models/trip_activity.dart';
import 'services/trip_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Mania',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
      ),
      home: const MyHomePage(title: 'Trip Mania'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TripActivity> _tripActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTripActivities();
  }

  Future<void> _loadTripActivities() async {
    try {
      List<TripActivity> activities =
          await TripActivityStorage.getTripActivitiesSorted();
      setState(() {
        _tripActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshTripActivities() async {
    setState(() {
      _isLoading = true;
    });
    await _loadTripActivities();
  }

  String _formatDate(DateTime date) {
    const List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sightseeing':
        return Icons.camera_alt;
      case 'museum':
      case 'museum/art':
        return Icons.museum;
      case 'transport':
        return Icons.directions_bus;
      case 'city walk':
        return Icons.directions_walk;
      case 'landmark':
      case 'landmark/park':
        return Icons.account_balance;
      case 'tour':
        return Icons.tour;
      case 'accommodation':
        return Icons.hotel;
      case 'sports':
        return Icons.sports;
      case 'neighborhood':
      case 'art/neighborhood':
        return Icons.home;
      case 'food':
      case 'food/sightseeing':
      case 'food/experience':
      case 'museum/food':
        return Icons.restaurant;
      case 'park':
        return Icons.park;
      case 'shopping/landmark':
        return Icons.shopping_bag;
      case 'market/food':
      case 'market':
        return Icons.store;
      case 'family':
        return Icons.family_restroom;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue,
                  Colors.lightBlueAccent,
                ], // blue to light blue
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_cafe, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          elevation: 5,
          backgroundColor: Colors.transparent, // needed for gradient
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshTripActivities,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tripActivities.isEmpty
          ? _buildEmptyState()
          : _buildTripsList(),
      floatingActionButton: FloatingActionButton(
        heroTag: "home_add_btn",
        onPressed: () async {
          // Navigate to form and refresh when returning
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormClass(title: 'Add Trip Activity'),
            ),
          );
          // Refresh the list when returning from form
          _refreshTripActivities();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_off, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'No Trip Activities Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start planning your adventures by adding your first trip activity!',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FormClass(title: 'Add Trip Activity'),
                ),
              );
              _refreshTripActivities();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return Column(
      children: [
        // Header with trip count
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.explore, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Your Adventures (${_tripActivities.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        // Trip activities list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tripActivities.length,
            itemBuilder: (context, index) {
              final activity = _tripActivities[index];
              return _buildTripCard(activity);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTripCard(TripActivity activity) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category icon and activity name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(activity.category),
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.activityName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        activity.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Location and date info
            if (activity.location.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activity.location,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(activity.date),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (activity.estimatedCost != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  Text(
                    '\$${activity.estimatedCost!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),

            // Notes
            if (activity.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                activity.notes,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Images
            if (activity.imagePaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Photos (${activity.imagePaths.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: activity.imagePaths.length,
                  itemBuilder: (context, imageIndex) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade100,
                      ),
                      child: const Icon(Icons.photo, color: Colors.grey),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
