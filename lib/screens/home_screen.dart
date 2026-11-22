import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/programming_service.dart';
import 'programming_detail_screen.dart';
import '../theme/app_theme.dart';

const _background = AppColors.background;
const _surface = AppColors.surface;
const _border = AppColors.border;
const _cream = AppColors.text;
const _muted = AppColors.muted;
const _green = AppColors.green;
const _pending = AppColors.muted;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.employee,
    required this.onLogout,
  });

  final Map<String, dynamic> employee;
  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _todayOnly = true;
  String _routeFilter = 'Todos';
  late Future<Map<String, dynamic>> _programmingFuture;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProgramaciones();
  }

  void _loadProgramaciones() {
    _programmingFuture = _todayOnly
        ? ProgrammingService.today()
        : ProgrammingService.all();
  }

  void _changeFilter(bool today) {
    if (_todayOnly == today) return;
    setState(() {
      _todayOnly = today;
      _routeFilter = 'Todos';
      _loadProgramaciones();
    });
  }

  void _changeRouteFilter(String filter) {
    if (_routeFilter == filter) return;
    setState(() => _routeFilter = filter);
  }

  Future<void> _refresh() async {
    setState(_loadProgramaciones);
    try {
      await _programmingFuture;
    } catch (_) {
      // El mensaje de error se muestra en la lista.
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await widget.onLogout();
  }

  String _text(dynamic value, [String fallback = 'Sin información']) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = _text(widget.employee['first_name'], 'Conductor');
    final lastName = _text(widget.employee['last_name'], '');
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _green,
          backgroundColor: _surface,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.recycling_rounded, color: Colors.white, size: 29),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RSU · RECORRIDOS', style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 1.3, fontWeight: FontWeight.w700)),
                            Text('$name $lastName'.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _cream, fontSize: 17, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _loggingOut ? null : _logout,
                        tooltip: 'Cerrar sesión',
                        icon: const Icon(Icons.logout_rounded, color: _muted),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFEAF5ED), Color(0xFFFFFFFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tu jornada', style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        const Text('Organiza tu recorrido.', style: TextStyle(color: _cream, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(_todayOnly ? 'Estas son las programaciones asignadas para hoy.' : 'Consulta todos los recorridos que tienes asignados.', style: const TextStyle(color: _muted, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(child: _FilterButton(label: 'Programaciones de hoy', selected: _todayOnly, onTap: () => _changeFilter(true))),
                      const SizedBox(width: 9),
                      Expanded(child: _FilterButton(label: 'Todos mis recorridos', selected: !_todayOnly, onTap: () => _changeFilter(false))),
                    ],
                  ),
                ),
              ),
              if (!_todayOnly)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in const ['Todos', 'Pendientes', 'En curso', 'Finalizados']) ...[
                            _FilterButton(
                              label: filter,
                              selected: _routeFilter == filter,
                              onTap: () => _changeRouteFilter(filter),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              FutureBuilder<Map<String, dynamic>>(
                future: _programmingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator(color: _green)),
                    );
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    final message = error is ApiException
                        ? error.message
                        : 'No se pudieron cargar las programaciones. Revisa tu conexión.';
                    if (error is ApiException && error.statusCode == 401) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) widget.onLogout();
                      });
                    }
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'No se pudo cargar la información',
                        message: message,
                        action: 'Volver a intentar',
                        onTap: () => setState(_loadProgramaciones),
                      ),
                    );
                  }

                  final response = snapshot.data ?? {};
                  final items = (response['data'] as List?) ?? [];
                  final filteredItems = items.where((raw) {
                    if (_todayOnly || _routeFilter == 'Todos') return true;
                    if (raw is! Map) return false;
                    final routeStarted = raw['route_started'] == true;
                    final routeFinished = raw['route_finished'] == true;
                    switch (_routeFilter) {
                      case 'En curso':
                        return routeStarted && !routeFinished;
                      case 'Finalizados':
                        return routeFinished;
                      case 'Pendientes':
                        return !routeStarted && !routeFinished;
                      default:
                        return true;
                    }
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        icon: Icons.event_available_rounded,
                        title: items.isEmpty
                            ? (_todayOnly ? 'Hoy no tienes recorridos' : 'Aún no tienes recorridos')
                            : 'No hay recorridos en este filtro',
                        message: items.isEmpty
                            ? (_todayOnly
                                ? 'No hay recorridos asignados para el día de hoy.'
                                : 'Cuando administración te asigne un recorrido, aparecerá en esta sección.')
                            : 'Prueba con otro estado para consultar tus recorridos.',
                        action: 'Actualizar',
                        onTap: () => setState(_loadProgramaciones),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    sliver: SliverList.separated(
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = Map<String, dynamic>.from(filteredItems[index] as Map);
                        final programmingId = int.tryParse(item['id'].toString());
                        return _ProgrammingCard(
                          item: item,
                          today: _todayOnly,
                          text: _text,
                          onTap: programmingId == null
                              ? () {}
                              : () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ProgrammingDetailScreen(
                                            programmingId: programmingId,
                                          ),
                                        ),
                                      )
                                      .then((_) {
                                        if (mounted) _refresh();
                                      });
                                },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _green : _surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _green : _border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? Colors.white : _cream, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _ProgrammingCard extends StatelessWidget {
  const _ProgrammingCard({
    required this.item,
    required this.today,
    required this.text,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final bool today;
  final String Function(dynamic, [String]) text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final people = (item['people'] as List?) ?? [];
    final days = (item['days'] as List?)?.join(' · ') ?? '';
    final routeStarted = item['route_started'] == true;
    final routeFinished = item['route_finished'] == true;
    final status = routeFinished
        ? 'Finalizado'
        : routeStarted
            ? 'Iniciado'
            : text(item['status'], 'Programado');
    final statusColor = routeStarted && !routeFinished ? _green : _pending;
    final ready = item['can_start_route'] == true;
    final canFinish = item['can_finish_route'] == true;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'RECORRIDO #${text(item['id'])}',
                      style: const TextStyle(
                        color: _green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      status,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _InfoLine(
                icon: Icons.calendar_today_rounded,
                label: 'Fecha',
                value: text(item['date'], days.isEmpty ? 'Sin fecha' : days),
              ),
              _InfoLine(icon: Icons.map_rounded, label: 'Zona', value: text(item['zone'])),
              _InfoLine(icon: Icons.local_shipping_rounded, label: 'Vehículo', value: text(item['vehicle'])),
              _InfoLine(icon: Icons.pin_rounded, label: 'Placa', value: text(item['plate'])),
              _InfoLine(
                icon: Icons.schedule_rounded,
                label: 'Turno',
                value: '${text(item['shift'])} · ${text(item['hours'], 'Horario no definido')}',
              ),
              if (item['notes'] != null && item['notes'].toString().trim().isNotEmpty)
                _InfoLine(
                  icon: Icons.notes_rounded,
                  label: 'Indicaciones',
                  value: text(item['notes']),
                ),
              if (today && people.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: _border),
                Row(
                  children: [
                    const Text(
                      'Equipo de trabajo',
                      style: TextStyle(
                        color: _cream,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${item['present_count'] ?? 0} de ${people.length} presentes',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ...people.map((raw) {
                  final person = Map<String, dynamic>.from(raw as Map);
                  final attended = person['attended'] == true;
                  final role = person['role'] == 'driver' ? 'Conductor' : 'Ayudante';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(
                          attended ? Icons.check_circle_rounded : Icons.schedule_rounded,
                          color: attended ? _green : _pending,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text(person['name']),
                            style: const TextStyle(
                              color: _cream,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$role · ${text(person['attendance_status'], 'Pendiente')}',
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }),
                if (routeStarted && canFinish)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_circle_fill_rounded, color: _green, size: 17),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recorrido iniciado. Recuerda finalizarlo al terminar el servicio.',
                            style: TextStyle(
                              color: _green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (ready)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: _green, size: 17),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estás dentro del horario para iniciar el recorrido.',
                            style: TextStyle(
                              color: _green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              const Divider(color: _border),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver detalle de programación',
                    style: TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: _green, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _muted, size: 17),
          const SizedBox(width: 9),
          SizedBox(width: 84, child: Text(label, style: const TextStyle(color: _muted, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: _cream, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message, required this.action, required this.onTap});
  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 35, 30, 35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: _muted),
            const SizedBox(height: 15),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _cream, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13, height: 1.5)),
            const SizedBox(height: 18),
            TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(color: _green, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}
