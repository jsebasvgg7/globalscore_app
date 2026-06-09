import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_theme.dart';
import '../widgets/remember_me_service.dart';

// ═══════════════════════════════════════════════════════════
//  LOGIN PAGE
// ═══════════════════════════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool  _isLoading          = false;
  bool  _obscurePassword    = true;
  bool  _rememberMe         = false;       // ← nuevo
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadSavedEmail();                     // ← nuevo
  }

  /// Carga el email guardado si el usuario había marcado "Recordarme".
  Future<void> _loadSavedEmail() async {
    final saved = await RememberMeService.load();
    if (saved != null && mounted) {
      setState(() {
        _emailController.text = saved;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email    = _emailController.text.trim();
    // BUG FIX: No usar .trim() en contraseña — espacios son parte de ella
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor completa todos los campos');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    // Guarda o borra el email según el estado del checkbox
    if (_rememberMe) {
      await RememberMeService.save(email);
    } else {
      await RememberMeService.clear();
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // BUG FIX: En release, el router_notifier puede tardar; verificar sesión activa
      if (response.session == null && mounted) {
        setState(() => _errorMessage = 'No se pudo iniciar sesión. Intenta de nuevo.');
      }
      // go_router / router_notifier detecta el cambio de sesión
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message.contains('Invalid login credentials')
              ? 'Correo o contraseña incorrectos'
              : e.message.contains('Email not confirmed')
                  ? 'Por favor verifica tu correo antes de continuar'
                  : 'Error al iniciar sesión';
        });
      }
    } on Exception catch (e) {
      // BUG FIX: captura errores de red/SSL en release builds (no solo AuthException)
      if (mounted) {
        final msg = e.toString().toLowerCase();
        setState(() {
          _errorMessage = msg.contains('network') || msg.contains('socket') || msg.contains('connection')
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
                        ? constraints.maxHeight * 0.06
                        : 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight * 0.88),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                  // ── Brand ──────────────────────────────────────────
                  _NeoBrandHeader(),
                  const SizedBox(height: 22),

                  // ── Login card ─────────────────────────────────────
                  Container(
                    decoration: _neoBox(),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Row(
                          children: [
                            Container(width: 3, height: 16, color: AuthTheme.accent),
                            const SizedBox(width: 8),
                            const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontFamily: AuthTheme.fontMono,
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: AuthTheme.dark, letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // CORREO
                        AuthField(
                          label: 'EMAIL',
                          hint: 'tu@email.com',
                          controller: _emailController,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() => _errorMessage = null),
                        ),
                        const SizedBox(height: 10),

                        // CONTRASEÑA
                        AuthField(
                          label: 'CONTRASEÑA',
                          hint: '••••••••••',
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
                        const SizedBox(height: 10),

                        // Remember + forgot row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ← ahora pasa valor y callback
                            _NeoCheckbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/forgot-password'),
                              child: const Text(
                                '¿OLVIDASTE TU CONTRASEÑA?',
                                style: TextStyle(
                                  fontFamily: AuthTheme.fontMono, fontSize: 9,
                                  fontWeight: FontWeight.w700, color: AuthTheme.accent,
                                  letterSpacing: 0.6,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AuthTheme.accent,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Error
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          AuthMessage(message: _errorMessage!, type: AuthMessageType.error),
                        ],
                        const SizedBox(height: 16),

                        // CTA full-width
                        _NeoButton(
                          label: 'INICIAR SESIÓN',
                          loadingLabel: 'ENTRANDO',
                          isLoading: _isLoading,
                          onTap: _isLoading ? null : _login,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Register link ──────────────────────────────────
                  GestureDetector(
                    onTap: () => context.go('/register'),
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
                            '¿NO TIENES CUENTA?',
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
                              'REGÍSTRATE',
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

                  // Decorative dots bottom
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _DotGrid(cols: 5, rows: 3),
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
//  NEOBRUTALIST HELPERS  (private)
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

class _NeoBrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo square
        Stack(
          children: [
            // Offset shadow layer
            Positioned(
              left: 4, top: 4,
              child: Container(
                width: 52, height: 52,
                color: AuthTheme.dark.withOpacity(0.35),
              ),
            ),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AuthTheme.accent,
                border: Border.all(color: AuthTheme.dark, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // App name
        const Text(
          'GLOBALSCORE',
          style: TextStyle(
            fontFamily: AuthTheme.fontSans,
            fontSize: 28, fontWeight: FontWeight.w900,
            color: AuthTheme.dark, letterSpacing: -1.0, height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        // Underline decoration
        Container(
          height: 3,
          width: 140,
          color: AuthTheme.accent,
        ),
        const SizedBox(height: 6),
        const Text(
          'COMPITE. COLECCIONA. DOMINA.',
          style: TextStyle(
            fontFamily: AuthTheme.fontMono, fontSize: 9,
            fontWeight: FontWeight.w700, color: AuthTheme.muted,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _NeoButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback? onTap;

  const _NeoButton({
    required this.label,
    this.loadingLabel = 'CARGANDO',
    required this.isLoading,
    this.onTap,
  });

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
                        'ENTRANDO',
                        style: TextStyle(
                          fontFamily: AuthTheme.fontMono, fontSize: 12,
                          fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  )
                : Text(
                    label,
                    style: const TextStyle(
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

// ← _NeoCheckbox ahora es StatelessWidget controlado por el padre
class _NeoCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NeoCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: value ? AuthTheme.accent : Colors.transparent,
              border: Border.all(color: AuthTheme.dark, width: 1.5),
            ),
            child: value
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 7),
          const Text(
            'RECORDARME',
            style: TextStyle(
              fontFamily: AuthTheme.fontMono, fontSize: 9,
              fontWeight: FontWeight.w600, color: AuthTheme.dark,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  final int cols;
  final int rows;
  const _DotGrid({required this.cols, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cols * 12.0,
      height: rows * 12.0,
      child: CustomPaint(painter: _DotPainter(cols: cols, rows: rows)),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int cols;
  final int rows;
  _DotPainter({required this.cols, required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuthTheme.dark.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final cw = size.width / cols;
    final rh = size.height / rows;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(Offset(c * cw + cw / 2, r * rh + rh / 2), 1.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
//  SHARED AUTH WIDGETS  (exportados)
// ═══════════════════════════════════════════════════════════

/// Marca original (kept for backward compat)
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: AuthTheme.accent,
            border: Border.all(color: AuthTheme.dark, width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 13),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'GLOBALSCORE',
          style: TextStyle(
            fontFamily: AuthTheme.fontMono, fontSize: 11,
            fontWeight: FontWeight.w800, color: AuthTheme.dark, letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AuthTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 5, height: 5,
            color: AuthTheme.accent,
          ),
        ),
        Expanded(child: Container(height: 1, color: AuthTheme.border)),
      ],
    );
  }
}

class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AuthTheme.fontMono, fontSize: 9,
            fontWeight: FontWeight.w800, color: AuthTheme.accent,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: AuthTheme.surface,
            border: Border.all(color: AuthTheme.dark, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AuthTheme.dark.withOpacity(0.20),
                offset: const Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 42,
                decoration: BoxDecoration(
                  color: AuthTheme.accent,
                  border: Border(
                    right: BorderSide(color: AuthTheme.dark, width: 1.5),
                  ),
                ),
                child: Center(child: Icon(icon, size: 15, color: Colors.white)),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontMono,
                    fontSize: 12, color: AuthTheme.dark,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontFamily: AuthTheme.fontMono,
                      fontSize: 11, color: AuthTheme.muted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                  ),
                ),
              ),
              if (suffixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: suffixIcon,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum AuthMessageType { error, success, info }

class AuthMessage extends StatelessWidget {
  final String message;
  final AuthMessageType type;

  const AuthMessage({super.key, required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final Color borderColor, bgColor, textColor, leftBorder;
    switch (type) {
      case AuthMessageType.error:
        borderColor = const Color(0x4DEF4444);
        bgColor     = const Color(0x12EF4444);
        textColor   = const Color(0xFFDC2626);
        leftBorder  = const Color(0xFFDC2626);
      case AuthMessageType.success:
        borderColor = const Color(0x4D1D9E75);
        bgColor     = const Color(0x121D9E75);
        textColor   = const Color(0xFF0F6E56);
        leftBorder  = const Color(0xFF1D9E75);
      case AuthMessageType.info:
        borderColor = const Color(0x405B4FD8);
        bgColor     = const Color(0x125B4FD8);
        textColor   = const Color(0xFF3D2E7C);
        leftBorder  = AuthTheme.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left:   BorderSide(color: leftBorder, width: 3),
          top:    BorderSide(color: borderColor, width: 0.5),
          right:  BorderSide(color: borderColor, width: 0.5),
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: AuthTheme.fontMono,
          fontSize: 11, color: textColor, height: 1.5,
        ),
      ),
    );
  }
}

/// Botón CTA secundario (pequeño, para usos específicos)
class AuthCtaButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback? onTap;

  const AuthCtaButton({
    super.key,
    required this.label,
    this.loadingLabel = 'CARGANDO',
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: AuthTheme.dark,
            border: Border.all(color: AuthTheme.dark, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AuthTheme.dark.withOpacity(0.30),
                offset: const Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                const AuthLoadingDots(),
                const SizedBox(width: 8),
                Text(
                  loadingLabel,
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontMono, fontSize: 11,
                    fontWeight: FontWeight.w700, color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ] else ...[
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AuthTheme.fontMono, fontSize: 11,
                    fontWeight: FontWeight.w700, color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white38, width: 1.5),
                  ),
                  child: const Center(
                    child: Text('→', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AuthLoadingDots extends StatefulWidget {
  const AuthLoadingDots({super.key});

  @override
  State<AuthLoadingDots> createState() => _AuthLoadingDotsState();
}

class _AuthLoadingDotsState extends State<AuthLoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    ));
    _anims = _controllers.map((c) =>
      CurvedAnimation(parent: c, curve: Curves.easeInOut)).toList();
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(right: 3),
        child: FadeTransition(
          opacity: _anims[i],
          child: Container(
            width: 4, height: 4,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      )),
    );
  }
}

class AuthSubHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const AuthSubHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        border: Border(
          bottom: BorderSide(color: AuthTheme.dark, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                border: Border.all(color: AuthTheme.dark, width: 1.5),
              ),
              child: const Center(
                child: Text('←', style: TextStyle(color: AuthTheme.accent, fontSize: 15)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AuthTheme.fontMono, fontSize: 11,
              fontWeight: FontWeight.w800, color: AuthTheme.dark,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}