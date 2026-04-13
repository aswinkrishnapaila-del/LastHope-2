import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OverpassService {
  /// Fetches nearby hospitals, police stations, and fire stations.
  /// [radius] in meters (default 5000m = 5km).
  Future<List<MapPoi>> fetchNearbyEmergencyServices(
    LatLng center, {
    int radius = 5000,
  }) async {
    // node, way, relation for services since hospitals are often ways/buildings
    final String query =
        '[out:json];nwr(around:$radius,${center.latitude},${center.longitude})["amenity"~"hospital|clinic|doctors|police|fire_station"];out center;';

    final Uri url = Uri.parse('https://overpass-api.de/api/interpreter');

    try {
      final response = await http.post(
        url,
        body: {'data': query},
        headers: {'User-Agent': 'LastHopeEmergencyApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List elements = data['elements'] ?? [];
        return elements.map<MapPoi>((e) {
          final lat = e['lat'] ?? (e['center'] != null ? e['center']['lat'] : 0.0);
          final lon = e['lon'] ?? (e['center'] != null ? e['center']['lon'] : 0.0);
          return MapPoi(
            lat: lat,
            lon: lon,
            name: e['tags']?['name'] ?? 'Unknown Service',
            type: e['tags']?['amenity'] ?? 'unknown',
          );
        }).toList();
      } else {
        throw Exception('Failed to load POIs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching POIs: $e');
    }
  }
}

class MapPoi {
  final double lat;
  final double lon;
  final String name;
  final String type; // 'hospital', 'police', 'fire_station'

  MapPoi({
    required this.lat,
    required this.lon,
    required this.name,
    required this.type,
  });
}
