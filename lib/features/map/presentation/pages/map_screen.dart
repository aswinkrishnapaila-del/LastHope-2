import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../dependency_injection.dart';
import '../../data/overpass_service.dart';
import '../../../connectivity/mesh_service.dart';

// CONFIGURATION:
// Using OpenFreeMap (Free, no API key required)

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final OverpassService _overpassService = OverpassService();

  bool _permissionGranted = false;
  LatLng? _currentPosition;
  StreamSubscription? _meshSubscription;
  final List<Marker> _markers = [];
  final List<CircleMarker> _circles = [];
  bool _isLoadingPois = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _setupMeshListener();
  }

  @override
  void dispose() {
    _meshSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        _permissionGranted = true;
      });
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = latLng;

        // Clear previous safe zone
        _circles.clear();

        // Add Safe Zone Circle (500m radius)
        _circles.add(
          CircleMarker(
            point: _currentPosition!,
            radius: 500,
            useRadiusInMeter: true,
            color: Colors.green.withValues(alpha: 0.2),
            borderColor: Colors.green,
            borderStrokeWidth: 2,
          ),
        );
      });

      // Move camera
      _mapController.move(_currentPosition!, 15);

      // Fetch POIs
      _fetchPois(latLng);
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  double _calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  List<MapPoi> get _sortedPois {
    if (_currentPosition == null) return [];
    final pois = _markers
        .where((m) => m.key is ValueKey<MapPoi>)
        .map((m) => (m.key as ValueKey<MapPoi>).value)
        .toList();
    
    // Sort by distance from current position
    pois.sort((a, b) {
      double distA = _calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, a.lat, a.lon);
      double distB = _calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, b.lat, b.lon);
      return distA.compareTo(distB);
    });
    return pois;
  }

  Future<void> _fetchPois(LatLng center) async {
    setState(() => _isLoadingPois = true);
    try {
      final pois = await _overpassService.fetchNearbyEmergencyServices(center);
      setState(() {
        _markers.clear(); // Clear old markers
        for (var poi in pois) {
          _markers.add(
            Marker(
              key: ValueKey<MapPoi>(poi),
              point: LatLng(poi.lat, poi.lon),
              width: 45,
              height: 45,
              child: GestureDetector(
                onTap: () => _showPoiDetails(poi),
                child: _getPoiIcon(poi.type),
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint("Error fetching POIs: $e");
    } finally {
      setState(() => _isLoadingPois = false);
    }
  }

  Widget _getPoiIcon(String type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'hospital':
        icon = Icons.add; // The "+" sign in the screenshot
        color = Colors.red[600]!;
        break;
      case 'police':
        icon = Icons.shield;
        color = Colors.blue[800]!;
        break;
      case 'fire_station':
        icon = Icons.local_fire_department;
        color = Colors.orange[800]!;
        break;
      default:
        icon = Icons.place;
        color = Colors.grey;
    }

    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  void _showPoiDetails(MapPoi poi) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 150,
          color: Colors.grey[900],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poi.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                poi.type.toUpperCase().replaceAll('_', ' '),
                style: const TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchNavigation(poi.lat, poi.lon);
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text("Navigate"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final Uri url = Uri.parse("google.navigation:q=$lat,$lng");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback for non-Android or if scheme fails: standard detailed URL
      final Uri webUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
      );
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _setupMeshListener() {
    _meshSubscription = sl<MeshService>().statusStream.listen((status) {
      if (status.contains("Found SOS Beacon")) {
        _addRescuerMarker();
      }
    });
  }

  void _showNearbyServicesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sortedPois = _sortedPois;
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.local_hospital, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text(
                      "Nearby Emergency Services (${sortedPois.length})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, indent: 16, endIndent: 16),
              Expanded(
                child: sortedPois.isEmpty 
                  ? const Center(
                      child: Text(
                        "No nearby services found.\nTry refreshing.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                  itemCount: sortedPois.length,
                  itemBuilder: (context, index) {
                    final poi = sortedPois[index];
                    final distance = _calculateDistance(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      poi.lat,
                      poi.lon,
                    );

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: _getPoiIcon(poi.type),
                        title: Text(
                          poi.name,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.directions_walk, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                "${(distance).toStringAsFixed(0)} m away",
                                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  poi.type.toUpperCase(),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () => _launchNavigation(poi.lat, poi.lon),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addRescuerMarker() {
    if (_currentPosition == null) return;
    // Simulate a rescuer nearby
    final peerPos = LatLng(
      _currentPosition!.latitude + 0.001,
      _currentPosition!.longitude + 0.001,
    );

    setState(() {
      _markers.add(
        Marker(
          point: peerPos,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Location Permission Needed",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPermission,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Grant Permission"),
            ),
          ],
        ),
      );
    }

    if (_currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Help"),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _getCurrentLocation(),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition!,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lasthope.app',
                maxZoom: 19.0,
              ),
              CircleLayer(circles: _circles),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blueAccent,
                      size: 40,
                    ),
                  ),
                  ..._markers,
                ],
              ),
            ],
          ),
          
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'presentLocationMapBtn',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (_currentPosition != null) {
                      _mapController.move(_currentPosition!, 15);
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  heroTag: 'nearbyServicesBtn',
                  backgroundColor: Colors.red[700],
                  onPressed: _showNearbyServicesSheet,
                  icon: const Icon(Icons.local_hospital, color: Colors.white),
                  label: const Text('Nearby Services', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          
          if (_isLoadingPois)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      ),
                      SizedBox(width: 12),
                      Text("Scanning for nearby help...", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
