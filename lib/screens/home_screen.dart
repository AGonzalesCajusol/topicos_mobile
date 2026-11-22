import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons, CupertinoTabBar;
import 'package:material_ui/material_ui.dart';
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

  void _showProfileSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        final first = _text(widget.employee['first_name'], 'Conductor');
        final last = _text(widget.employee['last_name'], '');
        final fullName = '$first $last'.trim();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu cuenta',
                  style: TextStyle(
                    color: _cream,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3ED),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        CupertinoIcons.person_fill,
                        color: _green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: _cream,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Conductor · Sesión activa',
                            style: TextStyle(color: _muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _loggingOut
                        ? null
                        : () {
                            Navigator.of(sheetContext).pop();
                            _logout();
                          },
                    icon: const Icon(CupertinoIcons.square_arrow_right),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB3423D),
                      side: const BorderSide(color: Color(0xFFE9D2D0)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _text(dynamic value, [String fallback = 'Sin información']) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = _text(widget.employee['first_name'], 'Conductor');
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
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3EC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(CupertinoIcons.leaf_arrow_circlepath, color: _green, size: 24),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RSU  ·  OPERACIONES',
                              style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hola, $name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _cream, fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mis recorridos',
                        style: TextStyle(color: _cream, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.55),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _todayOnly ? 'Tu programación asignada para hoy.' : 'Consulta tus servicios y su estado.',
                        style: const TextStyle(color: _muted, fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3ED),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(CupertinoIcons.info_circle, color: _green, size: 21),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Text(
                            'El recorrido se habilita cuando todo el personal registra su asistencia y estás dentro del horario permitido.',
                            style: TextStyle(color: Color(0xFF315541), fontSize: 13, height: 1.45, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
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
                      separatorBuilder: (_, _) => const SizedBox(height: 15),
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
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: _surface,
        activeColor: _green,
        inactiveColor: _muted,
        currentIndex: _todayOnly ? 0 : 1,
        onTap: (index) {
          if (index == 0) {
            _changeFilter(true);
          } else if (index == 1) {
            _changeFilter(false);
          } else {
            _showProfileSheet();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), label: 'Recorridos'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_crop_circle), label: 'Perfil'),
        ],
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
      color: selected ? _green : const Color(0xFFF0F3F0),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _green : _border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? Colors.white : _cream, fontSize: 13, fontWeight: FontWeight.w700),
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
    final statusColor = routeFinished || routeStarted ? _green : _pending;
    final ready = item['can_start_route'] == true;
    final canFinish = item['can_finish_route'] == true;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 18, offset: Offset(0, 5)),
            ],
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
          SizedBox(width: 76, child: Text(label, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(color: _cream, fontSize: 13, fontWeight: FontWeight.w600, height: 1.35))),
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
