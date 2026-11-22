import 'package:latlong2/latlong.dart';

/// Removes only exact consecutive GPS coordinate repetitions.
/// Any coordinate change is kept, regardless of distance.
List<LatLng> deduplicateConsecutiveRoutePoints(Iterable<LatLng> locations) {
  final accepted = <LatLng>[];

  for (final point in locations) {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude < -90 ||
        point.latitude > 90 ||
        point.longitude < -180 ||
        point.longitude > 180) {
      continue;
    }

    if (accepted.isNotEmpty &&
        accepted.last.latitude == point.latitude &&
        accepted.last.longitude == point.longitude) {
      continue;
    }

    accepted.add(point);
  }

  return List<LatLng>.unmodifiable(accepted);
}
