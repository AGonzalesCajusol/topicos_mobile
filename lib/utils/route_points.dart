import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

const double minimumRouteMovementMeters = 15.0;

/// Removes consecutive GPS samples that do not represent a meaningful movement.
///
/// Only compares each candidate with the last accepted point. Returning to a
/// previously visited place later in the route is therefore preserved.
List<LatLng> deduplicateConsecutiveRoutePoints(
  Iterable<LatLng> locations, {
  double minimumMovementMeters = minimumRouteMovementMeters,
}) {
  if (!minimumMovementMeters.isFinite || minimumMovementMeters < 0) {
    throw ArgumentError.value(
      minimumMovementMeters,
      'minimumMovementMeters',
      'Must be a finite, non-negative distance.',
    );
  }

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
        _distanceInMeters(accepted.last, point) <= minimumMovementMeters) {
      continue;
    }

    accepted.add(point);
  }

  return List<LatLng>.unmodifiable(accepted);
}

double _distanceInMeters(LatLng first, LatLng second) {
  const earthRadiusMeters = 6371000.0;
  final latitude1 = first.latitude * math.pi / 180;
  final latitude2 = second.latitude * math.pi / 180;
  final latitudeDelta = (second.latitude - first.latitude) * math.pi / 180;
  final longitudeDelta = (second.longitude - first.longitude) * math.pi / 180;
  final sinLatitude = math.sin(latitudeDelta / 2);
  final sinLongitude = math.sin(longitudeDelta / 2);
  final value = sinLatitude * sinLatitude +
      math.cos(latitude1) * math.cos(latitude2) * sinLongitude * sinLongitude;

  return earthRadiusMeters *
      2 *
      math.asin(math.sqrt(value.clamp(0.0, 1.0)));
}
