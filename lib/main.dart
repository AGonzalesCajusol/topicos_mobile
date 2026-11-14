import 'features/programming/presentation/screens/my_program_schedules_screen.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const DriverApp());

const _green = Color(0xFF2E9B65);
const _institutionalBlue = Color(0xFF0D47A1);
const _dark = Color(0xFF14251F);
const _muted = Color(0xFF718078);
const _bg = Color(0xFFF4F7F5);

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conductor RSU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
        appBarTheme: const AppBarTheme(
          backgroundColor: _bg,
          foregroundColor: _dark,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dni = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _dni.dispose();
    _password.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 76,
                      width: 76,
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: _green,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'Bienvenido, conductor',
                      style: GoogleFonts.inter(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Modo demostraciÃ³n: puedes ingresar sin validar credenciales.',
                      style: TextStyle(color: _muted, height: 1.5),
                    ),
                    const SizedBox(height: 34),
                    const _FieldLabel('DNI'),
                    TextFormField(
                      controller: _dni,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        'DNI (opcional para la demostraciÃ³n)',
                        Icons.badge_outlined,
                      ),
                      validator: (value) =>
                          value == null ||
                              !RegExp(r'^\d{8}$').hasMatch(value.trim())
                          ? 'El DNI debe tener 8 dÃ­gitos'
                          : null,
                    ),
                    SizedBox(height: 20),
                    _FieldLabel('ContraseÃ±a'),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      onFieldSubmitted: (_) => _continue(),
                      decoration:
                          _inputDecoration(
                            'ContraseÃ±a (opcional para la demostraciÃ³n)',
                            Icons.lock_outline_rounded,
                          ).copyWith(
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingresa tu contraseÃ±a'
                          : null,
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _continue,
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Entrar a la demostraciÃ³n',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 28),
                    Center(
                      child: Text(
                        'Sistema de GestiÃ³n de Residuos SÃ³lidos',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
  hintText: hint,
  prefixIcon: Icon(icon, color: _muted),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE1E9E4)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE1E9E4)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: _green, width: 1.5),
  ),
);

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: _dark,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
  );
}

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
              backgroundColor: _institutionalBlue,
              foregroundColor: Colors.white,
              title: const Text(
                'Panel del conductor',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'Cerrar sesiÃ³n',
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  ),
                  icon: const Icon(Icons.logout_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: const SafeArea(child: _DashboardTab()),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _institutionalBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TU JORNADA',
                style: TextStyle(
                  color: Color(0xFF9CCBB0),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Â¡Hola, conductor!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'AquÃ­ puedes gestionar tu recorrido del dÃ­a.',
                style: TextStyle(color: Color(0xFFD0DED6)),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF9CCBB0),
                    size: 17,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Programaciones asignadas',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Accesos rÃ¡pidos',
          style: TextStyle(
            color: _dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.assignment_outlined,
          title: 'Mis programaciones',
          subtitle: 'Consulta tus fechas y horarios asignados',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MyProgramSchedulesScreen(),
            ),
          ),
        ),
        _ActionTile(
          icon: Icons.history_rounded,
          title: 'Historial de recorridos',
          subtitle: 'Consulta tus recorridos anteriores',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RouteHistoryScreen(),
            ),
          ),
        ),
        _ActionTile(
          icon: Icons.today_outlined,
          title: 'Programaciones del dÃ­a',
          subtitle: 'Revisa las actividades de hoy',
          onTap: () => _open(
            context,
            'Programaciones del dÃ­a',
            'AquÃ­ se listarÃ¡n las programaciones correspondientes a hoy.',
          ),
        ),
        _ActionTile(
          icon: Icons.fact_check_outlined,
          title: 'Validar asistencias',
          subtitle: 'Registra y consulta las asistencias',
          onTap: () => _open(
            context,
            'Validar asistencias',
            'La validaciÃ³n se conectarÃ¡ con el servicio de asistencias.',
          ),
        ),
        _ActionTile(
          icon: Icons.route_outlined,
          title: 'Recorrido en curso',
          subtitle: 'Visualiza y registra tu ubicaciÃ³n durante la ruta',
          accent: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActiveRouteScreen()),
          ),
        ),
        _ActionTile(
          icon: Icons.flag_outlined,
          title: 'Finalizar recorrido',
          subtitle: 'Registra observaciones y confirma el cierre',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FinishRouteScreen()),
          ),
        ),
        _ActionTile(
          icon: Icons.map_outlined,
          title: 'Visualizar recorrido',
          subtitle: 'Consulta la trayectoria registrada',
          onTap: () => _open(
            context,
            'Visualizar recorrido',
            'AquÃ­ se mostrarÃ¡ el mapa con la trayectoria del recorrido.',
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFE0E5E8)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent
              ? _institutionalBlue.withValues(alpha: .12)
              : const Color(0xFFF1F4F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _institutionalBlue, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _dark,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
      onTap: onTap,
    ),
  );
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context) {
    return const MyProgramSchedulesScreen();
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) => const RouteHistoryScreen();
}

