import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_theme.dart';
import 'login_page.dart';   // AuthDivider, AuthField, AuthMessage, AuthCtaButton, AuthSubHeader, AuthMessageType

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
            _successMessage = '¡Cuenta creada! Revisa tu correo para verificar tu cuenta.';
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
        child: Column(
          children: [
            // Sub-header
            AuthSubHeader(
              title: 'CREAR CUENTA',
              onBack: () => context.go('/login'),
            ),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'Únete a\nGlobalscore',
                          style: TextStyle(
                            fontFamily: AuthTheme.fontSans,
                            fontSize: 30, fontWeight: FontWeight.w800,
                            color: AuthTheme.dark, height: 1.1, letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '· REGÍSTRATE GRATIS ·',
                          style: TextStyle(
                            fontFamily: AuthTheme.fontMono, fontSize: 10,
                            fontWeight: FontWeight.w700, color: AuthTheme.muted,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const AuthDivider(),
                        const SizedBox(height: 20),

                        // NOMBRE
                        AuthField(
                          label: 'NOMBRE', hint: 'Tu nombre',
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                          onChanged: (_) => setState(() => _errorMessage = null),
                        ),
                        const SizedBox(height: 10),

                        // CORREO
                        AuthField(
                          label: 'CORREO', hint: 'usuario@email.com',
                          controller: _emailController,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() => _errorMessage = null),
                        ),
                        const SizedBox(height: 10),

                        // CONTRASEÑA
                        AuthField(
                          label: 'CONTRASEÑA', hint: 'Mín. 6 caracteres',
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

                        // Strength indicator
                        ValueListenableBuilder(
                          valueListenable: _passwordController,
                          builder: (_, value, __) {
                            if (value.text.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _PasswordStrength(
                                strength: _getPasswordStrength(value.text),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Info box
                        _InfoBox(),
                        const SizedBox(height: 16),

                        // Error / Success
                        if (_errorMessage != null) ...[
                          AuthMessage(message: _errorMessage!, type: AuthMessageType.error),
                          const SizedBox(height: 12),
                        ],
                        if (_successMessage != null) ...[
                          AuthMessage(message: _successMessage!, type: AuthMessageType.success),
                          const SizedBox(height: 12),
                        ],

                        // CTA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AuthCtaButton(
                              label: 'REGISTRAR',
                              loadingLabel: 'CREANDO',
                              isLoading: _isLoading,
                              onTap: _isLoading ? null : _register,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Alt link
                        Row(
                          children: [
                            const Text(
                              '¿Ya tienes cuenta? ',
                              style: TextStyle(
                                fontFamily: AuthTheme.fontMono,
                                fontSize: 10, color: AuthTheme.muted,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text(
                                'Inicia sesión',
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
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  WIDGETS PRIVADOS DE REGISTER
// ═══════════════════════════════════════════════════════════

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
              color: i < strength ? _colors[strength] : AuthTheme.border,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0D5B4FD8),
        border: Border(
          left:   const BorderSide(color: AuthTheme.accent, width: 2),
          top:    BorderSide(color: AuthTheme.accent.withOpacity(0.18), width: 0.5),
          right:  BorderSide(color: AuthTheme.accent.withOpacity(0.18), width: 0.5),
          bottom: BorderSide(color: AuthTheme.accent.withOpacity(0.18), width: 0.5),
        ),
      ),
      child: const Row(
        children: [
          Text('🔒 ', style: TextStyle(fontSize: 12)),
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