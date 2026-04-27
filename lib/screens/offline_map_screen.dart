import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../constants/app_colors.dart';
import '../providers/trip_provider.dart';

class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({super.key});

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentPosition;
  LatLng? _destinationPosition;
  bool _isLoading = true;
  bool _isTracking = false;
  String _errorMessage = '';
  bool _mapReady = false;
  bool _isSearching = false;
  List<SearchResult> _searchResults = [];
  List<LatLng> _searchMarkers = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Get destination location first
    await _getDestinationLocation();
    // Then get current location
    await _initializeLocation();
  }

  Future<void> _getDestinationLocation() async {
    try {
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      final trip = tripProvider.currentTrip;

      if (trip != null && trip.destinationCountry.isNotEmpty) {
        // Geocode the destination country
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(trip.destinationCountry)}&format=json&limit=1',
        );

        final response = await http.get(
          url,
          headers: {'User-Agent': 'TravelCompanionApp/1.0'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            setState(() {
              _destinationPosition = LatLng(lat, lon);
            });
            debugPrint('Destination location set: $lat, $lon for ${trip.destinationCountry}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error geocoding destination: $e');
      // Continue with default location if geocoding fails
    }
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them.';
          _isLoading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permissions are permanently denied. Enable them in settings.';
          _isLoading = false;
        });
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location request timed out. Please ensure GPS is enabled and try again.');
        },
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      }

      // Move map to current location - will be handled by initialCenter in MapOptions
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapReady) {
      try {
        final zoom = _mapController.camera.zoom;
        _mapController.move(_currentPosition!, zoom);
      } catch (e) {
        // If camera is not initialized yet, just skip
        debugPrint('Error centering location: $e');
      }
    }
  }

  void _toggleTracking() async {
    if (_isTracking) {
      setState(() => _isTracking = false);
    } else {
      setState(() => _isTracking = true);
      // Start listening to location updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (_isTracking && mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          if (_isTracking && _mapReady) {
            try {
              final zoom = _mapController.camera.zoom;
              _mapController.move(_currentPosition!, zoom);
            } catch (e) {
              // If camera is not initialized yet, just skip
              debugPrint('Error moving map during tracking: $e');
            }
          }
        }
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      // Use Nominatim (OpenStreetMap) geocoding API
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'TravelCompanionApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((item) {
          return SearchResult(
            name: item['display_name'] ?? '',
            lat: double.parse(item['lat']),
            lon: double.parse(item['lon']),
          );
        }).toList();

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _selectSearchResult(SearchResult result) {
    final location = LatLng(result.lat, result.lon);
    setState(() {
      _searchMarkers = [location];
      _searchResults = [];
      _searchController.clear();
    });

    if (_mapReady) {
      _mapController.move(location, 15.0);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Offline Map & GPS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.lightGradient,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPink,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Getting your location...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 80,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _initializeLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Geolocator.openLocationSettings();
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Settings'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryPink,
                            side: const BorderSide(color: AppColors.primaryPink),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _destinationPosition ?? _currentPosition ?? const LatLng(0, 0),
                initialZoom: _destinationPosition != null ? 6.0 : 15.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                onMapReady: () {
                  setState(() {
                    _mapReady = true;
                  });
                  debugPrint('Map is ready');
                },
              ),
              children: [
                // Map tiles from OpenStreetMap
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.travel_companion',
                  // Tiles will be cached automatically by the browser/platform
                ),
                // Markers for current location and search results
                MarkerLayer(
                  markers: [
                    // Destination marker
                    if (_destinationPosition != null)
                      Marker(
                        point: _destinationPosition!,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.flag,
                          color: AppColors.primaryPurple,
                          size: 45,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    // Current location marker
                    if (_currentPosition != null)
                      Marker(
                        point: _currentPosition!,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    // Search result markers
                    ..._searchMarkers.map(
                      (location) => Marker(
                        point: location,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primaryPink,
                          size: 50,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          // Search bar at top
          if (!_isLoading)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search places...',
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: AppColors.primaryPink),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryPink,
                                      ),
                                    ),
                                  ),
                                )
                              : _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchResults = [];
                                          _searchMarkers = [];
                                        });
                                      },
                                    )
                                  : null,
                        ),
                        onSubmitted: _searchPlaces,
                      ),
                    ),
                  ),
                  // Search results dropdown
                  if (_searchResults.isNotEmpty)
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(top: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_on,
                              color: AppColors.primaryPink,
                              size: 20,
                            ),
                            title: Text(
                              result.name,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(result),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Control buttons at bottom right
          if (!_isLoading && _errorMessage.isEmpty)
            Positioned(
              bottom: 24,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Center on location button
                  FloatingActionButton(
                    heroTag: 'center',
                    onPressed: _centerOnCurrentLocation,
                    backgroundColor: AppColors.white,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primaryPink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Track location button
                  FloatingActionButton(
                    heroTag: 'track',
                    onPressed: _toggleTracking,
                    backgroundColor:
                        _isTracking ? AppColors.primaryPink : AppColors.white,
                    child: Icon(
                      _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                      color: _isTracking ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Zoom in button
                  FloatingActionButton(
                    heroTag: 'zoom_in',
                    mini: true,
                    onPressed: () {
                      if (_mapReady) {
                        try {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        } catch (e) {
                          debugPrint('Error zooming in: $e');
                        }
                      }
                    },
                    backgroundColor: AppColors.white,
                    child: const Icon(
                      Icons.add,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Zoom out button
                  FloatingActionButton(
                    heroTag: 'zoom_out',
                    mini: true,
                    onPressed: () {
                      if (_mapReady) {
                        try {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        } catch (e) {
                          debugPrint('Error zooming out: $e');
                        }
                      }
                    },
                    backgroundColor: AppColors.white,
                    child: const Icon(
                      Icons.remove,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SearchResult {
  final String name;
  final double lat;
  final double lon;

  SearchResult({
    required this.name,
    required this.lat,
    required this.lon,
  });
}