class ActiveRouteScreen extends StatelessWidget {
  const ActiveRouteScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recorrido en curso')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _MapPlaceholder(
          label: 'Mapa del recorrido',
          detail: 'El mapa se habilitarÃ¡ con la ubicaciÃ³n GPS.',
        ),
        const SizedBox(height: 18),
        const _StatusCard(
          icon: Icons.gps_fixed_rounded,
          title: 'Registro de ubicaciÃ³n',
          detail: 'La especificaciÃ³n solicita registrar la ubicaciÃ³n cada 5 segundos durante el recorrido.',
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FinishRouteScreen()),
          ),
          icon: const Icon(Icons.flag_rounded),
          label: const Text('Finalizar recorrido'),
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    ),
  );
}

class FinishRouteScreen extends StatefulWidget {
  const FinishRouteScreen({super.key});

  @override
  State<FinishRouteScreen> createState() => _FinishRouteScreenState();
}

class _FinishRouteScreenState extends State<FinishRouteScreen> {
  final _observation = TextEditingController();

  @override
  void dispose() {
    _observation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Finalizar recorrido')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _StatusCard(
          icon: Icons.check_circle_outline_rounded,
          title: 'Cierre de recorrido',
          detail: 'Antes de confirmar, registra cualquier observaciÃ³n sobre el servicio.',
        ),
        const SizedBox(height: 22),
        const _FieldLabel('Observaciones'),
        TextField(
          controller: _observation,
          maxLines: 5,
          decoration: _inputDecoration(
            'Escribe una observaciÃ³n (opcional)',
            Icons.edit_note_rounded,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Â¿Confirmar finalizaciÃ³n?'),
              content: const Text(
                'Se enviarÃ¡ la solicitud de cierre del recorrido.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pantalla lista; falta conectar el servicio de cierre.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text('Confirmar finalizaciÃ³n'),
        ),
      ],
    ),
  );
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _green, size: 54),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _dark,
              fontWeight: FontWeight.w800,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.label, required this.detail});
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.map_outlined, size: 54, color: _green),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: _dark, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE5ECE7)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _green, size: 25),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _dark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                detail,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _open(BuildContext context, String title, String description) {
  if (title == 'Mis programaciones') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyProgramSchedulesScreen()),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: _InfoPage(
          title: title,
          description: description,
          icon: Icons.construction_rounded,
        ),
      ),
    ),
  );
}


// ======================================================
// HISTORIAL DE RECORRIDOS - DATOS MOCK
// ======================================================

class RouteHistoryScreen extends StatelessWidget {
  const RouteHistoryScreen({super.key});

