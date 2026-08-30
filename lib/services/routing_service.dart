import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ev_charge_navigator/utils/constants.dart';

class RoutingService {
  /// Fetch a driving route from OSRM between two GPS coordinates.
  /// Returns a Map with 'distance' (km), 'duration' (minutes),
  /// 'geometry' (decoded polyline as list of lat/lng pairs),
  /// and 'steps' (list of instruction maps).
  Future<Map<String, dynamic>> getRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    final url = Uri.parse(
      '${AppConstants.osrmBaseUrl}/route/v1/driving/'
      '$startLng,$startLat;$endLng,$endLat'
      '?overview=full&geometries=polyline&steps=true&annotations=true',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('OSRM API error: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['code'] != 'Ok' || data['routes'] == null || (data['routes'] as List).isEmpty) {
        throw Exception('No route found between the specified locations.');
      }

      final route = data['routes'][0];
      final legs = route['legs'] as List;

      // Decode polyline geometry
      final geometry = _decodePolyline(route['geometry'] as String);

      // Extract turn-by-turn steps
      final steps = <Map<String, dynamic>>[];
      for (final leg in legs) {
        for (final step in leg['steps']) {
          final maneuver = step['maneuver'];
          steps.add({
            'instruction': _buildInstruction(
              maneuver['type'] ?? '',
              maneuver['modifier'] ?? '',
            ),
            'name': step['name'] ?? '',
            'distance': (step['distance'] ?? 0).toDouble(),
            'duration': (step['duration'] ?? 0).toDouble(),
          });
        }
      }

      return {
        'distance': (route['distance'] ?? 0).toDouble() / 1000.0, // meters to km
        'duration': (route['duration'] ?? 0).toDouble() / 60.0, // seconds to minutes
        'geometry': geometry,
        'steps': steps,
      };
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }

  /// Decode a Google-encoded polyline string into a list of [lat, lng] pairs.
  List<List<double>> _decodePolyline(String encoded) {
    final List<List<double>> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add([lat / 1e5, lng / 1e5]);
    }

    return points;
  }

  String _buildInstruction(String type, String modifier) {
    switch (type) {
      case 'depart':
        return 'Start your journey';
      case 'arrive':
        return 'You have arrived';
      case 'turn':
        return 'Turn ${modifier.isNotEmpty ? modifier : 'ahead'}';
      case 'continue':
        return 'Continue straight';
      case 'merge':
        return 'Merge ${modifier.isNotEmpty ? modifier : 'ahead'}';
      case 'fork':
        return 'Take the ${modifier.isNotEmpty ? modifier : ''} fork';
      case 'roundabout':
        return 'Enter the roundabout';
      case 'exit roundabout':
        return 'Exit the roundabout';
      case 'new name':
        return 'Continue onto new road';
      case 'end of road':
        return 'Turn ${modifier.isNotEmpty ? modifier : 'ahead'} at end of road';
      case 'notification':
        return modifier;
      default:
        return modifier.isNotEmpty
            ? '${type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : 'Continue'} $modifier'
            : 'Continue ahead';
    }
  }
}
