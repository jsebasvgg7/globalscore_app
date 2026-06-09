import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';
import '../data/albums_service.dart';

// ════════════════════════════════════════════════════════════
//  PACK OPENING PAGE — neobrutalismo retro mobile-first
//  SOLO DISEÑO — lógica intacta
// ════════════════════════════════════════════════════════════

// ── Tokens ──────────────────────────────────────────────────
const _kBg        = Color(0xFFF5F2EC);
const _kBgDark    = Color(0xFF12101F);
const _kInk       = Color(0xFF1C1A2E);
const _kBorder    = Color(0xFF2D2A40);
const _kMuted     = Color(0xFF9B9590);
const _kAccent    = Color(0xFF5B4FD8);
const _kAccentDk  = Color(0xFF3D338F);
const _kGold      = Color(0xFFFFD600);
const _kShadow    = Color(0xFF302D41);

const _kFont = 'DM Mono';

// ── Colores por tipo ─────────────────────────────────────────
Color _typeColor(String t) => switch (t) {
      'player'      => const Color(0xFF5B4FD8),
      'team'        => const Color(0xFF1DAA75),
      'competition' => const Color(0xFFF59E0B),
      'event'       => const Color(0xFFE0435A),
      _             => _kAccent,
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

// ── Resolución de URL — soporta Cloudinary, Supabase y paths relativos ──
const _kCloudinaryBase = 'https://res.cloudinary.com/';
const _kSupabaseBase   =
    'https://auquyjigjceqzwpjbbff.supabase.co/storage/v1/object/public/historical/';

String? _resolveImageUrl(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;
  // Ya es URL completa (http / https)
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  // Path relativo → Supabase historical bucket
  final clean = s.startsWith('/') ? s.substring(1) : s;
  return '$_kSupabaseBase$clean';
}

// ════════════════════════════════════════════════════════════
//  PHASES
// ════════════════════════════════════════════════════════════
enum _Phase { opening, revealing, done, error }

// ════════════════════════════════════════════════════════════
//  PAGE — lógica intacta
// ════════════════════════════════════════════════════════════
class PackOpeningPage extends ConsumerStatefulWidget {
  const PackOpeningPage({super.key});

  @override
  ConsumerState<PackOpeningPage> createState() => _PackOpeningPageState();
}

class _PackOpeningPageState extends ConsumerState<PackOpeningPage> {
  _Phase _phase = _Phase.opening;
  PackOpenResult? _result;
  String? _errorMsg;
  final Set<int> _revealed = {};
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startOpening());
  }

  Future<void> _startOpening() async {
    if (_opened || !mounted) return;
    _opened = true;
    setState(() {
      _phase    = _Phase.opening;
      _result   = null;
      _errorMsg = null;
      _revealed.clear();
    });
    try {
      final userId = await ref.read(albumsUserIdProvider.future);
      final result = await AlbumsService().openPack(userId);
      if (mounted) {
        setState(() {
          _result = result;
          _phase  = _Phase.revealing;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _phase    = _Phase.error;
          _opened   = false;
        });
      }
    }
  }

  void _revealCard(int index) {
    final total = _result?.allCards.length ?? 0;
    if (_revealed.contains(index)) return;
    setState(() => _revealed.add(index));
    if (_revealed.length >= total) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _phase = _Phase.done);
      });
    }
  }

  void _revealAll() {
    final total = _result?.allCards.length ?? 0;
    for (int i = 0; i < total; i++) _revealed.add(i);
    setState(() => _phase = _Phase.done);
  }

  void _goBack() {
    ref.read(albumsProvider.notifier).refresh();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _NbHeader(onClose: _goBack),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_phase) {
      _Phase.opening   => _OpeningView(onAnimationDone: () {}),
      _Phase.revealing => _RevealingView(
          result:      _result!,
          revealed:    _revealed,
          onReveal:    _revealCard,
          onRevealAll: _revealAll,
        ),
      _Phase.done  => _DoneView(result: _result!, onBack: _goBack),
      _Phase.error => _ErrorView(
          msg:     _errorMsg ?? 'Error desconocido',
          onRetry: () { _opened = false; _startOpening(); },
          onBack:  _goBack,
        ),
    };
  }
}