  static const List<_HistoryRecord> records = [
    _HistoryRecord(
      date: '10 de noviembre de 2026',
      zone: 'Zona Norte',
      vehicle: 'Camión 01',
      plate: 'ABC-123',
      start: '06:00 a. m.',
      end: '01:45 p. m.',
      duration: '7 h 45 min',
    ),
    _HistoryRecord(
      date: '09 de noviembre de 2026',
      zone: 'Zona Centro',
      vehicle: 'Camión 03',
      plate: 'DEF-456',
      start: '02:00 p. m.',
      end: '09:30 p. m.',
      duration: '7 h 30 min',
    ),
    _HistoryRecord(
      date: '08 de noviembre de 2026',
      zone: 'Zona Sur',
      vehicle: 'Camión 05',
      plate: 'GHI-789',
      start: '06:15 a. m.',
      end: '01:50 p. m.',
      duration: '7 h 35 min',
    ),
    _HistoryRecord(
      date: '07 de noviembre de 2026',
      zone: 'Zona Norte',
      vehicle: 'Camión 01',
      plate: 'ABC-123',
      start: '10:00 p. m.',
      end: '05:40 a. m.',
      duration: '7 h 40 min',
    ),
    _HistoryRecord(
      date: '06 de noviembre de 2026',
      zone: 'Zona Centro',
      vehicle: 'Camión 03',
      plate: 'DEF-456',
      start: '02:10 p. m.',
      end: '09:40 p. m.',
      duration: '7 h 30 min',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: _institutionalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Historial de recorridos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          tooltip: 'Volver al panel',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          const Text(
            'Recorridos realizados',
            style: TextStyle(
              color: _dark,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Consulta el registro de tus servicios anteriores.',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: _institutionalBlue,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                '${records.length} recorridos registrados',
                style: const TextStyle(
                  color: _dark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          ...records.map(
            (record) => _HistoryRecordCard(
              record: record,
              onTap: () => _showDetails(context, record),
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Datos de demostración · Pendiente de conexión con el backend',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, _HistoryRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(21, 12, 21, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E5E8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 23),
                  const Text(
                    'Detalle del recorrido',
                    style: TextStyle(
                      color: _dark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    record.date,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const _HistoryStatus(),
                  const SizedBox(height: 20),
                  _HistoryDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Zona atendida',
                    value: record.zone,
                  ),
                  _HistoryDetailRow(
                    icon: Icons.local_shipping_outlined,
                    label: 'Vehículo',
                    value: record.vehicle,
                  ),
                  _HistoryDetailRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Placa',
                    value: record.plate,
                  ),
                  _HistoryDetailRow(
                    icon: Icons.play_circle_outline,
                    label: 'Hora de inicio',
                    value: record.start,
                  ),
                  _HistoryDetailRow(
                    icon: Icons.stop_circle_outlined,
                    label: 'Hora de finalización',
                    value: record.end,
                  ),
                  _HistoryDetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Duración',
                    value: record.duration,
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar detalle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryRecord {
  const _HistoryRecord({
    required this.date,
    required this.zone,
    required this.vehicle,
    required this.plate,
    required this.start,
    required this.end,
    required this.duration,
  });

  final String date;
  final String zone;
  final String vehicle;
  final String plate;
  final String start;
  final String end;
  final String duration;
}

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({
    required this.record,
    required this.onTap,
  });

  final _HistoryRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: _institutionalBlue,
                    size: 17,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      record.date,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: _muted,
                    size: 20,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFE0E5E8)),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.zone,
                      style: const TextStyle(
                        color: _dark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2EC),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Finalizado',
                      style: TextStyle(
                        color: Color(0xFF28734D),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: _muted,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${record.vehicle} · ${record.plate}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: _muted,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${record.start} - ${record.end}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                  Text(
                    record.duration,
                    style: const TextStyle(
                      color: _institutionalBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Consultar detalle',
                  style: TextStyle(
                    color: _institutionalBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryStatus extends StatelessWidget {
  const _HistoryStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2EC),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF28734D)),
          SizedBox(width: 10),
          Text(
            'Recorrido finalizado',
            style: TextStyle(
              color: Color(0xFF28734D),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDetailRow extends StatelessWidget {
  const _HistoryDetailRow({
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
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        children: [
          Icon(icon, color: _institutionalBlue, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _dark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


