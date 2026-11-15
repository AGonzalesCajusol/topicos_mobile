import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../services/programming_service.dart';
import '../theme/app_theme.dart';

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

class _ProgrammingDetailScreenState extends State<ProgrammingDetailScreen> {
  late Future<Map<String, dynamic>> _detailFuture;
  Timer? _availabilityTimer;
  bool _starting = false;
  bool _finishing = false;
  bool _locating = false;
  bool _locationAttempted = false;
  Position? _currentPosition;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadDetail();

    // Actualiza el permiso mientras la pantalla está abierta, para habilitar
    // el botón al llegar la hora de inicio sin exigir que el usuario recargue.
    _availabilityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshDetail(),
    );
  }

  @override
  void dispose() {
    _availabilityTimer?.cancel();
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

      // Primero se guarda el inicio en Laravel. La ubicación es un paso visual
      // posterior: si el permiso GPS se deniega, el recorrido sigue iniciado.
      await _refreshDetail();
      await _captureCurrentLocation();
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
    final pending = (total - present).clamp(0, total);
    final allAttended = data['complete'] == true;

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
                'Confirmar inicio',
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
            Text(
              allAttended
                  ? 'Todo el personal ha registrado su asistencia. Puedes iniciar el recorrido.'
                  : total == 0
                      ? 'No hay personal registrado en esta programación. Puedes continuar con el inicio del recorrido.'
                      : 'Hay $pending ${pending == 1 ? 'persona pendiente' : 'personas pendientes'} de asistencia. Puedes iniciar el recorrido, pero verifica que el equipo esté listo.',
              style: const TextStyle(
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

  Future<void> _captureCurrentLocation() async {
    if (_locating || !mounted) return;

    _locationAttempted = true;
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Activa la ubicación del dispositivo para mostrar el mapa.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('No se concedió el permiso para acceder a la ubicación.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'El permiso de ubicación está bloqueado. Actívalo desde los ajustes del dispositivo o del navegador.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      if (!mounted) return;
      setState(() => _currentPosition = position);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationError = error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'No se pudo obtener tu ubicación. Inténtalo nuevamente.';
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Widget _locationMapCard() {
    final position = _currentPosition;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _panelBorder),
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
                child: const Icon(Icons.my_location_rounded, color: _success, size: 19),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu ubicación actual',
                      style: TextStyle(
                        color: _primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Posición obtenida mediante el GPS',
                      style: TextStyle(color: _secondaryText, fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualizar ubicación',
                onPressed: _locating ? null : _captureCurrentLocation,
                icon: const Icon(Icons.refresh_rounded, color: _success),
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (_locating)
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _success),
                    SizedBox(height: 12),
                    Text(
                      'Obteniendo tu ubicación...',
                      style: TextStyle(color: _secondaryText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else if (position == null)
            Container(
              height: 190,
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off_rounded, color: _secondaryText, size: 30),
                  const SizedBox(height: 9),
                  Text(
                    _locationError ?? 'Aún no se ha podido obtener tu ubicación.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _secondaryText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _captureCurrentLocation,
                    icon: const Icon(Icons.gps_fixed_rounded, size: 17),
                    label: const Text('Intentar nuevamente'),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                height: 245,
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      key: ValueKey('${position.latitude}_${position.longitude}'),
                      options: MapOptions(
                        initialCenter: LatLng(position.latitude, position.longitude),
                        initialZoom: 16,
                        minZoom: 3,
                        maxZoom: 19,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _mapTileUrl,
                          userAgentPackageName: 'com.example.doctor',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(position.latitude, position.longitude),
                              width: 48,
                              height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
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
          if (position != null && !_locating) ...[
            const SizedBox(height: 9),
            Text(
              'Lat. ${position.latitude.toStringAsFixed(5)}  ·  Lon. ${position.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
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
    try {
      final response = await ProgrammingService.finish(widget.programmingId);
      if (!mounted) return;

      final message = response['message']?.toString()
          ?? 'Recorrido finalizado correctamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _refreshDetail();
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
          'Programación de hoy',
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

          if (routeStarted && !routeFinished &&
              !_locationAttempted && !_locating && _currentPosition == null &&
              _locationError == null) {
            _locationAttempted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _captureCurrentLocation();
            });
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
                if (routeStarted && !routeFinished) ...[
                  const SizedBox(height: 14),
                  _locationMapCard(),
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
