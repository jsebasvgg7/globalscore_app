import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';
import '../data/albums_service.dart';
import '../../../shared/layout/scaffold_with_nav_bar.dart';

// ── Paleta — crema base + tokens Ds de albums_page ──────────
const _bg         = Color(0xFFF5F2EC);   // Ds.bg — crema base
const _bgSection  = Color(0xFFEFEBE3);   // Ds.bgSection
const _card       = Color(0xFFE8E3D8);   // Ds.bgCard
const _border     = Color(0xFF2D2A40);   // Ds.border — oscuro azul-gris
const _borderSub  = Color(0xFFCBC6BA);   // Ds.borderSub
const _accent     = Color(0xFF5B4FD8);   // Ds.accent
const _accentDark = Color(0xFF4A40C0);   // Ds.accentDim
const _gold       = Color(0xFFFFD600);   // Ds.gold
const _shadow     = Color(0xFF302D41);   // Ds.shadow3d
const _muted      = Color(0xFF7A7268);   // Ds.muted
const _text       = Color(0xFF1C1A2E);   // Ds.ink
const _white      = Colors.white;

// Colores por tipo (badge y borde)
Color _typeColor(String t) => switch (t) {
      'player'      => const Color(0xFF5B4FD8), // morado
      'team'        => const Color(0xFF1DAA75), // verde
      'competition' => const Color(0xFFF59E0B), // ámbar
      'event'       => const Color(0xFFE0435A), // rojo-rosa
      _             => _accent,
    };

String _typeLabel(String t) => switch (t) {
      'player'      => 'JUGADOR',
      'team'        => 'EQUIPO',
      'competition' => 'COPA',
      'event'       => 'EVENTO',
      _             => '?',
    };

IconData _typeIcon(String t) => switch (t) {
      'player'      => Icons.person,
      'team'        => Icons.shield,
      'competition' => Icons.emoji_events,
      'event'       => Icons.history_edu,
      _             => Icons.star,
    };

// ════════════════════════════════════════════════════════════
//  ENTRY POINT
// ════════════════════════════════════════════════════════════
void showPackOpeningModal(BuildContext context, WidgetRef ref) {
  // Ocultar topbar y bottom nav para dar espacio completo al opening
  ref.read(hideTopBarProvider.notifier).hide();
  ref.read(hideBottomNavProvider.notifier).hide();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: const _PackOpeningSheet(),
    ),
  ).then((_) {
    // Restaurar topbar y bottom nav al cerrar
    ref.read(hideTopBarProvider.notifier).show();
    ref.read(hideBottomNavProvider.notifier).show();
    ref.read(packOpenProvider.notifier).reset();
    ref.invalidate(albumsProvider);
  });
}

// ════════════════════════════════════════════════════════════
//  SHEET CONTAINER
// ════════════════════════════════════════════════════════════
class _PackOpeningSheet extends StatelessWidget {
  const _PackOpeningSheet();

  @override
  Widget build(BuildContext context) {
    // El alto se controla por fase desde _PackOpeningFlow vía un callback;
    // aquí simplemente dejamos que el contenido dicte la altura.
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.zero,
        border: Border(top: BorderSide(color: _border, width: 2.5)),
      ),
      child: const _PackOpeningFlow(),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MÁQUINA DE ESTADOS
//  idle → opening → revealing → done
// ════════════════════════════════════════════════════════════
enum _Phase { idle, opening, revealing, done }

class _PackOpeningFlow extends ConsumerStatefulWidget {
  const _PackOpeningFlow();
  @override
  ConsumerState<_PackOpeningFlow> createState() => _PackOpeningFlowState();
}

class _PackOpeningFlowState extends ConsumerState<_PackOpeningFlow> {
  _Phase _phase = _Phase.idle;
  PackOpenResult? _result;
  String? _errorMsg;
  bool _isOpening = false; // lock anti-double-tap
  // Set de índices revelados (tap por tap)
  final Set<int> _revealed = {};
  // Cuántos sobres se abrieron en ESTA sesión del modal.
  // Se resta del valor real del provider para evitar desincronizaciones.
  int _openedThisSession = 0;

