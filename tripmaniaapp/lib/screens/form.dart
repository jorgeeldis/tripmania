import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Map-related state variables
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(
    44.9778,
    -93.2650,
  ); // Minneapolis, MN default
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _markers = [];
  bool _isSearching = false;

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
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Activity Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedValue,
              hint: const Text('Select Option'),
              isExpanded: true,
              items: items.isNotEmpty
                  ? items.map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item['id'],
                        child: Text(item['label'] ?? ''),
                      );
                    }).toList()
                  : <DropdownMenuItem<String>>[],
              onChanged: (value) {
                setState(() {
                  selectedValue = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Estimated Cost',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                _formatDate(date), // Use custom formatting method
                style: const TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () async {
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
            ),
            const SizedBox(height: 16),
            const Text(
              "Please search for the location on the map below:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            const Text('Image'),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(
                child: Text(
                  'Image upload functionality to be implemented',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle form submission
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Submit',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
