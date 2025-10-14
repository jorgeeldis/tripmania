import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/trip_activity.dart';
import '../services/trip_storage.dart';

class LocationSuggestion {
  final String displayName;
  final LatLng location;

  LocationSuggestion({required this.displayName, required this.location});

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      displayName: json['display_name'] ?? '',
      location: LatLng(
        double.tryParse(json['lat'] ?? '0') ?? 0.0,
        double.tryParse(json['lon'] ?? '0') ?? 0.0,
      ),
    );
  }
}

void main() {
  runApp(const Form());
}

class Form extends StatelessWidget {
  const Form({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add your trip!',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
      ),
      home: const FormClass(title: 'Add your trip!'),
    );
  }
}

class FormClass extends StatefulWidget {
  const FormClass({super.key, required this.title});

  final String title;

  @override
  State<FormClass> createState() => _FormClassState();
}

class _FormClassState extends State<FormClass> {
  String? selectedValue;
  DateTime date = DateTime.now();

  // Form controllers for better data management
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Map-related state variables
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(
    44.9778,
    -93.2650,
  ); // Minneapolis, MN default
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _markers = [];
  bool _isSearching = false;

  // Image picker related variables
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    // Initialize with default marker
    _addMarker(_selectedLocation);
  }

  static const List<Map<String, String>> _itemsData = [
    {'id': '1', 'label': 'Sightseeing'},
    {'id': '2', 'label': 'Museum'},
    {'id': '3', 'label': 'Transport'},
    {'id': '4', 'label': 'City Walk'},
    {'id': '5', 'label': 'Landmark'},
    {'id': '6', 'label': 'Tour'},
    {'id': '7', 'label': 'Accommodation'},
    {'id': '8', 'label': 'Sports'},
    {'id': '9', 'label': 'Neighborhood'},
    {'id': '10', 'label': 'Food/Sightseeing'},
    {'id': '11', 'label': 'Museum/Art'},
    {'id': '12', 'label': 'Park'},
    {'id': '13', 'label': 'Food'},
    {'id': '14', 'label': 'Shopping/Landmark'},
    {'id': '15', 'label': 'Landmark/Park'},
    {'id': '16', 'label': 'Art/Neighborhood'},
    {'id': '17', 'label': 'Market/Food'},
    {'id': '18', 'label': 'Family'},
    {'id': '19', 'label': 'Food/Experience'},
    {'id': '20', 'label': 'Museum/Food'},
    {'id': '21', 'label': 'Market'},
  ];

  List<Map<String, String>> get items => _itemsData;

  String _formatDate(DateTime date) {
    // Custom date formatting to avoid web compatibility issues
    const List<String> monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    String month = monthNames[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
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

  void _submitForm() async {
    // Validate required fields
    if (_activityNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an activity name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an activity category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show saving indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Saving trip activity...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Get selected category name
      final selectedCategory = items.firstWhere(
        (item) => item['id'] == selectedValue,
        orElse: () => {'id': '', 'label': 'Unknown'},
      );

      // Prepare image paths (convert XFile paths to strings)
      List<String> imagePaths = _selectedImages
          .map((image) => image.path)
          .toList();

      // Create TripActivity object
      final tripActivity = TripActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        activityName: _activityNameController.text.trim(),
        location: _locationController.text.trim(),
        category: selectedCategory['label'] ?? 'Unknown',
        categoryId: selectedValue!,
        estimatedCost: double.tryParse(_costController.text.trim()),
        date: date,
        notes: _notesController.text.trim(),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        imagePaths: imagePaths,
        createdAt: DateTime.now(),
      );

      // Save to storage
      bool saved = await TripActivityStorage.saveTripActivity(tripActivity);

      if (saved) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Trip activity saved successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate back to home screen
          Navigator.of(context).pop();
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Failed to save trip activity'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error saving: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Photos'),
          content: const Text('Choose how you want to add photos:'),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImageFromCamera();
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImages();
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addMarker(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = [
        Marker(
          point: location,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
        ),
      ];
    });
  }

  Future<List<LocationSuggestion>> _searchLocations(String query) async {
    if (query.length < 3) return [];

    setState(() {
      _isSearching = true;
    });

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&addressdetails=1',
        ),
        headers: {
          'User-Agent':
              'TripManiaApp/1.0 (tripmania@example.com)', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suggestions = data
            .map((item) => LocationSuggestion.fromJson(item))
            .toList();

        setState(() {
          _isSearching = false;
        });

        return suggestions;
      }
    } catch (e) {
      debugPrint('Error searching locations: $e');
    }

    setState(() {
      _isSearching = false;
    });

    return [];
  }

  void _selectLocation(LocationSuggestion suggestion) {
    _mapController.move(suggestion.location, 13.0);
    _addMarker(suggestion.location);
    _searchController.text = suggestion.displayName;
  }

  void _showMapSearchDialog() {
    final dialogSearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Location'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<LocationSuggestion>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.length < 3) {
                    return const Iterable<LocationSuggestion>.empty();
                  }
                  return await _searchLocations(textEditingValue.text);
                },
                displayStringForOption: (LocationSuggestion option) =>
                    option.displayName,
                onSelected: (LocationSuggestion selection) {
                  _selectLocation(selection);
                  Navigator.of(context).pop();
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                      dialogSearchController.text = controller.text;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Enter location name...',
                          border: OutlineInputBorder(),
                        ),
                        onEditingComplete: onEditingComplete,
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option.displayName,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _activityNameController.dispose();
    _locationController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.add_location_alt,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add New Trip Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fill in the details below to create your trip memory',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Activity Name Field
            _buildSectionTitle('Activity Details', Icons.event),
            const SizedBox(height: 12),
            TextField(
              controller: _activityNameController,
              decoration: InputDecoration(
                labelText: 'Activity Name *',
                hintText: 'e.g., Visit Minnehaha Falls',
                prefixIcon: const Icon(
                  Icons.local_activity,
                  color: Colors.blue,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Field
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location Name',
                hintText: 'e.g., Minneapolis, MN',
                prefixIcon: const Icon(Icons.place, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  hint: const Row(
                    children: [
                      Icon(Icons.category, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Select Activity Category *'),
                    ],
                  ),
                  isExpanded: true,
                  items: items.isNotEmpty
                      ? items.map<DropdownMenuItem<String>>((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'],
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(item['label'] ?? ''),
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(item['label'] ?? ''),
                              ],
                            ),
                          );
                        }).toList()
                      : <DropdownMenuItem<String>>[],
                  onChanged: (value) {
                    setState(() {
                      selectedValue = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cost and Date Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Estimated Cost',
                      hintText: '\$25.00',
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Colors.blue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.0),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null && pickedDate != date) {
                            setState(() {
                              date = pickedDate;
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDate(date),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location Section
            _buildSectionTitle('Location Details', Icons.location_on),
            const SizedBox(height: 12),
            const Text(
              "Search for the exact location and pin it on the map below:",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Autocomplete<LocationSuggestion>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.length < 3) {
                      return const Iterable<LocationSuggestion>.empty();
                    }
                    return await _searchLocations(textEditingValue.text);
                  },
                  displayStringForOption: (LocationSuggestion option) =>
                      option.displayName,
                  onSelected: (LocationSuggestion selection) {
                    _selectLocation(selection);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                        _searchController.text = controller.text;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Search Location',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.search),
                          ),
                          onEditingComplete: onEditingComplete,
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: Container(
                          width: MediaQuery.of(context).size.width - 32,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option.displayName,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                height: 200,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation,
                          initialZoom: 13.0,
                          onTap: (tapPosition, point) {
                            _addMarker(point);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.tripmania.app',
                          ),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
                    ),
                    // Search button on the map
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FloatingActionButton.small(
                        heroTag: "map_search_btn",
                        onPressed: () {
                          _showMapSearchDialog();
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.search, color: Colors.blue),
                      ),
                    ),
                    // Zoom controls
                    Positioned(
                      top: 60,
                      right: 10,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: "map_zoom_in_btn",
                            onPressed: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1,
                              );
                            },
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.add, color: Colors.blue),
                          ),
                          const SizedBox(height: 4),
                          FloatingActionButton.small(
                            heroTag: "map_zoom_out_btn",
                            onPressed: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom - 1,
                              );
                            },
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.remove, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Additional Information Section
            _buildSectionTitle('Additional Information', Icons.note_add),
            const SizedBox(height: 16),

            // Image Upload Section
            _selectedImages.isEmpty
                ? Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(
                        color: Colors.blue.shade200,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.0),
                        onTap: _showImagePickerDialog,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Colors.blue.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photos',
                              style: TextStyle(
                                color: Colors.blue.shade400,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Tap to capture memories of your trip',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Photos (${_selectedImages.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showImagePickerDialog,
                            icon: const Icon(Icons.add_a_photo, size: 20),
                            label: const Text('Add More'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: kIsWeb
                                          ? FutureBuilder<Uint8List>(
                                              future: _selectedImages[index]
                                                  .readAsBytes(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Image.memory(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                } else {
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                            )
                                          : Image.network(
                                              _selectedImages[index].path,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),

            // Notes Field
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes & Memories',
                hintText:
                    'Share your experience, tips, or memorable moments...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.edit_note, color: Colors.blue),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {
                    _submitForm();
                  },
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Save Trip Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