  // Fuente de verdad: provider − abiertos en esta sesión.
  // Usar ref.read (no watch) para evitar rebuilds involuntarios mientras
  // el provider se refresca; el setState en _startOpening ya fuerza el rebuild.
  int get _packsAvailable {
    final fromProvider =
        ref.read(albumsProvider).value?.packs?.packsAvailable ?? 0;
    return (fromProvider - _openedThisSession).clamp(0, 9999);
  }

  Future<void> _startOpening() async {
    if (_isOpening) return; // evita doble-tap / dupeos
    setState(() {
      _isOpening = true;
      _phase    = _Phase.opening;
      _result   = null;
      _errorMsg = null;
      _revealed.clear();
    });

    try {
      final userId = await ref.read(albumsUserIdProvider.future);
      final result = await AlbumsService().openPack(userId);

      // ── DEBUG: diagnóstico de imagePath por carta ──────
      debugPrint('╔══ IMAGE PATHS ════════════════════════');
      for (final card in result.allCards) {
        debugPrint('║ [${card.cardType}] ${card.name} → "${card.imagePath}"');
      }
      debugPrint('╚═══════════════════════════════════════');

      if (mounted) {
        setState(() {
          _result            = result;
          _phase             = _Phase.revealing;
          _openedThisSession += 1; // solo sube cuando la API confirma el gasto
          _isOpening         = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg  = e.toString();
          _phase     = _Phase.idle;
          _isOpening = false;
        });
      }
    }
  }

  void _revealCard(int index) {
    final total = _result?.allCards.length ?? 0;
    if (_revealed.contains(index)) return;
    setState(() => _revealed.add(index));
    // Si todas reveladas → done automático tras breve delay
    if (_revealed.length >= total) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _phase = _Phase.done);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final isRevealing = _phase == _Phase.revealing;
    final total = _result?.allCards.length ?? 0;
    final revealedCount = _revealed.length;
    final allDone = isRevealing && total > 0 && revealedCount >= total;

