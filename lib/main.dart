import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() => runApp(const RsuApp());

// ---------- Paleta ----------
const bg = Color(0xFF10201C);
const bg2 = Color(0xFF0B1613);
const card = Color(0xFF182B26);
const line = Color(0xFF2C4A41);
const cream = Color(0xFFF4EFE3);
const muted = Color(0xFF9DB5AB);
const green = Color(0xFF7BE495);
const greenDark = Color(0xFF3FA863);
const yellow = Color(0xFFFFD25E);
const coral = Color(0xFFFF7A66);
const blue = Color(0xFF5AA9FF);
const ink = Color(0xFF0B1613);

TextStyle hand(double size, Color color) => GoogleFonts.caveat(
  fontSize: size,
  color: color,
  fontWeight: FontWeight.w700,
);

TextStyle display(
  double size,
  Color color, {
  FontWeight w = FontWeight.w800,
  double? h,
}) => GoogleFonts.bricolageGrotesque(
  fontSize: size,
  color: color,
  fontWeight: w,
  height: h,
);

class RsuApp extends StatelessWidget {
  const RsuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RSU Reciclaje',
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Map<String, dynamic>? _employee;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final employee = await AuthService.restoreSession();
      if (!mounted) return;
      setState(() {
        _employee = employee;
        _checking = false;
      });
    } catch (_) {
      await AuthService.logout();
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  void _onLogin(Map<String, dynamic> employee) {
    setState(() => _employee = employee);
  }

  Future<void> _onLogout() async {
    await AuthService.logout();
    if (mounted) setState(() => _employee = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    if (_employee == null) {
      // El login conserva su tema oscuro original; el resto de la app usa AppTheme.light.
      return Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: const ColorScheme.dark(primary: green),
        ),
        child: LoginScreen(onLogin: _onLogin),
      );
    }

    return HomeScreen(employee: _employee!, onLogout: _onLogout);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final ValueChanged<Map<String, dynamic>> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final employee = await AuthService.login(_user.text.trim(), _pass.text);
      if (mounted) widget.onLogin(employee);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: coral,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo conectar con el servidor. Revisa tu conexión.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: coral,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.3,
            colors: [Color(0xFF1C3A31), bg, bg2],
            stops: [0, .55, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Hero(),
                    const SizedBox(height: 8),
                    Text('Hola,\nconductor', style: display(42, cream, h: 1.0)),
                    Transform.rotate(
                      angle: -0.03,
                      child: Text('¡buen turno!', style: hand(44, green)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inicia sesión para consultar tus recorridos y horarios.',
                      style: display(15, muted, w: FontWeight.w500, h: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Correo electrónico'),
                          TextFormField(
                            controller: _user,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.email],
                            style: display(16, cream, w: FontWeight.w500),
                            decoration: _deco(
                              'Ingresa tu correo electrónico',
                              Icons.person_rounded,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa tu correo electrónico'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _label('Contraseña'),
                          TextFormField(
                            controller: _pass,
                            obscureText: _hide,
                            onFieldSubmitted: (_) => _login(),
                            autofillHints: const [AutofillHints.password],
                            style: display(16, cream, w: FontWeight.w500),
                            decoration:
                                _deco(
                                  'Ingresa tu contraseña',
                                  Icons.lock_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _hide ? 'Mostrar' : 'Ocultar',
                                    onPressed: () =>
                                        setState(() => _hide = !_hide),
                                    icon: Icon(
                                      _hide
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: muted,
                                    ),
                                  ),
                                ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Escribe tu contraseña'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          _PressButton(
                            label: _loading ? 'Iniciando sesión…' : 'Iniciar sesión',
                            onTap: _loading ? null : _login,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '¡Vamos a recorrer la ciudad!',
                            style: hand(24, yellow),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sistema de Gestión de Residuos Sólidos',
                            textAlign: TextAlign.center,
                            style: display(12.5, muted, w: FontWeight.w500),
                          ),
                        ],
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

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: display(14, cream, w: FontWeight.w700)),
  );

  InputDecoration _deco(String hint, IconData icon) {
    OutlineInputBorder b(Color c, [double w = 2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: display(15, const Color(0xFF6F8A7F), w: FontWeight.w500),
      prefixIcon: Icon(icon, color: muted),
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      errorStyle: display(13, coral, w: FontWeight.w600),
      border: b(line),
      enabledBorder: b(line),
      focusedBorder: b(green),
      errorBorder: b(coral),
      focusedErrorBorder: b(coral),
    );
  }
}

// ---------- Botón con efecto "presionable" ----------
class _PressButton extends StatefulWidget {
  const _PressButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final off = widget.onTap == null;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 58,
        width: double.infinity,
        margin: EdgeInsets.only(top: _down ? 4 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: off ? green.withValues(alpha: .7) : green,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: greenDark, offset: Offset(0, _down ? 1 : 5)),
          ],
        ),
        child: Text(widget.label, style: display(18, ink)),
      ),
    );
  }
}

