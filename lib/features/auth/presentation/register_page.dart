import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_theme.dart';
import 'login_page.dart';
// ═══════════════════════════════════════════════════════════
//  REGISTER PAGE
// ═══════════════════════════════════════════════════════════

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool  _isLoading          = false;
  bool  _obscurePassword    = true;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  int _getPasswordStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    int s = 0;
    if (pwd.length >= 6)                        s++;
    if (pwd.length >= 10)                       s++;
    if (RegExp(r'[A-Z]|[0-9]').hasMatch(pwd))  s++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(pwd)) s++;
    return s.clamp(0, 4);
  }

  Future<void> _register() async {
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    // BUG FIX: No trim() en contraseña
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor completa todos los campos');
      return;
    }
    if (name.length < 3) {
      setState(() => _errorMessage = 'El nombre debe tener al menos 3 caracteres');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'display_name': name},
      );

      if (response.user != null) {
        await Supabase.instance.client.from('users').insert({
          'auth_id':                response.user!.id,
          'name':                   name,
          'email':                  email.toLowerCase(),
          'points':                 0,
          'predictions':            0,
          'correct':                0,
          'monthly_points':         0,
          'monthly_predictions':    0,
          'monthly_correct':        0,
          'current_streak':         0,
          'best_streak':            0,
          'level':                  1,
          'monthly_championships':  0,
        });

        if (mounted) {
          setState(() {
            _successMessage = '¡Cuenta creada! Revisa tu correo para verificar.';
            _isLoading = false;
          });
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) context.go('/login');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message.contains('already registered')
              ? 'Este correo ya está registrado'
              : e.message;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        setState(() {
          _errorMessage = msg.contains('network') || msg.contains('socket')
              ? 'Sin conexión. Verifica tu internet.'
              : 'Error inesperado. Intenta de nuevo.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.cream,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: constraints.maxHeight > 600
                        ? constraints.maxHeight * 0.05
                        : 14,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight * 0.88),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // ── Title + dot grid ──────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ÚNETE A\nGLOBALSCORE',
                                    style: TextStyle(
                                      fontFamily: AuthTheme.fontSans,
                                      fontSize: 24, fontWeight: FontWeight.w900,
                                      color: AuthTheme.dark, height: 1.1, letterSpacing: -1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    '· REGÍSTRATE GRATIS ·',
                                    style: TextStyle(
                                      fontFamily: AuthTheme.fontMono, fontSize: 9,
                                      fontWeight: FontWeight.w700, color: AuthTheme.muted,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _RegisterDotGrid(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Form card ─────────────────────────────
                        Container(
                          decoration: _neoBox(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 3, height: 14, color: AuthTheme.accent),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'DATOS DE CUENTA',
                                    style: TextStyle(
                                      fontFamily: AuthTheme.fontMono, fontSize: 9,
                                      fontWeight: FontWeight.w800, color: AuthTheme.muted,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              AuthField(
                                label: 'NOMBRE',
                                hint: 'Tu nombre',
                                controller: _nameController,
                                icon: Icons.person_outline_rounded,
                                onChanged: (_) => setState(() => _errorMessage = null),
                              ),
                              const SizedBox(height: 10),

                              AuthField(
                                label: 'CORREO',
                                hint: 'usuario@email.com',
                                controller: _emailController,
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) => setState(() => _errorMessage = null),
                              ),
                              const SizedBox(height: 10),

                              AuthField(
                                label: 'CONTRASEÑA',
                                hint: 'Mín. 6 caracteres',
                                controller: _passwordController,
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                onChanged: (_) => setState(() => _errorMessage = null),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  child: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 15, color: AuthTheme.muted,
                                  ),
                                ),
                              ),

                              ValueListenableBuilder(
                                valueListenable: _passwordController,
                                builder: (_, value, __) {
                                  if (value.text.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _PasswordStrength(
                                      strength: _getPasswordStrength(value.text),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),

                              _InfoBox(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Error / Success
                        if (_errorMessage != null) ...[
                          AuthMessage(message: _errorMessage!, type: AuthMessageType.error),
                          const SizedBox(height: 10),
                        ],
                        if (_successMessage != null) ...[
                          AuthMessage(message: _successMessage!, type: AuthMessageType.success),
                          const SizedBox(height: 10),
                        ],

                        // CTA
                        _RegisterButton(
                          isLoading: _isLoading,
                          onTap: _isLoading ? null : _register,
                        ),
                        const SizedBox(height: 14),

                        // ── Login link card (igual que en login) ──
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AuthTheme.cream,
                              border: Border.all(color: AuthTheme.dark, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AuthTheme.dark.withOpacity(0.30),
                                  offset: const Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '¿YA TIENES CUENTA?',
                                  style: TextStyle(
                                    fontFamily: AuthTheme.fontMono, fontSize: 10,
                                    fontWeight: FontWeight.w600, color: AuthTheme.dark,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AuthTheme.accent,
                                    border: Border.all(color: AuthTheme.dark, width: 1.5),
                                  ),
                                  child: const Text(
                                    'INICIA SESIÓN',
                                    style: TextStyle(
                                      fontFamily: AuthTheme.fontMono, fontSize: 10,
                                      fontWeight: FontWeight.w800, color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPERS PRIVADOS (también usados en login_page)
// ═══════════════════════════════════════════════════════════

BoxDecoration _neoBox({
  Color bg = AuthTheme.cream,
  double shadowX = 3,
  double shadowY = 3,
}) =>
    BoxDecoration(
      color: bg,
      border: Border.all(color: AuthTheme.dark, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: AuthTheme.dark.withOpacity(0.35),
          offset: Offset(shadowX, shadowY),
          blurRadius: 0,
        ),
      ],
    );

// ═══════════════════════════════════════════════════════════
//  WIDGETS PRIVADOS DE REGISTER
// ═══════════════════════════════════════════════════════════

class _RegisterDotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.18,
      child: SizedBox(
        width: 60, height: 40,
        child: CustomPaint(painter: _MiniDotPainter()),
      ),
    );
  }
}

class _MiniDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cols = 5;
    const rows = 3;
    final paint = Paint()..color = AuthTheme.dark;
    final cw = size.width / cols;
    final rh = size.height / rows;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(Offset(c * cw + cw / 2, r * rh + rh / 2), 2.0, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  const _RegisterButton({required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AuthTheme.accent,
            border: Border.all(color: AuthTheme.dark, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AuthTheme.dark.withOpacity(0.35),
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthLoadingDots(),
                      SizedBox(width: 8),
                      Text(
                        'CREANDO CUENTA',
                        style: TextStyle(
                          fontFamily: AuthTheme.fontMono, fontSize: 12,
                          fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'REGISTRAR',
                    style: TextStyle(
                      fontFamily: AuthTheme.fontMono, fontSize: 12,
                      fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  final int strength; // 0–4

  const _PasswordStrength({required this.strength});

  static const _labels = ['', 'Débil', 'Regular', 'Buena', 'Fuerte'];
  static const _colors = [
    Colors.transparent,
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF1D9E75),
    Color(0xFF5B4FD8),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
              decoration: BoxDecoration(
                color: i < strength ? _colors[strength] : AuthTheme.border,
                border: Border.all(
                  color: i < strength ? AuthTheme.dark.withOpacity(0.25) : Colors.transparent,
                  width: 0.5,
                ),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        if (strength > 0)
          Text(
            _labels[strength],
            style: const TextStyle(
              fontFamily: AuthTheme.fontMono, fontSize: 9,
              color: AuthTheme.muted, letterSpacing: 0.6,
            ),
          ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x0D5B4FD8),
        border: Border.all(color: AuthTheme.accent.withOpacity(0.40), width: 1.0),
      ),
      child: const Row(
        children: [
          Text('🔒 ', style: TextStyle(fontSize: 11)),
          Text(
            'Tus datos están seguros y protegidos',
            style: TextStyle(
              fontFamily: AuthTheme.fontMono, fontSize: 10,
              color: Color(0xFF3D2E7C), letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}