    // En revealing: el modal se ajusta al contenido (sin espacio vacío).
    // En el resto de fases: altura fija 92% de pantalla.
    if (isRevealing) {
      return Column(
        mainAxisSize: MainAxisSize.min,   // ← clave: wrap content
        children: [
          _GaHeader(packsAvailable: _packsAvailable),
          _RevealingView(
            result: _result!,
            revealed: _revealed,
            onReveal: _revealCard,
            onFinish: () => setState(() => _phase = _Phase.done),
          ),
          // Footer siempre visible — el modal ya no tiene espacio vacío
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  allDone ? '¡LISTO!' : 'TOCA CADA CARTA PARA REVELARLA',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: allDone ? _accent : _muted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('·', style: TextStyle(color: _muted, fontSize: 9)),
                const SizedBox(width: 8),
                Text(
                  '$revealedCount/$total',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Fases idle / opening / done → altura fija
    return SizedBox(
      height: screenH * 0.92,
      child: Column(
        children: [
          _GaHeader(packsAvailable: _packsAvailable),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: switch (_phase) {
                _Phase.idle => _IdleView(
                    key: const ValueKey('idle'),
                    packsAvailable: _packsAvailable,
                    onOpen: _startOpening,
                    errorMsg: _errorMsg,
                  ),
                _Phase.opening => const _OpeningView(key: ValueKey('opening')),
                _Phase.revealing => const SizedBox.shrink(), // nunca llega aquí
                _Phase.done => _DoneView(
                    key: const ValueKey('done'),
                    result: _result!,
                    packsAvailable: _packsAvailable,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  HEADER — "GA · GLOBAL ALBUMS · 25/26"
// ════════════════════════════════════════════════════════════
class _GaHeader extends StatelessWidget {
  final int packsAvailable;
  const _GaHeader({required this.packsAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: _accent,
        border: Border(bottom: BorderSide(color: _border, width: 1.5)),
      ),
      child: Row(
        children: [
          // Logo GA
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Text(
              'GA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Título
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GLOBAL ALBUMS · 25/26',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white60,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                'APERTURA DE SOBRE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Cerrar
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(Icons.close, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FASE idle — sobre 3D + botón "TOCA PARA ABRIR"
// ════════════════════════════════════════════════════════════
class _IdleView extends StatefulWidget {
  final int packsAvailable;
  final VoidCallback onOpen;
  final String? errorMsg;

  const _IdleView({
    super.key,
    required this.packsAvailable,
    required this.onOpen,
    this.errorMsg,
  });

  @override
  State<_IdleView> createState() => _IdleViewState();
}

class _IdleViewState extends State<_IdleView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canOpen = widget.packsAvailable > 0;

    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Marco exterior con brackets
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE0),
                  border: Border.all(color: _border.withValues(alpha: 0.15), width: 1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bracket esquinas exteriores
                    ..._outerBrackets(),
                    // Sobre flotando
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: const _Pack3D(scale: 1.45),
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.errorMsg != null) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.errorMsg!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFE55B5B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Bottom section
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border, width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              // Botón principal
              GestureDetector(
                onTap: canOpen ? widget.onOpen : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: canOpen ? _accent : _muted,
                    border: Border.all(color: _border, width: 1.5),
                    boxShadow: canOpen
                        ? const [BoxShadow(color: Color(0x88302D41), offset: Offset(4, 4))]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    canOpen
                        ? (widget.errorMsg != null ? 'REINTENTAR' : 'TOCA PARA ABRIR')
                        : 'SIN SOBRES',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Footer categorías con colores de tipo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CategoryPill(label: 'JUGADOR', color: const Color(0xFF5B4FD8)),
                  const _Dot(),
                  _CategoryPill(label: 'EQUIPO', color: const Color(0xFF1DAA75)),
                  const _Dot(),
                  _CategoryPill(label: 'COPA', color: const Color(0xFFF59E0B)),
                  const _Dot(),
                  _CategoryPill(label: 'EVENTO', color: const Color(0xFFE0435A)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static List<Widget> _outerBrackets() {
    const s = 14.0;
    const t = 1.5;
    const c = Color(0xFF8B7355);
    Widget bracket({bool flipH = false, bool flipV = false}) => Transform.scale(
      scaleX: flipH ? -1 : 1,
      scaleY: flipV ? -1 : 1,
      child: SizedBox(
        width: s, height: s,
        child: CustomPaint(painter: _BracketPainter(color: c, strokeWidth: t)),
      ),
    );

    return [
      Positioned(top: 6, left: 6, child: bracket()),
      Positioned(top: 6, right: 6, child: bracket(flipH: true)),
      Positioned(bottom: 6, left: 6, child: bracket(flipV: true)),
      Positioned(bottom: 6, right: 6, child: bracket(flipH: true, flipV: true)),
    ];
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _BracketPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => false;
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryPill({required this.label, this.color = _muted});
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1,
        ),
      );
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text('·', style: TextStyle(fontSize: 9, color: _muted)),
      );
}

// ════════════════════════════════════════════════════════════
//  SOBRE PREMIUM — rectangular con flap pintado + escudo GA
// ════════════════════════════════════════════════════════════
class _Pack3D extends StatelessWidget {
  final double scale;
  const _Pack3D({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final w   = 155.0 * scale;
    final h   = 205.0 * scale;
    final off = 7.0   * scale;

    // El SizedBox total incluye espacio para las capas traseras
    return SizedBox(
      width:  w + off,
      height: h + off,
      child: Stack(
        children: [
          // ── Sombra
          Positioned(
            top: off + 5, left: off + 3,
            child: Container(width: w, height: h, color: const Color(0x55302D41)),
          ),
          // ── Capa más trasera
          Positioned(
            top: off, left: off,
            child: CustomPaint(
              size: Size(w, h),
              painter: _EnvelopePainter(
                bodyColor:   const Color(0xFF1A154A),
                borderColor: const Color(0xFF2E2870),
                flapColor:   const Color(0xFF120E38),
                isFront: false,
              ),
            ),
          ),
          // ── Capa media
          Positioned(
            top: off * 0.5, left: off * 0.5,
            child: CustomPaint(
              size: Size(w, h),
              painter: _EnvelopePainter(
                bodyColor:   const Color(0xFF201A5C),
                borderColor: const Color(0xFF3A318A),
                flapColor:   const Color(0xFF160F44),
                isFront: false,
              ),
            ),
          ),
          // ── Cara frontal con contenido
          Positioned(
            top: 0, left: 0,
            child: SizedBox(
              width: w, height: h,
              child: Stack(
                children: [
                  // Cuerpo del sobre
                  CustomPaint(
                    size: Size(w, h),
                    painter: _EnvelopePainter(
                      bodyColor:   const Color(0xFF2D1F7A),
                      borderColor: _accent,
                      flapColor:   const Color(0xFF231660),
                      isFront: true,
                    ),
                  ),
                  // Contenido superpuesto al cuerpo
                  _EnvelopeFrontContent(w: w, h: h, scale: scale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter que dibuja el sobre completo: cuerpo rect + flap triangular superior
class _EnvelopePainter extends CustomPainter {
  final Color bodyColor, borderColor, flapColor;
  final bool isFront;

  const _EnvelopePainter({
    required this.bodyColor,
    required this.borderColor,
    required this.flapColor,
    required this.isFront,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final flapH = h * 0.28; // altura del flap triangular

    // ── Cuerpo rectangular
    final bodyPaint = Paint()..color = bodyColor..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bodyPaint);

    // ── Flap triangular (triángulo sobre la parte superior)
    final flapPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w / 2, flapH)
      ..lineTo(w, 0)
      ..close();
    final flapPaint = Paint()..color = flapColor..style = PaintingStyle.fill;
    canvas.drawPath(flapPath, flapPaint);

    // ── Línea divisoria del flap (horizontal en la base del triángulo)
    final divPaint = Paint()
      ..color = borderColor.withValues(alpha: isFront ? 0.5 : 0.25)
      ..strokeWidth = isFront ? 1.0 : 0.8
      ..style = PaintingStyle.stroke;
    // La línea del flap va de (0,0) a (w,0) pasando por el punto del triángulo
    // en realidad dibujamos una línea en y=flapH que es donde termina el triángulo
    // Pero visualmente el borde real del sobre es el rectángulo entero:
    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: isFront ? 0.85 : 0.35)
      ..strokeWidth = isFront ? 1.5 : 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), borderPaint);

    // ── Borde del flap triangular
    canvas.drawPath(flapPath, divPaint);

    // ── Línea de pliegue horizontal (base del triángulo)
    if (isFront) {
      final foldPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, flapH), Offset(w, flapH), foldPaint);
    }
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => false;
}

// Contenido superpuesto al frente del sobre
class _EnvelopeFrontContent extends StatelessWidget {
  final double w, h, scale;
  const _EnvelopeFrontContent({required this.w, required this.h, required this.scale});

  @override
  Widget build(BuildContext context) {
    final flapH = h * 0.28;
    final bodyTop = flapH + 4 * scale; // justo debajo del pliegue

    return Stack(
      children: [
        // Stripes diagonales sutiles (solo en zona del cuerpo bajo el flap)
        Positioned(top: flapH, left: 0, right: 0, bottom: 0,
          child: ClipRect(child: CustomPaint(painter: _DarkStripePainter())),
        ),

        // Barcode en el flap (centrado verticalmente en el triángulo)
        Positioned(
          top: flapH * 0.3,
          left: 0, right: 0,
          child: Center(
            child: CustomPaint(
              size: Size(55 * scale, 9 * scale),
              painter: _BarcodePainter(),
            ),
          ),
        ),

        // GS-25/26 debajo del barcode en el flap
        Positioned(
          top: flapH * 0.62,
          left: 0, right: 0,
          child: Center(
            child: Text(
              'GS-25/26',
              style: TextStyle(
                fontSize: 6.5 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        // Escudo GA — zona central del cuerpo
        Positioned(
          top: bodyTop + 18 * scale,
          left: 0, right: 0,
          child: Center(child: _GaShield(scale: scale * 0.9, accentColor: _accent)),
        ),

        // GLOBAL ALBUMS
        Positioned(
          bottom: 36 * scale,
          left: 0, right: 0,
          child: Center(
            child: Text(
              'GLOBAL ALBUMS',
              style: TextStyle(
                fontSize: 8.5 * scale,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.88),
                letterSpacing: 2.5,
              ),
            ),
          ),
        ),

        // Temporada
        Positioned(
          bottom: 20 * scale,
          left: 0, right: 0,
          child: Center(
            child: Text(
              '25 · 26',
              style: TextStyle(
                fontSize: 7.5 * scale,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 3,
              ),
            ),
          ),
        ),

        // Esquinas doradas (en la zona del cuerpo)
        Positioned(top: flapH + 8 * scale, left: 7 * scale,
            child: _GoldCorner(scale: scale)),
        Positioned(top: flapH + 8 * scale, right: 7 * scale,
            child: _GoldCorner(scale: scale, flipH: true)),
        Positioned(bottom: 8 * scale, left: 7 * scale,
            child: _GoldCorner(scale: scale, flipV: true)),
        Positioned(bottom: 8 * scale, right: 7 * scale,
            child: _GoldCorner(scale: scale, flipH: true, flipV: true)),
      ],
    );
  }
}

// Escudo pentagonal con "GA"
class _GaShield extends StatelessWidget {
  final double scale;
  final Color accentColor;
  const _GaShield({required this.scale, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final size = 64.0 * scale;
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _ShieldPainter(accentColor: accentColor),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 4 * scale),
            child: Text(
              'GA',
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color accentColor;
  const _ShieldPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fill
    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    // Border
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.65)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.65)
      ..lineTo(0, h * 0.25)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.accentColor != accentColor;
}

// Esquina dorada tipo bracket
class _GoldCorner extends StatelessWidget {
  final double scale;
  final bool flipH, flipV;
  const _GoldCorner({required this.scale, this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1,
      scaleY: flipV ? -1 : 1,
      child: CustomPaint(
        size: Size(10 * scale, 10 * scale),
        painter: _GoldCornerPainter(),
      ),
    );
  }
}

class _GoldCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_GoldCornerPainter old) => false;
}


class _CornerBracket extends StatelessWidget {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  const _CornerBracket({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 12),
      painter: _CornerPainter(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  const _CornerPainter({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    if (topLeft) {
      canvas.drawLine(Offset(0, h), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), paint);
    } else if (topRight) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (bottomLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    } else if (bottomRight) {
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    for (double x = -size.height; x < size.width + size.height; x += 28) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => false;
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    double x = 0;
    while (x < size.width) {
      final w = rng.nextDouble() * 3 + 1;
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w + rng.nextDouble() * 2 + 0.5;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => false;
}

// ════════════════════════════════════════════════════════════
//  FASE opening — sobre flotando + loading
// ════════════════════════════════════════════════════════════
class _OpeningView extends StatefulWidget {
  const _OpeningView({super.key});
  @override
  State<_OpeningView> createState() => _OpeningViewState();
}

class _OpeningViewState extends State<_OpeningView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _float,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _float.value),
            child: const _Pack3D(scale: 1.45),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'ABRIENDO SOBRE...',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: _muted,
          ),
        ),
        const SizedBox(height: 16),
        // Dots
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final v = (((_ctrl.value + i / 3) % 1.0));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.25 + 0.75 * v),
                  border: Border.all(color: _border, width: 1),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FASE revealing — grid 2×2, tap para revelar
// ════════════════════════════════════════════════════════════
class _RevealingView extends StatelessWidget {
  final PackOpenResult result;
  final Set<int> revealed;
  final void Function(int) onReveal;
  final VoidCallback onFinish;

  const _RevealingView({
    super.key,
    required this.result,
    required this.revealed,
    required this.onReveal,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final cards = result.allCards;
    final total = cards.length;

    return Column(
      children: [
        // ── Sub-header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _border, width: 1)),
          ),
          child: Row(
            children: [
              const Text(
                'TUS CARTAS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _text,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(total, (i) => Container(
                  width: 14, height: 14,
                  margin: const EdgeInsets.only(left: 4),
                  color: revealed.contains(i) ? _accent : const Color(0xFFD4CFC5),
                )),
              ),
            ],
          ),
        ),

        // ── Leyenda rareza
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Row(
            children: [
              _RarityDot(color: const Color(0xFF5B4FD8), label: 'RARO'),
              const SizedBox(width: 14),
              _RarityDot(color: const Color(0xFFE0435A), label: 'ÉPICO'),
              const SizedBox(width: 14),
              _RarityDot(color: _gold, label: 'LEGENDARIO'),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Grid 2×2 — sin Expanded, el modal se ajusta al contenido
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: total,
            itemBuilder: (_, i) {
              if (revealed.contains(i)) {
                return _ResultCard(
                  card: cards[i],
                  index: i,
                  animate: revealed.length == revealed.where((r) => r <= i).length &&
                      revealed.contains(i),
                );
              }
              return GestureDetector(
                onTap: () => onReveal(i),
                child: _HiddenRevealCard(index: i),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Indicador de rareza
class _RarityDot extends StatelessWidget {
  final Color color;
  final String label;
  const _RarityDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: _muted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
}

// ── Carta oculta (GA shield)
class _HiddenRevealCard extends StatelessWidget {
  final int index;
  const _HiddenRevealCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border.all(color: _accent.withValues(alpha: 0.6), width: 1.5),
        boxShadow: const [
          BoxShadow(color: _shadow, offset: Offset(3, 3)),
        ],
      ),
      child: Stack(
        children: [
          // Diagonal stripes sobre fondo oscuro
          Positioned.fill(
            child: CustomPaint(painter: _DarkStripePainter()),
          ),
          // Logo GA centrado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.18),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'GA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white60,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Código serie
                Text(
                  'GS-25/26',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Esquinas bracket
          Positioned(top: 8, left: 8, child: _MiniCorner()),
          Positioned(top: 8, right: 8, child: _MiniCorner(flip: true)),
          Positioned(bottom: 8, left: 8, child: _MiniCorner(bottom: true)),
          Positioned(bottom: 8, right: 8, child: _MiniCorner(flip: true, bottom: true)),
        ],
      ),
    );
  }
}

class _MiniCorner extends StatelessWidget {
  final bool flip;
  final bool bottom;
  const _MiniCorner({this.flip = false, this.bottom = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10, height: 10,
      child: CustomPaint(
        painter: _CornerPainter(
          topLeft: !flip && !bottom,
          topRight: flip && !bottom,
          bottomLeft: !flip && bottom,
          bottomRight: flip && bottom,
        ),
      ),
    );
  }
}

class _DarkStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width + size.height; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DarkStripePainter old) => false;
}

// ════════════════════════════════════════════════════════════
//  CARTA RESULTADO — diseño de la imagen (número + tipo + avatar circular + estrellas)
// ════════════════════════════════════════════════════════════
class _ResultCard extends StatefulWidget {
  final AlbumCard card;
  final int index;
  final bool animate;
  const _ResultCard({required this.card, required this.index, this.animate = false});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 60), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: _CardContent(card: widget.card, index: widget.index),
    );
  }
}

class _CardContent extends StatelessWidget {
  final AlbumCard card;
  final int index;
  const _CardContent({required this.card, required this.index});

  @override
  Widget build(BuildContext context) {
    final color   = _typeColor(card.cardType);
    final label   = _typeLabel(card.cardType);
    final stars   = card.significanceLevel ?? 1;
    final numStr  = (index + 1).toString().padLeft(3, '0');
    final isGoat  = card.isGoat;
    final borderC = isGoat ? _gold : color;

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: borderC, width: isGoat ? 2 : 1.5),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top row: número + tipo
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 0),
            child: Row(
              children: [
                Text(
                  numStr,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Avatar circular con borde punteado
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _CircularAvatar(
                  imagePath: card.imagePath,
                  name: card.name,
                  color: color,
                  isGoat: isGoat,
                  cardType: card.cardType,
                ),
              ),
            ),
          ),

          // ── Estrellas
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Text(
                '★',
                style: TextStyle(
                  fontSize: 9,
                  color: i < stars
                      ? (stars >= 5 ? _gold : color)
                      : _border.withValues(alpha: 0.18),
                ),
              )),
            ),
          ),

          // ── Separador
          Container(height: 1, color: _border.withValues(alpha: 0.1)),

          // ── Nombre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            color: _border.withValues(alpha: 0.04),
            child: Text(
              card.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: _text,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resuelve la URL final de la imagen ───────────────────────
// • URLs absolutas (https://...) → se usan tal cual
// • Paths relativos (events/xxx.jpg) → quedaron sin migrar a Cloudinary,
//   apuntan al bucket 'historical' del Supabase original
const _supabaseStorageBase =
    'https://auquyjigjceqzwpjbbff.supabase.co/storage/v1/object/public/historical/';

String? _resolveImageUrl(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  // URL absoluta → usar directo
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  // Path relativo → completar con Supabase Storage (registros pre-migración)
  final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '$_supabaseStorageBase$path';
}

// Avatar circular con borde punteado — idéntico al diseño de la imagen
class _CircularAvatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  final Color color;
  final bool isGoat;
  final String cardType;

  const _CircularAvatar({
    required this.imagePath,
    required this.name,
    required this.color,
    required this.isGoat,
    required this.cardType,
  });

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    final url  = _resolveImageUrl(imagePath);

    return SizedBox(
      width: size + 12,
      height: size + 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Borde punteado exterior
          CustomPaint(
            size: const Size(size + 12, size + 12),
            painter: _DashedCirclePainter(
              color: isGoat ? _gold : color,
              dashCount: 20,
            ),
          ),
          // Imagen circular
          ClipOval(
            child: Container(
              width: size,
              height: size,
              color: color.withValues(alpha: 0.08),
              child: url != null
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      // Mostrar shimmer mientras carga
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return _AvatarShimmer(color: color);
                      },
                      // Fallback si la URL falla (404, CORS, timeout, etc.)
                      errorBuilder: (_, error, __) {
                        debugPrint('[PackOpening] image error for "$url": $error');
                        return _AvatarFallback(
                          name: name,
                          cardType: cardType,
                          color: color,
                        );
                      },
                    )
                  : _AvatarFallback(
                      name: name,
                      cardType: cardType,
                      color: color,
                    ),
            ),
          ),
          // Halo GOAT
          if (isGoat)
            CustomPaint(
              size: const Size(size + 20, size + 20),
              painter: _DashedCirclePainter(
                color: _gold.withValues(alpha: 0.4),
                dashCount: 30,
                strokeWidth: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

// Shimmer mientras la imagen carga
class _AvatarShimmer extends StatefulWidget {
  final Color color;
  const _AvatarShimmer({required this.color});
  @override
  State<_AvatarShimmer> createState() => _AvatarShimmerState();
}

class _AvatarShimmerState extends State<_AvatarShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        color: widget.color.withValues(alpha: 0.06 + 0.08 * _anim.value),
      ),
    );
  }
}

// Fallback cuando no hay imagen: ícono del tipo + iniciales si hay nombre
class _AvatarFallback extends StatelessWidget {
  final String name;
  final String cardType;
  final Color color;
  const _AvatarFallback({
    required this.name,
    required this.cardType,
    required this.color,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;
    // Para jugadores mostramos iniciales; para los demás el ícono del tipo
    if (cardType == 'player' && initials.isNotEmpty) {
      return Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    return Center(
      child: Icon(
        _typeIcon(cardType),
        size: 32,
        color: color.withValues(alpha: 0.5),
      ),
    );
  }
}

// Painter borde punteado circular
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;

  const _DashedCirclePainter({
    required this.color,
    required this.dashCount,
    this.strokeWidth = 1.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final paint  = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final dashAngle = (2 * math.pi) / dashCount;
    final gapFraction = 0.38;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color || old.dashCount != dashCount;
}

// ════════════════════════════════════════════════════════════
//  FASE done — resultado completo
// ════════════════════════════════════════════════════════════
class _DoneView extends StatefulWidget {
  final PackOpenResult result;
  final int packsAvailable;

  const _DoneView({
    super.key,
    required this.result,
    required this.packsAvailable,
  });

  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.result.allCards;

    return FadeTransition(
      opacity: _fade,
      child: Column(
        children: [
          // ── Sub-header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                const Text(
                  'TUS CARTAS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _text,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(4, (i) => Container(
                    width: 14, height: 14,
                    margin: const EdgeInsets.only(left: 4),
                    color: i < cards.length ? _accent : const Color(0xFFD4CFC5),
                  )),
                ),
              ],
            ),
          ),

          // Leyenda
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              children: [
                _RarityDot(color: const Color(0xFF5B4FD8), label: 'RARO'),
                const SizedBox(width: 14),
                _RarityDot(color: const Color(0xFFE0435A), label: 'ÉPICO'),
                const SizedBox(width: 14),
                _RarityDot(color: _gold, label: 'LEGENDARIO'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Grid cartas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: cards.length,
                itemBuilder: (_, i) => _CardContent(card: cards[i], index: i),
              ),
            ),
          ),

          // ── Banner completado + botones
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border, width: 1.5)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            child: Column(
              children: [
                // Banner ¡SOBRE COMPLETADO!
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    border: Border.all(color: _accent.withValues(alpha: 0.3), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '¡SOBRE COMPLETADO!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: _accent,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Botón principal VER MI COLECCIÓN
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _accent,
                      border: Border.all(color: _border, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: _shadow, offset: Offset(4, 4)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'VER MI COLECCIÓN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}