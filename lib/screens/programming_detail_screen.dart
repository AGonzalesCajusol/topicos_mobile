import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../services/programming_service.dart';
import '../theme/app_theme.dart';
import '../utils/route_points.dart';


const _pageBackground = AppColors.background;
const _panel = AppColors.surface;
const _panelBorder = AppColors.border;
const _primaryText = AppColors.text;
const _secondaryText = AppColors.muted;
const _accent = AppColors.green;
const _success = AppColors.green;
const _pending = AppColors.muted;
const _mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

class ProgrammingDetailScreen extends StatefulWidget {
  const ProgrammingDetailScreen({
    super.key,
    required this.programmingId,
  });

  final int programmingId;

  @override
  State<ProgrammingDetailScreen> createState() => _ProgrammingDetailScreenState();
}

class _ProgrammingDetailScreenState extends State<ProgrammingDetailScreen>
    with WidgetsBindingObserver {
  late Future<Map<String, dynamic>> _detailFuture;
  final MapController _mapController = MapController();
  Timer? _availabilityTimer;
  Timer? _trackingTimer;
  Timer? _routeRefreshTimer;
  final List<LatLng> _routePoints = [];
  bool _routeLoading = false;
  bool _routeLoaded = false;
  bool _routeIsFinished = false;
  bool _starting = false;
  bool _finishing = false;
  bool _locating = false;
  bool _trackingStarting = false;
  bool _trackingAttempted = false;
  bool _sendingLocation = false;
  bool _mapReady = false;
  bool _appIsForeground = true;
  Position? _currentPosition;
  String? _locationError;
  String? _locationSyncMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDetail();
    _startAvailabilityRefresh();
  }

  void _startAvailabilityRefresh() {
    _availabilityTimer?.cancel();
    _availabilityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshDetail(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appIsForeground = true;
      _trackingAttempted = false;
      _startAvailabilityRefresh();
      _refreshDetail();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _appIsForeground = false;
      _availabilityTimer?.cancel();
      _availabilityTimer = null;
      _stopLocationTracking();
      _trackingAttempted = false;
      _stopRouteRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _availabilityTimer?.cancel();
    _stopLocationTracking();
    _stopRouteRefresh();
    super.dispose();
  }

  Future<void> _refreshDetail() async {
    if (!mounted) return;
    setState(_loadDetail);
    try {
      await _detailFuture;
    } catch (_) {
      // La pantalla muestra el error si la consulta no se completa.
    }
  }

  Future<void> _startRoute(Map<String, dynamic> data) async {
    if (_starting) return;

    final confirmed = await _confirmStartRoute(data);
    if (!confirmed || !mounted) return;

    setState(() => _starting = true);
    try {
      final response = await ProgrammingService.start(widget.programmingId);
      if (!mounted) return;

      final message = response['message']?.toString()
          ?? 'Recorrido iniciado correctamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      // El detalle confirma el inicio y activa el envío GPS cada 5 segundos.
      // Si el permiso de ubicación se deniega, el recorrido sigue abierto.
      await _refreshDetail();
      await _startLocationTracking();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      await _refreshDetail();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar el recorrido. Inténtalo nuevamente.')),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<bool> _confirmStartRoute(Map<String, dynamic> data) async {
    final people = (data['people'] as List? ?? []);
    final total = people.length;
    final present = (data['present_count'] as num?)?.toInt() ?? 0;
    final missingPeople = people
        .whereType<Map>()
        .where((person) => person['attended'] != true)
        .map((person) => person['name']?.toString() ?? 'Personal sin nombre')
        .toList();
    final allAttended = data['complete'] == true &&
        people.isNotEmpty &&
        missingPeople.isEmpty;

    // Protección adicional en Flutter: aun con datos antiguos en pantalla,
    // jamás se envía la petición de inicio si falta una asistencia.
    if (!allAttended) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _panel,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _panelBorder),
          ),
          title: const Text(
            'Personal pendiente',
            style: TextStyle(
              color: _primaryText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No puedes iniciar el recorrido hasta que todo el personal asignado registre su asistencia.',
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              if (missingPeople.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...missingPeople.map(
                  (name) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFFD98B24),
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: _primaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _panelBorder),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (allAttended ? _success : const Color(0xFFD98B24))
                    .withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                allAttended ? Icons.groups_rounded : Icons.group_outlined,
                color: allAttended ? _success : const Color(0xFFD98B24),
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Text(
                'Todo el personal ha asistido',
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: _success.withOpacity(.09),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _success.withOpacity(.18)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.how_to_reg_rounded, color: _success, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '$present de $total personas con asistencia',
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Todo el personal asignado ha registrado su asistencia. Puedes iniciar el recorrido.',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> _startLocationTracking({bool retry = false}) async {
    if (!mounted || !_appIsForeground ||
        _trackingTimer != null || _trackingStarting ||
        (_trackingAttempted && !retry)) {
      return;
    }

    _trackingAttempted = true;
    _trackingStarting = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Activa la ubicación del dispositivo para iniciar el seguimiento.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Debes conceder permiso de ubicación para enviar las posiciones del recorrido.',
        );
      }

      if (!mounted || !_appIsForeground) return;

      setState(() {
        _locationError = null;
        _locationSyncMessage = 'Seguimiento activo: envío automático cada 5 segundos.';
      });

      // No se crean solicitudes simultáneas. Si un ciclo tarda más de 5 segundos,
      // se omite ese tick y se continúa en el siguiente.
      _trackingTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _captureAndSendLocation(),
      );

      await _captureAndSendLocation();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationError = error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'No se pudo activar el seguimiento de ubicación.';
        _locationSyncMessage = 'Seguimiento detenido. Revisa el GPS y vuelve a intentarlo.';
      });
      _stopLocationTracking();
    } finally {
      _trackingStarting = false;
    }
  }

  void _stopLocationTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  void _stopRouteRefresh() {
    _routeRefreshTimer?.cancel();
    _routeRefreshTimer = null;
  }

  void _syncRouteRefresh(bool routeStarted, bool routeFinished) {
    if (!routeStarted) {
      _stopRouteRefresh();
      return;
    }

    if (routeFinished || !_appIsForeground) {
      _stopRouteRefresh();
      if (routeFinished && !_routeLoaded && !_routeLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _refreshRoutePoints();
        });
      }
      return;
    }

    if (_routeRefreshTimer == null) {
      _refreshRoutePoints();
      _routeRefreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refreshRoutePoints(),
      );
    }
  }

  Future<void> _refreshRoutePoints() async {
    if (!mounted || _routeLoading) return;
    _routeLoading = true;

    try {
      final response = await ProgrammingService.routeLocations(widget.programmingId);
      final rawData = response['data'];
      final rawLocations = rawData is Map ? rawData['locations'] : null;
      final rawPoints = <LatLng>[];

      if (rawLocations is List) {
        for (final raw in rawLocations) {
          if (raw is! Map) continue;
          final latitude = double.tryParse(raw['latitude']?.toString() ?? '');
          final longitude = double.tryParse(raw['longitude']?.toString() ?? '');
          if (latitude == null || longitude == null) continue;
          rawPoints.add(LatLng(latitude, longitude));
        }
      }

      // Limpia también historiales antiguos. Solo conserva una lectura nueva
      // cuando existe desplazamiento real respecto al último punto aceptado.
      final points = deduplicateConsecutiveRoutePoints(rawPoints);

      if (!mounted) return;
      final routeChanged = points.length != _routePoints.length ||
          List.generate(
            points.length < _routePoints.length ? points.length : _routePoints.length,
            (index) => index,
          ).any((index) =>
              points[index].latitude != _routePoints[index].latitude ||
              points[index].longitude != _routePoints[index].longitude);

      if (routeChanged || !_routeLoaded) {
        setState(() {
          _routePoints
            ..clear()
            ..addAll(points);
          _routeLoaded = true;
        });
      }

      if (_mapReady && points.isNotEmpty && (routeChanged || _routeIsFinished)) {
        if (_routeIsFinished && points.length > 1) {
          _mapController.fitCamera(
            CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.all(42),
            ),
          );
        } else {
          final liveCenter = _currentPosition == null
              ? points.last
              : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
          _mapController.move(liveCenter, 16);
        }
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _locationSyncMessage = error.message);
    } catch (_) {
      // El mapa conserva los puntos que ya había cargado.
    } finally {
      _routeLoading = false;
    }
  }

  Future<void> _refreshLocation() async {
    if (_trackingTimer == null) {
      await _startLocationTracking(retry: true);
    } else {
      await _captureAndSendLocation();
    }
  }

  Future<void> _captureAndSendLocation() async {
    if (!mounted || !_appIsForeground || _sendingLocation) return;

    _sendingLocation = true;
    final firstPosition = _currentPosition == null;
    if (firstPosition) {
      setState(() {
        _locating = true;
        _locationError = null;
      });
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      if (!mounted) return;

      setState(() => _currentPosition = position);
      if (_mapReady) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          16,
        );
      }

      final response = await ProgrammingService.sendLocation(
        widget.programmingId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      if (!mounted) return;

      final stored = response['stored'] == true;
      final minimumDistance =
          (response['minimum_distance_meters'] as num?)?.toStringAsFixed(0) ?? '5';
      setState(() {
        _locationError = null;
        _locationSyncMessage = stored
            ? 'Ubicación guardada en el servidor.'
            : 'Punto repetido o muy cercano (menos de ${minimumDistance} m). Se conserva el anterior.';
      });

      // Solo se incorpora al trazo lo que Laravel confirmó como guardado.
      if (stored) await _refreshRoutePoints();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _locationSyncMessage = error.message;
      });

      // El servidor responde 409 cuando el recorrido ya está cerrado.
      if (error.statusCode == 409) {
        _stopLocationTracking();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationError = _currentPosition == null
            ? (error is Exception
                ? error.toString().replaceFirst('Exception: ', '')
                : 'No se pudo obtener tu ubicación.')
            : null;
        _locationSyncMessage = 'No se pudo enviar esta posición. Se volverá a intentar.';
      });
    } finally {
      _sendingLocation = false;
      if (mounted && _locating) setState(() => _locating = false);
    }
  }

  double _routeDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0;
    const earthRadiusKm = 6371.0;
    var total = 0.0;
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final latitudeDelta = (current.latitude - previous.latitude) * math.pi / 180;
      final longitudeDelta = (current.longitude - previous.longitude) * math.pi / 180;
      final previousLatitude = previous.latitude * math.pi / 180;
      final currentLatitude = current.latitude * math.pi / 180;
      final a = math.pow(math.sin(latitudeDelta / 2), 2) +
          math.cos(previousLatitude) * math.cos(currentLatitude) *
              math.pow(math.sin(longitudeDelta / 2), 2);
      final safeA = a.clamp(0.0, 1.0);
      total += earthRadiusKm * 2 * math.asin(math.sqrt(safeA));
    }
    return total;
  }

  Widget _locationMapCard({required bool routeFinished, bool expanded = false}) {
    final position = _currentPosition;
    final route = List<LatLng>.unmodifiable(_routePoints);
    final mapCenter = position != null
        ? LatLng(position.latitude, position.longitude)
        : route.isNotEmpty
            ? route.last
            : null;

    Widget pointMarker(Color color, IconData icon) => Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.2),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        );

    final markers = <Marker>[];
    if (route.isNotEmpty) {
      markers.add(
        Marker(
          point: route.first,
          width: 36,
          height: 36,
          child: pointMarker(_success, Icons.flag_rounded),
        ),
      );
      if (route.length > 1) {
        markers.add(
          Marker(
            point: route.last,
            width: 38,
            height: 38,
            child: pointMarker(
              routeFinished ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
              routeFinished ? Icons.flag_rounded : Icons.navigation_rounded,
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _panelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _success.withOpacity(.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.route_rounded, color: _success, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeFinished ? 'Recorrido realizado' : 'Recorrido en tiempo real',
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      routeFinished
                          ? 'Historial de ubicaciones registradas'
                          : 'Actualizando la ruta cada 5 segundos',
                      style: const TextStyle(color: _secondaryText, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (!routeFinished)
                IconButton(
                  tooltip: 'Actualizar recorrido',
                  onPressed: _routeLoading ? null : _refreshRoutePoints,
                  icon: const Icon(Icons.refresh_rounded, color: _success),
                ),
            ],
          ),
          const SizedBox(height: 11),
          if (mapCenter == null)
            Container(
              height: expanded ? 330 : 210,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _routeLoading ? Icons.sync_rounded : Icons.route_outlined,
                        color: _secondaryText,
                        size: 30,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        _routeLoading
                            ? 'Cargando los puntos del recorrido...'
                            : routeFinished
                                ? 'Este recorrido no tiene ubicaciones GPS guardadas.'
                                : 'Esperando la primera ubicación confirmada por el servidor.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _secondaryText,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                height: expanded ? 330 : (routeFinished ? 360 : 265),
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: mapCenter,
                        initialZoom: 14,
                        minZoom: 3,
                        maxZoom: 19,
                        interactionOptions: const InteractionOptions(
                          // El gesto vertical queda libre para desplazar la pantalla.
                          // El usuario conserva zoom por doble toque o pellizco.
                          flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                        ),
                        onMapReady: () {
                          _mapReady = true;
                          if (_routeIsFinished && route.length > 1) {
                            _mapController.fitCamera(
                              CameraFit.coordinates(
                                coordinates: route,
                                padding: const EdgeInsets.all(42),
                              ),
                            );
                          } else if (position != null) {
                            _mapController.move(mapCenter, 16);
                          } else if (route.isNotEmpty) {
                            _mapController.move(route.last, 16);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _mapTileUrl,
                          userAgentPackageName: 'com.example.doctor',
                        ),
                        if (route.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: route,
                                strokeWidth: 5,
                                color: _success,
                              ),
                            ],
                          ),
                        if (markers.isNotEmpty)
                          MarkerLayer(markers: markers),
                        if (position != null && !routeFinished)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(position.latitude, position.longitude),
                                width: 44,
                                height: 44,
                                child: pointMarker(
                                  const Color(0xFFF59E0B),
                                  Icons.navigation_rounded,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      right: 7,
                      bottom: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.94),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(color: Color(0xFF333333), fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${route.length} puntos aceptados por el servidor',
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!routeFinished)
                const Text(
                  'EN VIVO',
                  style: TextStyle(
                    color: _success,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                )
              else
                const Text(
                  'HISTÓRICO',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _RouteMetric(label: 'DISTANCIA', value: '${_routeDistanceKm(route).toStringAsFixed(2)} km', icon: Icons.route_rounded)),
              const SizedBox(width: 9),
              Expanded(child: _RouteMetric(label: 'PUNTOS GPS', value: route.length.toString(), icon: Icons.my_location_rounded)),
            ],
          ),
          if (position != null && !routeFinished) ...[
            const SizedBox(height: 5),
            Text(
              'GPS actual: ${position.latitude.toStringAsFixed(5)} · ${position.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_locationSyncMessage != null) ...[
            const SizedBox(height: 5),
            Text(
              _locationSyncMessage!,
              style: TextStyle(
                color: _locationSyncMessage!.contains('No se pudo')
                    ? const Color(0xFFB45309)
                    : _success,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _activeRouteFooter({
    required bool canFinish,
    required String message,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 9),
        decoration: BoxDecoration(
          color: _panel,
          border: Border(top: BorderSide(color: _panelBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.045),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _starting || _finishing || !canFinish ? null : _finishRoute,
                icon: _finishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.flag_rounded, size: 19),
                label: Text(
                  _finishing ? 'FINALIZANDO RECORRIDO…' : 'FINALIZAR RECORRIDO',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .35),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.surfaceSoft,
                  disabledForegroundColor: AppColors.muted,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _secondaryText, fontSize: 10, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishRoute() async {
    if (_finishing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar recorrido'),
        content: const Text(
          '¿Confirmas que el recorrido ha terminado? Esta acción cerrará la programación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continuar recorrido'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _finishing = true);
    _stopLocationTracking();

    // Espera a que termine una petición GPS previa antes de capturar el punto final.
    while (_sendingLocation && mounted) {
      await Future.delayed(const Duration(milliseconds: 150));
    }

    double? finalLatitude;
    double? finalLongitude;
    double? finalAccuracy;
    String? finalLocationWarning;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        finalLocationWarning = 'GPS desactivado; se finalizará sin punto final.';
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          finalLocationWarning = 'No se obtuvo permiso GPS; se finalizará sin punto final.';
        } else {
          final finalPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 25),
            ),
          );
          finalLatitude = finalPosition.latitude;
          finalLongitude = finalPosition.longitude;
          finalAccuracy = finalPosition.accuracy;
          if (mounted) {
            setState(() => _currentPosition = finalPosition);
          }
        }
      }
    } catch (_) {
      finalLocationWarning = 'No se pudo obtener el último GPS; se finalizará sin punto final.';
    }

    try {
      final response = await ProgrammingService.finish(
        widget.programmingId,
        latitude: finalLatitude,
        longitude: finalLongitude,
        accuracy: finalAccuracy,
      );
      if (!mounted) return;

      final message = response['message']?.toString()
          ?? 'Recorrido finalizado correctamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(finalLocationWarning == null
              ? message
              : '$message $finalLocationWarning"),
        ),
      );

      // El backend guarda el punto final en la misma transacción que el cierre.
      _stopLocationTracking();
      _stopRouteRefresh();
      _routeIsFinished = true;
      _routeLoaded = false;
      _mapReady = false;
      await _refreshDetail();
      if (!mounted) return;
      await _refreshRoutePoints();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      await _refreshDetail();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo finalizar el recorrido. Inténtalo nuevamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  void _loadDetail() {
    _detailFuture = ProgrammingService.detail(widget.programmingId);
  }

  String _value(dynamic value, [String fallback = 'Sin información']) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  String _formattedDate(dynamic rawDate) {
    final date = DateTime.tryParse(rawDate?.toString() ?? '');
    if (date == null) return 'Fecha no disponible';

    const weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo',
    ];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];

    return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _panel,
        foregroundColor: _primaryText,
        elevation: 0,
        title: const Text(
          'Detalle del recorrido',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _panelBorder),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'No se pudo cargar el detalle de la programación.';

            return _DetailError(
              message: message,
              onRetry: () => setState(_loadDetail),
            );
          }

          final response = snapshot.data ?? {};
          final rawData = response['data'];
          if (rawData is! Map) {
            return _DetailError(
              message: 'El servidor no devolvió el detalle esperado.',
              onRetry: () => setState(_loadDetail),
            );
          }

          final data = Map<String, dynamic>.from(rawData);
          final people = (data['people'] as List? ?? [])
              .whereType<Map>()
              .map((person) => Map<String, dynamic>.from(person))
              .toList();
          final helpers = people
              .where((person) => person['role'] != 'driver')
              .map((person) => _value(person['name']))
              .toList();
          final canStart = data['can_start_route'] == true;
          final routeStarted = data['route_started'] == true;
          final routeFinished = data['route_finished'] == true;
          _routeIsFinished = routeFinished;
          final canFinish = data['can_finish_route'] == true;
          final startMessage = _value(
            data['start_message'],
            canStart
                ? 'Puedes iniciar el recorrido.'
                : 'El inicio todavía no está habilitado.',
          );
          final finishMessage = _value(
            data['finish_message'],
            'El recorrido debe finalizarse cuando termine el servicio.',
          );
          final actionMessage = routeStarted ? finishMessage : startMessage;
          final complete = data['complete'] == true;

          _syncRouteRefresh(routeStarted, routeFinished);

          if (routeStarted && !routeFinished &&
              _appIsForeground && _trackingTimer == null &&
              !_trackingStarting) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _startLocationTracking();
            });
          }

          if (routeStarted && !routeFinished) {
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: _accent,
                    backgroundColor: _panel,
                    onRefresh: _refreshDetail,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _DateTile(
                                date: _formattedDate(data['date']),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _success.withOpacity(.12),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: _success.withOpacity(.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.radio_button_checked_rounded,
                                    color: _success,
                                    size: 13,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'INICIADO',
                                    style: TextStyle(
                                      color: _success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _locationMapCard(
                          routeFinished: false,
                          expanded: true,
                        ),
                        const SizedBox(height: 12),
                        _DetailPanel(
                          children: [
                            _InfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'Zona',
                              value: _value(data['zone']),
                            ),
                            _InfoRow(
                              icon: Icons.local_shipping_rounded,
                              label: 'Vehículo',
                              value: _value(data['vehicle']),
                            ),
                            _InfoRow(
                              icon: Icons.confirmation_number_rounded,
                              label: 'Placa',
                              value: _value(data['plate']),
                            ),
                            _InfoRow(
                              icon: Icons.access_time_filled_rounded,
                              label: 'Turno',
                              value:
                                  '${_value(data['shift'])} · ${_value(data['hours'], 'Horario no definido')}',
                            ),
                            if (data['started_at'] != null)
                              _InfoRow(
                                icon: Icons.play_circle_outline_rounded,
                                label: 'Inicio',
                                value: _value(data['started_at']),
                              ),
                          ],
                        ),
                        if (_locationError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _locationError!,
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (_trackingAttempted &&
                            _trackingTimer == null &&
                            !_trackingStarting) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _refreshLocation,
                            icon: const Icon(Icons.my_location_rounded),
                            label: const Text('REINTENTAR GPS'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _success,
                              side: const BorderSide(color: _success),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                _activeRouteFooter(
                  canFinish: canFinish,
                  message: actionMessage,
                ),
              ],
            );
          }

          return RefreshIndicator(
            color: _accent,
            backgroundColor: _panel,
            onRefresh: () async {
              setState(_loadDetail);
              try {
                await _detailFuture;
              } catch (_) {
                // El estado de error se muestra en la pantalla.
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _DateTile(date: _formattedDate(data['date'])),
                const SizedBox(height: 12),
                _StatusBanner(
                  complete: complete,
                  present: (data['present_count'] as num?)?.toInt() ?? 0,
                  total: people.length,
                ),
                if (routeStarted) ...[
                  const SizedBox(height: 14),
                  _locationMapCard(routeFinished: routeFinished),
                ],
                const SizedBox(height: 14),
                _DetailPanel(
                  children: [
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Zona',
                      value: _value(data['zone']),
                    ),
                    _InfoRow(
                      icon: Icons.local_shipping_rounded,
                      label: 'Vehículo',
                      value: _value(data['vehicle']),
                    ),
                    _InfoRow(
                      icon: Icons.confirmation_number_rounded,
                      label: 'Placa',
                      value: _value(data['plate']),
                    ),
                    _InfoRow(
                      icon: Icons.people_alt_rounded,
                      label: 'Ayudantes',
                      value: helpers.isEmpty ? 'Sin ayudantes asignados' : helpers.join('\n'),
                    ),
                    _InfoRow(
                      icon: Icons.access_time_filled_rounded,
                      label: 'Turno',
                      value: '${_value(data['shift'])} (${_value(data['hours'], 'Horario no definido')})',
                    ),
                    if (data['started_at'] != null)
                      _InfoRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Inicio real',
                        value: _value(data['started_at']),
                      ),
                    if (data['finished_at'] != null)
                      _InfoRow(
                        icon: Icons.flag_circle_rounded,
                        label: 'Finalización',
                        value: _value(data['finished_at']),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Estado de asistencia del personal',
                        style: TextStyle(
                          color: _primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${data['present_count'] ?? 0}/${people.length}',
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DetailPanel(
                  children: people.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Todavía no hay personal asociado a esta programación.',
                              style: TextStyle(color: _secondaryText, fontSize: 12),
                            ),
                          ),
                        ]
                      : people.map((person) {
                          final isDriver = person['role'] == 'driver';
                          final attended = person['attended'] == true;
                          final status = _value(
                            person['attendance_status'],
                            'Pendiente',
                          );
                          final time = person['attendance_time'];

                          return _PersonAttendanceRow(
                            name: _value(person['name']),
                            role: isDriver ? 'Conductor (Tú)' : 'Ayudante',
                            status: status,
                            time: time?.toString(),
                            attended: attended,
                            isDriver: isDriver,
                          );
                        }).toList(),
                ),
                if (_value(data['notes'], '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DetailPanel(
                    children: [
                      _InfoRow(
                        icon: Icons.notes_rounded,
                        label: 'Indicaciones',
                        value: _value(data['notes']),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _starting || _finishing
                        ? null
                        : routeStarted
                            ? (canFinish ? _finishRoute : null)
                            : (canStart ? () => _startRoute(data) : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.surfaceSoft,
                      disabledForegroundColor: AppColors.muted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      _starting
                          ? 'INICIANDO RECORRIDO...'
                          : _finishing
                              ? 'FINALIZANDO RECORRIDO...'
                              : routeFinished
                                  ? 'RECORRIDO FINALIZADO'
                                  : routeStarted
                                      ? 'FINALIZAR RECORRIDO'
                                      : canStart
                                          ? 'INICIAR RECORRIDO'
                                          : 'INICIO NO DISPONIBLE',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  actionMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _success, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _secondaryText, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: .6)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: _primaryText, fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _panelBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: _accent, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              date,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.complete,
    required this.present,
    required this.total,
  });

  final bool complete;
  final int present;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = complete ? _success : _pending;
    final message = complete
        ? 'El equipo está completo'
        : 'Hay personal pendiente de asistencia';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(.28)),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.info_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$present/$total',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _panelBorder),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(color: _secondaryText, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonAttendanceRow extends StatelessWidget {
  const _PersonAttendanceRow({
    required this.name,
    required this.role,
    required this.status,
    required this.time,
    required this.attended,
    required this.isDriver,
  });

  final String name;
  final String role;
  final String status;
  final String? time;
  final bool attended;
  final bool isDriver;

  @override
  Widget build(BuildContext context) {
    final statusColor = attended ? _success : _pending;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            isDriver ? Icons.badge_rounded : Icons.person_rounded,
            color: _secondaryText,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(color: _secondaryText, fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(
            attended ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: statusColor,
            size: 17,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (time != null && time!.isNotEmpty)
                Text(
                  time!,
                  style: const TextStyle(color: _secondaryText, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _secondaryText, size: 42),
            const SizedBox(height: 14),
            const Text(
              'No se pudo cargar el detalle',
              style: TextStyle(
                color: _primaryText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 7),
            Text(
              message,
              style: const TextStyle(color: _secondaryText, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Volver a intentar',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