// ════════════════════════════════════════════════════════════
//  HEADER
// ════════════════════════════════════════════════════════════
class _NbHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _NbHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: _kBgDark,
        border: Border(bottom: BorderSide(color: _kAccent, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kAccent,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const Center(
              child: Text('GA',
                style: TextStyle(
                  fontFamily: _kFont, fontSize: 9,
                  fontWeight: FontWeight.w900, color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('GLOBAL ALBUMS',
                  style: TextStyle(
                    fontFamily: _kFont, fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 2,
                  ),
                ),
                const Text('APERTURA DE SOBRE',
                  style: TextStyle(
                    fontFamily: _kFont, fontSize: 13,
                    fontWeight: FontWeight.w900, color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Icon(Icons.close, size: 15,
                  color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  OPENING VIEW
// ════════════════════════════════════════════════════════════
class _OpeningView extends StatefulWidget {
  final VoidCallback onAnimationDone;
  const _OpeningView({required this.onAnimationDone});

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
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Sobre — ocupa ~58% de la pantalla
        Expanded(
          flex: 58,
          child: Center(
            child: Padding(
              // Empujamos un poco hacia abajo respecto al centro puro
              padding: const EdgeInsets.only(top: 24),
              child: AnimatedBuilder(
                animation: _float,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _float.value),
                  child: const _EnvelopeStack(),
                ),
              ),
            ),
          ),
        ),

        // ── Estado ────────────────────────────────────────
        Expanded(
          flex: 42,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Barra de carga neobrut
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    const Text('ABRIENDO SOBRE...',
                      style: TextStyle(
                        fontFamily: _kFont, fontSize: 9,
                        fontWeight: FontWeight.w900, color: _kMuted,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => Container(
                        height: 3,
                        decoration: BoxDecoration(
                          border: Border.all(color: _kBorder, width: 1),
                        ),
                        child: LinearProgressIndicator(
                          value: null,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(_kAccent),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Chips de tipo
              const _TypeChipsRow(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ENVELOPE STACK — sobre con flap triangular (diseño original)
//  Recuperado de la versión anterior con _EnvelopePainter
// ════════════════════════════════════════════════════════════
class _EnvelopeStack extends StatelessWidget {
  const _EnvelopeStack();

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final w = (screenW * 0.50).clamp(150.0, 210.0);
    final h = w * 1.38;
    const off = 8.0;

    return SizedBox(
      width: w + off * 2 + 4,
      height: h + off + 6,
      child: Stack(
        children: [
          // Sombra difusa
          Positioned(
            top: off + 6, left: off + 4,
            child: Container(
              width: w, height: h,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 20, spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Capa trasera
          Positioned(
            top: off, left: off * 1.5,
            child: CustomPaint(
              size: Size(w, h),
              painter: _EnvelopePainter(
                bodyColor:   const Color(0xFF18144A),
                borderColor: const Color(0xFF2E2870),
                flapColor:   const Color(0xFF100D32),
                isFront: false,
              ),
            ),
          ),
          // Capa media
          Positioned(
            top: off * 0.5, left: off * 0.75,
            child: CustomPaint(
              size: Size(w, h),
              painter: _EnvelopePainter(
                bodyColor:   const Color(0xFF1E1860),
                borderColor: const Color(0xFF3A318A),
                flapColor:   const Color(0xFF150F44),
                isFront: false,
              ),
            ),
          ),
          // Frente principal
          Positioned(
            top: 0, left: 0,
            child: SizedBox(
              width: w, height: h,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(w, h),
                    painter: _EnvelopePainter(
                      bodyColor:   const Color(0xFF1C1480),
                      borderColor: const Color(0xFF7868F0),
                      flapColor:   const Color(0xFF050214),
                      isFront: true,
                    ),
                  ),
                  _EnvelopeFrontContent(w: w, h: h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter: body rect + flap triangular superior
class _EnvelopePainter extends CustomPainter {
  final Color bodyColor, borderColor, flapColor;
  final bool isFront;

  const _EnvelopePainter({
    required this.bodyColor, required this.borderColor,
    required this.flapColor, required this.isFront,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final flapH = h * 0.26;

    // Cuerpo
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..color = bodyColor..style = PaintingStyle.fill);

    // Rayas en el cuerpo
    if (isFront) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, flapH, w, h - flapH));
      _stripes(canvas, size, 0.12);
      canvas.restore();
    }

    // Flap triangular
    final flapPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w / 2, flapH)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(flapPath, Paint()..color = flapColor..style = PaintingStyle.fill);

    if (isFront) {
      canvas.save();
      canvas.clipPath(flapPath);
      _stripes(canvas, size, 0.06);
      canvas.restore();
    }

    // Borde exterior
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = borderColor.withValues(alpha: isFront ? 1.0 : 0.35)
        ..strokeWidth = isFront ? 2.0 : 1.0
        ..style = PaintingStyle.stroke);

    // Borde flap
    canvas.drawPath(flapPath,
      Paint()
        ..color = borderColor.withValues(alpha: isFront ? 0.55 : 0.2)
        ..strokeWidth = isFront ? 1.1 : 0.7
        ..style = PaintingStyle.stroke);

    // Línea de pliegue
    if (isFront) {
      canvas.drawLine(Offset(0, flapH), Offset(w, flapH),
        Paint()
          ..color = borderColor.withValues(alpha: 0.82)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke);
    }
  }

  void _stripes(Canvas canvas, Size size, double alpha) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width + size.height; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_EnvelopePainter o) => false;
}

// Contenido superpuesto: barcode, escudo, textos, esquinas doradas
class _EnvelopeFrontContent extends StatelessWidget {
  final double w, h;
  const _EnvelopeFrontContent({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    final flapH = h * 0.26;
    final scale = w / 155.0;

    return SizedBox(
      width: w, height: h,
      child: Stack(
        children: [
          // Barcode en el flap
          Positioned(
            top: flapH * 0.25, left: 0, right: 0,
            child: Center(
              child: CustomPaint(
                size: Size(60 * scale, 10 * scale),
                painter: _BarcodePainter(
                  color: Colors.white.withValues(alpha: 0.42)),
              ),
            ),
          ),

          // GS-25/26 bajo el barcode
          Positioned(
            top: flapH * 0.62, left: 0, right: 0,
            child: Center(
              child: Text('GS-25/26',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 6.5 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.52),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // Escudo GA pentagonal — centrado en la zona del cuerpo
          Positioned(
            top: flapH + 18 * scale,
            left: 0, right: 0,
            child: Center(child: _GaShield(scale: scale * 0.95, accentColor: _kAccent)),
          ),

          // GLOBAL ALBUMS
          Positioned(
            bottom: 40 * scale, left: 0, right: 0,
            child: Center(
              child: Text('GLOBAL ALBUMS',
                style: TextStyle(
                  fontFamily: _kFont, fontSize: 9 * scale,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.92),
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),

          // Temporada
          Positioned(
            bottom: 22 * scale, left: 0, right: 0,
            child: Center(
              child: Text('25  ·  26',
                style: TextStyle(
                  fontFamily: _kFont, fontSize: 7.5 * scale,
                  color: Colors.white.withValues(alpha: 0.45),
                  letterSpacing: 3.5,
                ),
              ),
            ),
          ),

          // Esquinas doradas (solo zona del cuerpo, no del flap)
          Positioned(top: flapH + 8 * scale, left:  8 * scale, child: _GoldCorner(scale: scale)),
          Positioned(top: flapH + 8 * scale, right: 8 * scale, child: _GoldCorner(scale: scale, flipH: true)),
          Positioned(bottom: 8 * scale,      left:  8 * scale, child: _GoldCorner(scale: scale, flipV: true)),
          Positioned(bottom: 8 * scale,      right: 8 * scale, child: _GoldCorner(scale: scale, flipH: true, flipV: true)),
        ],
      ),
    );
  }
}

// ── Chips de tipo ──────────────────────────────────────────────
class _TypeChipsRow extends StatelessWidget {
  const _TypeChipsRow();

  @override
  Widget build(BuildContext context) {
    const types = [
      ('JUGADOR', Color(0xFF5B4FD8)),
      ('EQUIPO',  Color(0xFF1DAA75)),
      ('COPA',    Color(0xFFF59E0B)),
      ('EVENTO',  Color(0xFFE0435A)),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < types.length; i++) ...[
          Text(types[i].$1,
            style: TextStyle(
              fontFamily: _kFont, fontSize: 8,
              fontWeight: FontWeight.w700,
              color: types[i].$2, letterSpacing: 0.8,
            ),
          ),
          if (i < types.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('•', style: TextStyle(color: _kMuted.withValues(alpha: 0.7), fontSize: 9)),
            ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  REVEALING VIEW
// ════════════════════════════════════════════════════════════
class _RevealingView extends StatelessWidget {
  final PackOpenResult result;
  final Set<int> revealed;
  final void Function(int) onReveal;
  final VoidCallback onRevealAll;

  const _RevealingView({
    required this.result, required this.revealed,
    required this.onReveal, required this.onRevealAll,
  });

  @override
  Widget build(BuildContext context) {
    final cards    = result.allCards;
    final total    = cards.length;
    final revCount = revealed.length;
    final allDone  = revCount >= total;

    return Column(
      children: [
        // ── Header con indicadores ───────────────────────
        Container(
          decoration: const BoxDecoration(
            color: _kBg,
            border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              const Text('TUS CARTAS',
                style: TextStyle(
                  fontFamily: _kFont, fontSize: 13,
                  fontWeight: FontWeight.w900, color: _kInk,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(total, (i) => Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(
                    width: 13, height: 13,
                    color: revealed.contains(i) ? _kAccent : const Color(0xFFCBC6BA),
                  ),
                )),
              ),
            ],
          ),
        ),

        // ── Grid 2×2 — ocupa todo el espacio restante ────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final cellW = (constraints.maxWidth - 10) / 2;
                final cellH = (constraints.maxHeight - 10) / 2;
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: cellW / cellH,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(total, (i) => _FlipCard(
                    card: cards[i],
                    isRevealed: revealed.contains(i),
                    onTap: () => onReveal(i),
                  )),
                );
              },
            ),
          ),
        ),

        // ── Footer ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: GestureDetector(
            onTap: allDone ? null : onRevealAll,
            child: Text(
              allDone
                  ? '¡TOCA VER RESULTADO!'
                  : 'TOCA CADA CARTA PARA REVELARLA  •  $revCount/$total',
              style: TextStyle(
                fontFamily: _kFont, fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: allDone ? _kAccent : _kMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Flip card ─────────────────────────────────────────────────
class _FlipCard extends StatefulWidget {
  final AlbumCard card;
  final bool isRevealed;
  final VoidCallback onTap;
  const _FlipCard({required this.card, required this.isRevealed, required this.onTap});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.isRevealed && !old.isRevealed) _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRevealed ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final angle     = _anim.value * math.pi;
          final showFront = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _CardFront(card: widget.card),
                  )
                : _CardBack(),
          );
        },
      ),
    );
  }
}

// ── Reverso — oculta la carta ─────────────────────────────────
class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12101E),
        border: Border.all(color: _kAccent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: const [BoxShadow(color: _kShadow, offset: Offset(3, 3))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StripePainter())),
          // Brackets
          const Positioned(top: 8, left: 8, child: _Bracket()),
          const Positioned(top: 8, right: 8, child: _Bracket(flipH: true)),
          const Positioned(bottom: 8, left: 8, child: _Bracket(flipV: true)),
          const Positioned(bottom: 8, right: 8, child: _Bracket(flipH: true, flipV: true)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GaShield(scale: 0.82, accentColor: _kAccent),
                const SizedBox(height: 8),
                Text('GS-25/26',
                  style: TextStyle(
                    fontFamily: _kFont, fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.25),
                    letterSpacing: 1.8,
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

// ── Frente — carta revelada ───────────────────────────────────
class _CardFront extends StatelessWidget {
  final AlbumCard card;
  const _CardFront({required this.card});

  @override
  Widget build(BuildContext context) {
    final color  = _typeColor(card.cardType);
    final label  = _typeLabel(card.cardType);
    final isGoat = card.isGoat;
    final stars  = card.significanceLevel ?? 1;
    final numStr = switch (card.cardType) {
      'player'      => '001',
      'team'        => '002',
      'competition' => '003',
      _             => '004',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isGoat ? _kGold : color, width: isGoat ? 2.5 : 1.8),
        boxShadow: [
          BoxShadow(
            color: isGoat ? _kGold.withValues(alpha: 0.45) : color.withValues(alpha: 0.3),
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Número + badge tipo
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(numStr,
                  style: TextStyle(
                    fontFamily: _kFont, fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: color, letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(label,
                    style: TextStyle(
                      fontFamily: _kFont, fontSize: 6,
                      fontWeight: FontWeight.w900, color: color,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar circular con dashed border
          Expanded(
            flex: 6,
            child: Center(
              child: _CircularAvatar(
                imagePath: card.imagePath,
                name:      card.name,
                color:     color,
                isGoat:    isGoat,
                cardType:  card.cardType,
              ),
            ),
          ),

          // Estrellas — todos los tipos
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Text('★',
                style: TextStyle(
                  fontSize: 10,
                  color: i < stars
                      ? (isGoat ? _kGold : color)
                      : const Color(0xFFDDDAD4),
                ),
              )),
            ),
          ),

          // Separador
          Container(height: 1, color: const Color(0xFFE8E4DC)),

          // Badge tipo + nombre
          Container(
            color: const Color(0xFFF2EFE8),
            padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(label,
                    style: TextStyle(
                      fontFamily: _kFont, fontSize: 6.5,
                      fontWeight: FontWeight.w900, color: color,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(card.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _kFont, fontSize: 9,
                    fontWeight: FontWeight.w900, color: _kInk,
                    height: 1.2, letterSpacing: 0.2,
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

// ════════════════════════════════════════════════════════════
//  DONE VIEW
// ════════════════════════════════════════════════════════════
class _DoneView extends StatelessWidget {
  final PackOpenResult result;
  final VoidCallback onBack;
  const _DoneView({required this.result, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final cards  = result.allCards;
    final total  = cards.length;
    final goat   = result.hasGoat;
    final stars4 = cards.where((c) => (c.significanceLevel ?? 0) >= 4).length;

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: _kBg,
            border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              const Text('TUS CARTAS',
                style: TextStyle(
                  fontFamily: _kFont, fontSize: 13,
                  fontWeight: FontWeight.w900, color: _kInk,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(
                    width: 13, height: 13,
                    color: i < total ? _kAccent : const Color(0xFFCBC6BA),
                  ),
                )),
              ),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final cellW = (constraints.maxWidth - 10) / 2;
                final cellH = (constraints.maxHeight - 10) / 2;
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: cellW / cellH,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: cards.map((c) => _CardFront(card: c)).toList(),
                );
              },
            ),
          ),
        ),

        // Stats + botón
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Text('$total CARTAS',
                style: const TextStyle(
                  fontFamily: _kFont, fontSize: 8,
                  fontWeight: FontWeight.w900, color: _kMuted,
                  letterSpacing: 1,
                ),
              ),
              if (stars4 > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('•', style: TextStyle(color: _kMuted.withValues(alpha: 0.7), fontSize: 8)),
                ),
                Text('$stars4 ÉPICA${stars4 > 1 ? 'S' : ''}',
                  style: const TextStyle(
                    fontFamily: _kFont, fontSize: 8,
                    fontWeight: FontWeight.w900, color: Color(0xFFF59E0B),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
              if (goat) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('•', style: TextStyle(color: _kMuted.withValues(alpha: 0.7), fontSize: 8)),
                ),
                const Text('1 GOAT',
                  style: TextStyle(
                    fontFamily: _kFont, fontSize: 8,
                    fontWeight: FontWeight.w900, color: _kGold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: _NbButton(label: 'VER MI COLECCIÓN', onTap: onBack),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ERROR VIEW
// ════════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _ErrorView({required this.msg, required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isNoTickets = msg.contains('No tienes');
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder, width: 2),
              boxShadow: const [BoxShadow(color: _kShadow, offset: Offset(4, 4))],
            ),
            child: Icon(
              isNoTickets ? Icons.confirmation_num_outlined : Icons.error_outline,
              size: 28,
              color: isNoTickets ? _kMuted : Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isNoTickets ? 'SIN SOBRES' : 'ERROR',
            style: const TextStyle(
              fontFamily: _kFont, fontSize: 16,
              fontWeight: FontWeight.w900, color: _kInk,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kFont, fontSize: 9.5,
              color: _kMuted, letterSpacing: 0.5, height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          if (!isNoTickets) ...[
            _NbButton(label: 'REINTENTAR', onTap: onRetry),
            const SizedBox(height: 14),
          ],
          GestureDetector(
            onTap: onBack,
            child: const Text('VOLVER',
              style: TextStyle(
                fontFamily: _kFont, fontSize: 9,
                fontWeight: FontWeight.w700, color: _kMuted,
                letterSpacing: 2, decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ════════════════════════════════════════════════════════════

class _NbButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NbButton({required this.label, required this.onTap});

  @override
  State<_NbButton> createState() => _NbButtonState();
}

class _NbButtonState extends State<_NbButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: _pressed
            ? (Matrix4.identity()..translate(4.0, 4.0))
            : Matrix4.identity(),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: _kAccent,
          border: Border.all(color: _kBorder, width: 2),
          boxShadow: _pressed
              ? null
              : const [BoxShadow(color: _kShadow, offset: Offset(4, 4))],
        ),
        child: Center(
          child: Text(widget.label,
            style: const TextStyle(
              fontFamily: _kFont, fontSize: 12,
              fontWeight: FontWeight.w900, color: Colors.white,
              letterSpacing: 2.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Avatar circular con dashed border ─────────────────────────
class _CircularAvatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  final Color color;
  final bool isGoat;
  final String cardType;

  const _CircularAvatar({
    required this.imagePath, required this.name,
    required this.color, required this.isGoat, required this.cardType,
  });

  @override
  Widget build(BuildContext context) {
    const size = 70.0;
    final url = _resolveImageUrl(imagePath);
    return SizedBox(
      width: size + 14, height: size + 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed circle exterior
          CustomPaint(
            size: const Size(size + 14, size + 14),
            painter: _DashedCirclePainter(
              color: isGoat ? _kGold : color,
              dashCount: 22, strokeWidth: 1.8,
            ),
          ),
          // Segundo anillo GOAT
          if (isGoat)
            CustomPaint(
              size: const Size(size + 24, size + 24),
              painter: _DashedCirclePainter(
                color: _kGold.withValues(alpha: 0.35),
                dashCount: 32, strokeWidth: 1.1,
              ),
            ),
          // Imagen
          ClipOval(
            child: Container(
              width: size, height: size,
              color: color.withValues(alpha: 0.08),
              child: url != null
                  ? Image.network(url, fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) {
                        if (prog == null) return child;
                        return _AvatarShimmer(color: color);
                      },
                      errorBuilder: (_, e, __) {
                        debugPrint('[Pack] image error for "$imagePath": $e');
                        return _AvatarFallback(name: name, cardType: cardType, color: color);
                      })
                  : _AvatarFallback(name: name, cardType: cardType, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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

class _AvatarFallback extends StatelessWidget {
  final String name;
  final String cardType;
  final Color color;
  const _AvatarFallback({required this.name, required this.cardType, required this.color});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;
    if (cardType == 'player' && initials.isNotEmpty) {
      return Center(child: Text(initials,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
          color: color.withValues(alpha: 0.7))));
    }
    return Center(child: Icon(_typeIcon(cardType), size: 30,
        color: color.withValues(alpha: 0.5)));
  }
}

// ── GA Shield pentagonal ──────────────────────────────────────
class _GaShield extends StatelessWidget {
  final double scale;
  final Color accentColor;
  const _GaShield({required this.scale, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final size = 62.0 * scale;
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _ShieldPainter(accentColor: accentColor),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 4 * scale),
            child: Text('GA',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 17 * scale,
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
    final w = size.width; final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)..lineTo(w, h * 0.25)..lineTo(w, h * 0.65)
      ..lineTo(w * 0.5, h)..lineTo(0, h * 0.65)..lineTo(0, h * 0.25)..close();
    canvas.drawPath(path, Paint()..color = accentColor.withValues(alpha: 0.22)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = accentColor.withValues(alpha: 0.9)..style = PaintingStyle.stroke..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(_ShieldPainter o) => o.accentColor != accentColor;
}

// ── Painters ──────────────────────────────────────────────────
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 14..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width + size.height; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }
  @override bool shouldRepaint(_StripePainter o) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;
  const _DashedCirclePainter({required this.color, required this.dashCount, this.strokeWidth = 1.8});

  @override
  void paint(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = (size.width / 2) - strokeWidth;
    final paint     = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    final dashAngle = (2 * math.pi) / dashCount;
    const gap = 0.38;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          i * dashAngle, dashAngle * (1 - gap), false, paint);
    }
  }
  @override bool shouldRepaint(_DashedCirclePainter o) => o.color != color;
}

class _BarcodePainter extends CustomPainter {
  final Color color;
  const _BarcodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    double x = 0;
    while (x < size.width) {
      final w = rng.nextDouble() * 3 + 1;
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height),
        Paint()..color = color..style = PaintingStyle.fill);
      x += w + rng.nextDouble() * 2 + 0.5;
    }
  }
  @override bool shouldRepaint(_BarcodePainter o) => false;
}

class _Bracket extends StatelessWidget {
  final bool flipH, flipV;
  const _Bracket({this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1, scaleY: flipV ? -1 : 1,
      child: CustomPaint(
        size: const Size(11, 11),
        painter: _BracketPainter(color: Colors.white.withValues(alpha: 0.4), strokeWidth: 1.5),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _BracketPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), p);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), p);
  }
  @override bool shouldRepaint(_BracketPainter o) => false;
}

class _GoldCorner extends StatelessWidget {
  final double scale;
  final bool flipH, flipV;
  const _GoldCorner({required this.scale, this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1, scaleY: flipV ? -1 : 1,
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
    final p = Paint()..color = _kGold..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), p);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), p);
  }
  @override bool shouldRepaint(_GoldCornerPainter o) => false;
}