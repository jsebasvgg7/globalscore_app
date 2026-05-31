import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_theme.dart';

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
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor completa todos los campos');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email, password: password,
      );
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
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Error inesperado. Intenta de nuevo.');
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  const AuthBrandMark(),
                  const SizedBox(height: 28),

                  // Title
                  const Text(
                    'Iniciar\nsesión',
                    style: TextStyle(
                      fontFamily: AuthTheme.fontSans,
                      fontSize: 30, fontWeight: FontWeight.w800,
                      color: AuthTheme.dark, height: 1.1, letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '· ACCEDE A TU CUENTA ·',
                    style: TextStyle(
                      fontFamily: AuthTheme.fontMono, fontSize: 10,
                      fontWeight: FontWeight.w700, color: AuthTheme.muted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const AuthDivider(),
                  const SizedBox(height: 20),

                  // Correo
                  AuthField(
                    label: 'CORREO', hint: 'usuario@email.com',
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 10),

                  // Contraseña
                  AuthField(
                    label: 'CONTRASEÑA', hint: '••••••••',
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
                        size: 16, color: AuthTheme.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Forgot
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          fontFamily: AuthTheme.fontMono, fontSize: 10,
                          fontWeight: FontWeight.w700, color: AuthTheme.accent,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error
                  if (_errorMessage != null) ...[
                    AuthMessage(message: _errorMessage!, type: AuthMessageType.error),
                    const SizedBox(height: 12),
                  ],

                  // CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AuthCtaButton(
                        label: 'ENTRAR',
                        loadingLabel: 'ENTRANDO',
                        isLoading: _isLoading,
                        onTap: _isLoading ? null : _login,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Alt link
                  Row(
                    children: [
                      const Text(
                        '¿Sin cuenta? ',
                        style: TextStyle(fontFamily: AuthTheme.fontMono,
                            fontSize: 10, color: AuthTheme.muted),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: const Text(
                          'Regístrate',
                          style: TextStyle(
                            fontFamily: AuthTheme.fontMono, fontSize: 10,
                            fontWeight: FontWeight.w700, color: AuthTheme.accent,
                            decoration: TextDecoration.underline,
                            decorationColor: AuthTheme.accent,
                          ),
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════
//  SHARED AUTH WIDGETS  (exportados, usados en Register también)
// ═══════════════════════════════════════════════════════════

/// Marca de la app con cuadrado púrpura + nombre mono
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24, height: 24, color: AuthTheme.accent,
          child: Center(
            child: Container(
              width: 9, height: 9,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'GLOBALSCORE',
          style: TextStyle(
            fontFamily: AuthTheme.fontMono, fontSize: 13,
            fontWeight: FontWeight.w700, color: AuthTheme.dark,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

/// Separador con punto central púrpura
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: AuthTheme.border)),
        Container(
          width: 5, height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: AuthTheme.accent.withOpacity(0.5),
        ),
        Expanded(child: Container(height: 0.5, color: AuthTheme.border)),
      ],
    );
  }
}

/// Campo de texto con label mono mayúscula + ícono izquierdo
class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.suffixIcon,
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
            fontWeight: FontWeight.w700, color: AuthTheme.muted,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AuthTheme.border, width: 0.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(icon, size: 14, color: AuthTheme.muted),
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
                    contentPadding: EdgeInsets.zero,
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

/// Banner de error / éxito / info con borde izquierdo de color
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

/// Botón CTA principal: fondo oscuro, flecha derecha con borde
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AuthTheme.dark,
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
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white38, width: 1.5),
                  ),
                  child: const Center(
                    child: Text('→', style: TextStyle(color: Colors.white, fontSize: 12)),
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

/// Tres puntos animados para estado de carga
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

/// Sub-header para páginas secundarias (Register, Forgot, Reset)
class AuthSubHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const AuthSubHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        border: Border(bottom: BorderSide(color: AuthTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                border: Border.all(color: AuthTheme.border, width: 0.5),
              ),
              child: const Center(
                child: Text('←', style: TextStyle(color: AuthTheme.accent, fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AuthTheme.fontMono, fontSize: 11,
              fontWeight: FontWeight.w700, color: AuthTheme.dark,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}