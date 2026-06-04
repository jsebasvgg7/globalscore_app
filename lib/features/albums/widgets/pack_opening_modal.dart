import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';
import '../data/albums_service.dart';
import '../../../shared/layout/scaffold_with_nav_bar.dart';

// ── Paleta exacta del diseño ──────────────────────────────
const _bg     = Color(0xFFF5F0E8);   // crema
const _card   = Color(0xFFEDE7DA);
const _border = Color(0xFF1A1A2E);
const _accent = Color(0xFF5B2EFF);   // morado GA
const _accentDark = Color(0xFF3A1DB3);
const _gold   = Color(0xFFFFD600);
const _shadow = Color(0x661A1A2E);
const _muted  = Color(0xFF6B6660);
const _text   = Color(0xFF1A1A2E);
const _white  = Colors.white;

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
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.zero,
        border: Border(top: BorderSide(color: _border, width: 2)),
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
    setState(() {
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _phase    = _Phase.idle;
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

  bool get _allRevealed => _result != null && _revealed.length >= (_result!.allCards.length);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header GA fijo
        _GaHeader(packsAvailable: _packsAvailable),

        // ── Contenido por fase
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            child: switch (_phase) {
              _Phase.idle => _IdleView(
                  key: const ValueKey('idle'),
                  packsAvailable: _packsAvailable,
                  onOpen: _startOpening,
                  errorMsg: _errorMsg,
                ),
              _Phase.opening => const _OpeningView(key: ValueKey('opening')),
              _Phase.revealing => _RevealingView(
                  key: const ValueKey('revealing'),
                  result: _result!,
                  revealed: _revealed,
                  allRevealed: _allRevealed,
                  onReveal: _revealCard,
                  onFinish: () => setState(() => _phase = _Phase.done),
                ),
              _Phase.done => _DoneView(
                  key: const ValueKey('done'),
                  result: _result!,
                  packsAvailable: _packsAvailable,
                  onOpenAnother: _packsAvailable > 0 ? _startOpening : null,
                ),
            },
          ),
        ),
      ],
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
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
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
              // Sobre 3D animado
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: const _Pack3D(),
                ),
              ),

              const SizedBox(height: 32),

              // Contador de sobres
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _border,
                  boxShadow: const [
                    BoxShadow(color: _shadow, offset: Offset(3, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32, height: 32,
                      color: _accent,
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.packsAvailable}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SOBRES DISPONIBLES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.errorMsg != null) ...[
                const SizedBox(height: 12),
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
                        ? const [BoxShadow(color: _shadow, offset: Offset(4, 4))]
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

              // Footer categorías
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CategoryPill(label: 'JUGADOR'),
                  _Dot(),
                  _CategoryPill(label: 'EQUIPO'),
                  _Dot(),
                  _CategoryPill(label: 'COPA'),
                  _Dot(),
                  _CategoryPill(label: 'EVENTO'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill({required this.label});
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _muted,
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
//  SOBRE 3D — capas apiladas efecto profundidad
// ════════════════════════════════════════════════════════════
class _Pack3D extends StatelessWidget {
  const _Pack3D();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170, height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Capa sombra más profunda
          Positioned(
            top: 14, left: 14,
            child: Container(
              width: 140, height: 192,
              color: const Color(0xFF0D0A1F),
            ),
          ),
          // Capa intermedia (efecto 3D)
          Positioned(
            top: 8, left: 8,
            child: Container(
              width: 140, height: 192,
              decoration: BoxDecoration(
                color: const Color(0xFF3A2BB8),
                border: Border.all(color: _border, width: 1.5),
              ),
            ),
          ),
          // Cara frontal principal
          Positioned(
            top: 0, left: 0,
            child: Container(
              width: 140, height: 192,
              decoration: BoxDecoration(
                color: _accent,
                border: Border.all(color: _border, width: 2),
              ),
              child: Stack(
                children: [
                  // Diagonal stripes
                  Positioned.fill(
                    child: CustomPaint(painter: _StripePainter()),
                  ),
                  // Esquinas decorativas
                  ..._corners(),
                  // Logo central
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        // Escudo GA
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'GA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'GLOBAL ALBUMS',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          color: Colors.white.withValues(alpha: 0.15),
                          child: const Text(
                            '25 · 26',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Barcode top
                  Positioned(
                    top: 10, left: 0, right: 0,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(70, 14),
                        painter: _BarcodePainter(),
                      ),
                    ),
                  ),
                  // Corner accents gold
                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                        color: _gold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10, left: 10,
                    child: Container(
                      width: 8, height: 8,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() => [
        Positioned(
          top: 8, left: 8,
          child: _CornerBracket(topLeft: true),
        ),
        Positioned(
          top: 8, right: 8,
          child: _CornerBracket(topRight: true),
        ),
        Positioned(
          bottom: 8, left: 8,
          child: _CornerBracket(bottomLeft: true),
        ),
        Positioned(
          bottom: 8, right: 8,
          child: _CornerBracket(bottomRight: true),
        ),
      ];
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
            child: const _Pack3D(),
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
  final bool allRevealed;
  final void Function(int) onReveal;
  final VoidCallback onFinish;

  const _RevealingView({
    super.key,
    required this.result,
    required this.revealed,
    required this.allRevealed,
    required this.onReveal,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final cards = result.allCards;
    final total = cards.length;
    final revealedCount = revealed.length;

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
              // Indicadores cuadrados de progreso
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

        // ── Leyenda rareza (igual al diseño)
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

        // ── Grid 2×2
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
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
        ),

        // ── Footer
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TOCA CADA CARTA PARA REVELARLA',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _muted,
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
  final VoidCallback? onOpenAnother;

  const _DoneView({
    super.key,
    required this.result,
    required this.packsAvailable,
    this.onOpenAnother,
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

                // Botón ABRIR OTRO con contador
                GestureDetector(
                  onTap: widget.onOpenAnother,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: widget.onOpenAnother != null ? _accent : _muted,
                      border: Border.all(color: _border, width: 1.5),
                      boxShadow: widget.onOpenAnother != null
                          ? const [BoxShadow(color: _shadow, offset: Offset(4, 4))]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ABRIR OTRO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 26, height: 26,
                          color: Colors.white.withValues(alpha: 0.2),
                          alignment: Alignment.center,
                          child: Text(
                            '${widget.packsAvailable}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Link VER MI COLECCIÓN
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    'VER MI COLECCIÓN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.underline,
                      decorationColor: _accent,
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