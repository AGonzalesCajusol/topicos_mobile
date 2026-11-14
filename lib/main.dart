import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const DriverApp());

const _green = Color(0xFF2E9B65);
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
                      child: const Icon(Icons.local_shipping_rounded,
                          color: _green, size: 42),
                    ),
                    const SizedBox(height: 34),
                    Text('Bienvenido, conductor',
                        style: GoogleFonts.inter(
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                            color: _dark)),
                    const SizedBox(height: 9),
                    const Text(
                      'Modo demostración: puedes ingresar sin validar credenciales.',
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
                          'DNI (opcional para la demostración)', Icons.badge_outlined),
                      validator: (value) =>
                          value == null || !RegExp(r'^\d{8}$').hasMatch(value.trim())
                              ? 'El DNI debe tener 8 dígitos'
                              : null,
                    ),
                    SizedBox(height: 20),
                    _FieldLabel('Contraseña'),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      onFieldSubmitted: (_) => _continue(),
                      decoration: _inputDecoration(
                        'Contraseña (opcional para la demostración)',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(_hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingresa tu contraseña'
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
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('Entrar a la demostración',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    SizedBox(height: 28),
                    Center(
                      child: Text('Sistema de Gestión de Residuos Sólidos',
                          style: TextStyle(color: _muted, fontSize: 12)),
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

InputDecoration _inputDecoration(String hint, IconData icon) =>
    InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E9E4))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E9E4))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.5)),
    );

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: _dark, fontWeight: FontWeight.w700, fontSize: 14)),
      );
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardTab(),
      const _ScheduleTab(),
      const _HistoryTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del conductor',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            ),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) =>
            setState(() => _selectedIndex = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), label: 'Agenda'),
          NavigationDestination(
              icon: Icon(Icons.history_rounded), label: 'Historial'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _dark,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TU JORNADA',
                  style: TextStyle(
                      color: Color(0xFF9CCBB0),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 10),
              const Text('¡Hola, conductor!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Aquí puedes gestionar tu recorrido del día.',
                  style: TextStyle(color: Color(0xFFD0DED6))),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF9CCBB0), size: 17),
                  SizedBox(width: 8),
                  Text('Programaciones asignadas',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text('Accesos rápidos',
            style: TextStyle(
                color: _dark, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        _ActionTile(
          icon: Icons.assignment_outlined,
          title: 'Mis programaciones',
          subtitle: 'Consulta tus fechas y horarios asignados',
          onTap: () => _open(context, 'Mis programaciones',
              'Aquí se mostrarán las programaciones asignadas al conductor.'),
        ),
        _ActionTile(
          icon: Icons.today_outlined,
          title: 'Programaciones del día',
          subtitle: 'Revisa las actividades de hoy',
          onTap: () => _open(context, 'Programaciones del día',
              'Aquí se listarán las programaciones correspondientes a hoy.'),
        ),
        _ActionTile(
          icon: Icons.fact_check_outlined,
          title: 'Validar asistencias',
          subtitle: 'Registra y consulta las asistencias',
          onTap: () => _open(context, 'Validar asistencias',
              'La validación se conectará con el servicio de asistencias.'),
        ),
        _ActionTile(
          icon: Icons.route_outlined,
          title: 'Recorrido en curso',
          subtitle: 'Visualiza y registra tu ubicación durante la ruta',
          accent: true,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ActiveRouteScreen())),
        ),
        _ActionTile(
          icon: Icons.flag_outlined,
          title: 'Finalizar recorrido',
          subtitle: 'Registra observaciones y confirma el cierre',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FinishRouteScreen())),
        ),
        _ActionTile(
          icon: Icons.map_outlined,
          title: 'Visualizar recorrido',
          subtitle: 'Consulta la trayectoria registrada',
          onTap: () => _open(context, 'Visualizar recorrido',
              'Aquí se mostrará el mapa con la trayectoria del recorrido.'),
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
        margin: const EdgeInsets.only(bottom: 11),
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0xFFE8EEEA))),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          leading: Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: accent
                  ? _green.withValues(alpha: .14)
                  : const Color(0xFFF0F5F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _green),
          ),
          title: Text(title,
              style: const TextStyle(
                  color: _dark, fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle,
                style: const TextStyle(color: _muted, fontSize: 12)),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
          onTap: onTap,
        ),
      );
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context) => const _InfoPage(
        title: 'Mis programaciones',
        description:
            'En esta sección aparecerán tus programaciones asignadas. La fecha y hora serán de solo lectura para el conductor.',
        icon: Icons.calendar_month_outlined,
      );
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) => const _InfoPage(
        title: 'Historial de recorridos',
        description:
            'Aquí podrás consultar tus recorridos anteriores y abrir el detalle de cada trayectoria.',
        icon: Icons.history_rounded,
      );
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
                detail: 'El mapa se habilitará con la ubicación GPS.'),
            const SizedBox(height: 18),
            const _StatusCard(
                icon: Icons.gps_fixed_rounded,
                title: 'Registro de ubicación',
                detail:
                    'La especificación solicita registrar la ubicación cada 5 segundos durante el recorrido.'),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FinishRouteScreen())),
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Finalizar recorrido'),
              style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  minimumSize: const Size.fromHeight(52)),
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
                detail:
                    'Antes de confirmar, registra cualquier observación sobre el servicio.'),
            const SizedBox(height: 22),
            const _FieldLabel('Observaciones'),
            TextField(
              controller: _observation,
              maxLines: 5,
              decoration: _inputDecoration(
                  'Escribe una observación (opcional)',
                  Icons.edit_note_rounded),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('¿Confirmar finalización?'),
                  content: const Text(
                      'Se enviará la solicitud de cierre del recorrido.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar')),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Pantalla lista; falta conectar el servicio de cierre.')),
                        );
                      },
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              ),
              style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  minimumSize: const Size.fromHeight(52)),
              child: const Text('Confirmar finalización'),
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
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _dark,
                      fontWeight: FontWeight.w800,
                      fontSize: 21)),
              const SizedBox(height: 9),
              Text(description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, height: 1.5)),
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
        Text(label,
            style: const TextStyle(
                color: _dark, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(detail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12)),
        ),
      ],
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard(
      {required this.icon, required this.title, required this.detail});
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
                  Text(title,
                      style: const TextStyle(
                          color: _dark, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(detail,
                      style: const TextStyle(
                          color: _muted, fontSize: 13, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      );
}

void _open(BuildContext context, String title, String description) {
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