// ---------- Hero con stickers ----------
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 255,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // chispas
          Positioned(
            right: 4,
            top: 6,
            child: CustomPaint(
              size: const Size(44, 44),
              painter: _SparkPainter(),
            ),
          ),
          // hoja
          Positioned(
            right: 52,
            top: 0,
            child: Transform.rotate(
              angle: 0.25,
              child: CustomPaint(
                size: const Size(70, 84),
                painter: _LeafPainter(),
              ),
            ),
          ),
          // sello de reciclaje
          Positioned(
            left: 26,
            top: 14,
            child: Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  size: 78,
                  color: ink,
                ),
              ),
            ),
          ),
          // washi tape
          Positioned(
            left: 56,
            top: 4,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 56,
                height: 22,
                decoration: BoxDecoration(
                  color: yellow.withValues(alpha: .85),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          // etiqueta
          Positioned(
            right: 0,
            top: 100,
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: yellow,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Text('¡Juntos reciclamos!', style: hand(23, ink)),
              ),
            ),
          ),
          // tacho
          Positioned(
            left: 0,
            bottom: 8,
            child: Transform.rotate(
              angle: -0.12,
              child: CustomPaint(
                size: const Size(72, 90),
                painter: _BinPainter(),
              ),
            ),
          ),
          // camión
          const Positioned(right: 0, bottom: 0, child: _Truck()),
        ],
      ),
    );
  }
}

class _Truck extends StatefulWidget {
  const _Truck();

  @override
  State<_Truck> createState() => _TruckState();
}

class _TruckState extends State<_Truck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      builder: (_, child) => Transform.translate(
        offset: Offset(-8 + 16 * _c.value, 0),
        child: child,
      ),
      child: CustomPaint(size: const Size(150, 90), painter: _TruckPainter()),
    );
  }
}

// ---------- Painters (stickers con borde blanco) ----------
void _stickerBase(Canvas c, Path p) {
  c.drawPath(
    p,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeJoin = StrokeJoin.round,
  );
  c.drawPath(p, Paint()..color = Colors.white);
}

Paint _fill(Color c) => Paint()..color = c;
Paint get _stroke => Paint()
  ..color = ink
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

class _TruckPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final box = RRect.fromLTRBR(4, 8, 92, 62, const Radius.circular(10));
    final cab = Path()
      ..moveTo(92, 22)
      ..lineTo(122, 22)
      ..lineTo(146, 44)
      ..lineTo(146, 62)
      ..lineTo(92, 62)
      ..close();
    final win = Path()
      ..moveTo(100, 29)
      ..lineTo(120, 29)
      ..lineTo(136, 44)
      ..lineTo(100, 44)
      ..close();
    final all = Path()
      ..addRRect(box)
      ..addPath(cab, Offset.zero)
      ..addOval(Rect.fromCircle(center: const Offset(34, 66), radius: 12))
      ..addOval(Rect.fromCircle(center: const Offset(116, 66), radius: 12));
    _stickerBase(c, all);

    c.drawRRect(box, _fill(blue));
    c.drawRRect(box, _stroke);
    c.drawPath(cab, _fill(green));
    c.drawPath(cab, _stroke);
    c.drawPath(win, _fill(ink));

    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: .4)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(20, 26), const Offset(76, 26), stripe);
    c.drawLine(const Offset(20, 38), const Offset(76, 38), stripe);

    for (final x in [34.0, 116.0]) {
      c.drawCircle(Offset(x, 66), 12, _fill(yellow));
      c.drawCircle(Offset(x, 66), 12, _stroke);
      c.drawCircle(Offset(x, 66), 4, _fill(ink));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BinPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final body = RRect.fromLTRBR(10, 24, 54, 80, const Radius.circular(8));
    final lid = RRect.fromLTRBR(3, 12, 61, 28, const Radius.circular(8));
    final all = Path()
      ..addRRect(body)
      ..addRRect(lid);
    _stickerBase(c, all);
    c.drawRRect(body, _fill(blue));
    c.drawRRect(body, _stroke);
    c.drawRRect(lid, _fill(yellow));
    c.drawRRect(lid, _stroke);
    for (final x in [24.0, 32.0, 40.0]) {
      c.drawLine(Offset(x, 36), Offset(x, 68), _stroke..strokeWidth = 3.5);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final leaf = Path()
      ..moveTo(6, 78)
      ..cubicTo(2, 40, 24, 8, 66, 4)
      ..cubicTo(68, 44, 52, 74, 14, 82)
      ..close();
    _stickerBase(c, leaf);
    c.drawPath(leaf, _fill(green));
    c.drawPath(leaf, _stroke);
    final vein = Path()
      ..moveTo(12, 74)
      ..cubicTo(26, 52, 40, 34, 56, 16);
    c.drawPath(vein, _stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    Paint p(Color col) => Paint()
      ..color = col
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(8, 14), const Offset(14, 20), p(coral));
    c.drawLine(const Offset(24, 4), const Offset(24, 14), p(yellow));
    c.drawLine(const Offset(38, 14), const Offset(31, 20), p(green));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
