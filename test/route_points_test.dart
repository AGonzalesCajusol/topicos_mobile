import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:doctor/utils/route_points.dart';

void main() {
  group('deduplicateConsecutiveRoutePoints', () {
    const origin = LatLng(-6.7800000, -79.8300000);

    test('discards exact repetitions and GPS drift below 15 metres', () {
      final points = deduplicateConsecutiveRoutePoints([
        origin,
        origin,
        const LatLng(-6.7799000, -79.8300000), // Approximately 11 m.
        const LatLng(-6.7798000, -79.8300000), // Approximately 22 m from origin.
      ]);

      expect(points, hasLength(2));
      expect(points.first.latitude, closeTo(origin.latitude, 0.0000001));
      expect(points.last.latitude, closeTo(-6.7798000, 0.0000001));
    });

    test('keeps points after a real movement greater than 15 metres', () {
      final points = deduplicateConsecutiveRoutePoints([
        origin,
        const LatLng(-6.7798000, -79.8300000),
      ]);

      expect(points, hasLength(2));
    });

    test('keeps a return to a previously visited location after moving away', () {
      final points = deduplicateConsecutiveRoutePoints([
        origin,
        const LatLng(-6.7798000, -79.8300000),
        origin,
      ]);

      expect(points, hasLength(3));
      expect(points.last.latitude, closeTo(origin.latitude, 0.0000001));
      expect(points.last.longitude, closeTo(origin.longitude, 0.0000001));
    });

    test('ignores invalid GPS coordinates', () {
      final points = deduplicateConsecutiveRoutePoints([
        origin,
        LatLng(double.nan, -79.8300000),
        const LatLng(91, -79.8300000),
        const LatLng(-6.7798000, -79.8300000),
      ]);

      expect(points, hasLength(2));
    });
  });
}
