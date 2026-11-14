import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/programming_service.dart';

const _pageBackground = Color(0xFFF3F6FA);
const _panel = Color(0xFFFFFFFF);
const _panelBorder = Color(0xFFE1E8F0);
const _primaryText = Color(0xFF1F2937);
const _secondaryText = Color(0xFF64748B);
const _accent = Color(0xFF1267B3);
const _success = Color(0xFF16845B);
const _warning = Color(0xFFB7791F);

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

  @override
  void initState() {
    super.initState();
    _loadDetail();
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
        backgroundColor: const Color(0xFF1267B3),
        foregroundColor: Colors.white,
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
          final complete = data['complete'] == true;

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
                    onPressed: () {
                      final message = canStart
                          ? 'El detalle está disponible. Falta conectar el endpoint para iniciar el recorrido.'
                          : 'El recorrido se habilitará cuando el equipo complete su asistencia.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1674D1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'INICIAR RECORRIDO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  canStart
                      ? 'El equipo cumple las condiciones de asistencia.'
                      : 'Falta registrar la asistencia de todo el personal.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _secondaryText, fontSize: 11),
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
    final color = complete ? _success : _warning;
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
    final statusColor = attended ? _success : _warning;
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
