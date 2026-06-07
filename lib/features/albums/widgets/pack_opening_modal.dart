import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';
import '../data/albums_service.dart';

// ── Paleta ───────────────────────────────────────────────────
const _bg         = Color(0xFFF5F2EC);
const _bgDark     = Color(0xFF12101F);
const _border     = Color(0xFF2D2A40);
const _accent     = Color(0xFF5B4FD8);
const _accentDark = Color(0xFF3D338F);
const _gold       = Color(0xFFFFD600);
const _shadow     = Color(0xFF302D41);
const _muted      = Color(0xFF9B9590);
const _text       = Color(0xFF1C1A2E);

// ── Colores por tipo ─────────────────────────────────────────
Color _typeColor(String t) => switch (t) {
      'player'      => const Color(0xFF5B4FD8),
      'team'        => const Color(0xFF1DAA75),
      'competition' => const Color(0xFFF59E0B),
      'event'       => const Color(0xFFE0435A),
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
//  Ahora acepta onViewCollection para navegar al tab colección
// ════════════════════════════════════════════════════════════
void showPackOpeningModal(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onViewCollection,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _PackOpeningDialog(onViewCollection: onViewCollection),
    ),
  ).then((_) {
    ref.read(packOpenProvider.notifier).reset();
    ref.invalidate(albumsProvider);
  });
}

// ════════════════════════════════════════════════════════════
//  DIALOG CONTAINER — modal flotante centrado
// ════════════════════════════════════════════════════════════
class _PackOpeningDialog extends StatelessWidget {
  final VoidCallback? onViewCollection;
  const _PackOpeningDialog({this.onViewCollection});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
      child: Container(
        height: (screenH * 0.85).clamp(500.0, 720.0),
        decoration: BoxDecoration(
          color: _bg,
          border: Border.all(color: _border, width: 2.5),
          boxShadow: const [BoxShadow(color: _shadow, offset: Offset(6, 6))],
        ),
        child: _PackOpeningFlow(onViewCollection: onViewCollection),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MÁQUINA DE ESTADOS
// ════════════════════════════════════════════════════════════
enum _Phase { idle, opening, revealing, done }

class _PackOpeningFlow extends ConsumerStatefulWidget {
  final VoidCallback? onViewCollection;
  const _PackOpeningFlow({this.onViewCollection});

  @override
  ConsumerState<_PackOpeningFlow> createState() => _PackOpeningFlowState();
}

class _PackOpeningFlowState extends ConsumerState<_PackOpeningFlow> {
  _Phase _phase = _Phase.idle;
  PackOpenResult? _result;
  String? _errorMsg;
  bool _isOpening = false;
  final Set<int> _revealed = {};

  int get _packsAvailable {
    // Reactivo: se reconstruye cuando el StreamProvider emite un nuevo valor
    // (el Realtime de album_packs dispara el reload automáticamente)
    return ref.watch(albumsProvider).value?.packs?.packsAvailable ?? 0;
  }

  Future<void> _startOpening() async {
    if (_isOpening) return;
    if (_packsAvailable <= 0) return;
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

      debugPrint('╔══ IMAGE PATHS ════════════════════════');
      for (final card in result.allCards) {
        debugPrint('║ [${card.cardType}] ${card.name} → "${card.imagePath}"');
      }
      debugPrint('╚═══════════════════════════════════════');

      // NO invalidar aquí: el StreamProvider ya detecta el cambio
      // en album_packs vía Realtime y recarga solo.
      // Invalidar mientras el modal está abierto destruiría el canal
      // y crearía una ventana sin escucha de eventos.

      if (mounted) {
        setState(() {
          _result    = result;
          _phase     = _Phase.revealing;
          _isOpening = false;
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
    if (_revealed.length >= total) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _phase = _Phase.done);
      });
    }
  }

  // Cierra el dialog y navega al tab de colección
  void _goToCollection() {
    Navigator.of(context).pop();
    widget.onViewCollection?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isRevealing = _phase == _Phase.revealing;
    final total = _result?.allCards.length ?? 0;
    final revealedCount = _revealed.length;
    final allDone = isRevealing && total > 0 && revealedCount >= total;

    // ── Fase revealing: layout especial (mínimo) ──────────────
    if (isRevealing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GaHeader(packsAvailable: _packsAvailable),
          _RevealingView(
            result: _result!,
            revealed: _revealed,
            onReveal: _revealCard,
            onFinish: () => setState(() => _phase = _Phase.done),
          ),
          // Footer: botón REVELAR TODO o contador progreso
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border, width: 1)),
            ),
            child: allDone
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¡LISTO!',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: _accent,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$revealedCount/$total',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: _accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      for (int i = 0; i < total; i++) {
                        _revealCard(i);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _bgDark,
                        border: Border.all(color: _border, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: _shadow, offset: Offset(3, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'REVELAR TODO  ·  $revealedCount/$total',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      );
    }

    // ── Resto de fases ────────────────────────────────────────
    return Column(
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
              _Phase.revealing => const SizedBox.shrink(),
              _Phase.done => _DoneView(
                  key: const ValueKey('done'),
                  result: _result!,
                  onViewCollection: _goToCollection,
                ),
            },
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  HEADER — fondo negro, logo GA, X cierre
// ════════════════════════════════════════════════════════════
class _GaHeader extends StatelessWidget {
  final int packsAvailable;
  const _GaHeader({required this.packsAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: _bgDark,
        border: Border(bottom: BorderSide(color: _border, width: 1.5)),
      ),
      child: Row(
        children: [
          // Logo GA cuadrado morado
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _accent,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Text(
              'GA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GLOBAL ALBUMS · 25/26',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                'APERTURA DE SOBRE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botón cerrar
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FASE idle — sobre plano 2D + contador
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
      duration: const Duration(milliseconds: 2400),
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

    return Stack(
      children: [
        // Fondo de dots grid sutil
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

        // Marcos viewfinder en esquinas
        Positioned(top: 18, left: 18,
          child: CustomPaint(size: const Size(24, 24),
            painter: _BracketPainter(color: _accent.withValues(alpha: 0.35), strokeWidth: 2.0))),
        Positioned(top: 18, right: 18,
          child: Transform.scale(scaleX: -1,
            child: CustomPaint(size: const Size(24, 24),
              painter: _BracketPainter(color: _accent.withValues(alpha: 0.35), strokeWidth: 2.0)))),
        Positioned(bottom: 108, left: 18,
          child: Transform.scale(scaleY: -1,
            child: CustomPaint(size: const Size(24, 24),
              painter: _BracketPainter(color: _accent.withValues(alpha: 0.35), strokeWidth: 2.0)))),
        Positioned(bottom: 108, right: 18,
          child: Transform.scale(scaleX: -1, scaleY: -1,
            child: CustomPaint(size: const Size(24, 24),
              painter: _BracketPainter(color: _accent.withValues(alpha: 0.35), strokeWidth: 2.0)))),

        Column(
          children: [
            // Zona sobre
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sobre flotando
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: const _FlatPack(scale: 1.15),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Contador de sobres
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                        decoration: BoxDecoration(
                          color: _accent,
                          border: Border.all(color: _border, width: 2),
                          boxShadow: const [
                            BoxShadow(color: _shadow, offset: Offset(4, 4)),
                          ],
                        ),
                        child: Text(
                          '${widget.packsAvailable}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        color: _border,
                        child: const Text(
                          'SOBRES DISPONIBLES',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Zona inferior
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _border, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  // Error si lo hay
                  if (widget.errorMsg != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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

                  // Botón TOCA PARA ABRIR
                  GestureDetector(
                    onTap: canOpen ? widget.onOpen : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        color: canOpen ? _accent : _muted,
                        border: Border.all(color: _border, width: 2),
                        boxShadow: canOpen
                            ? const [BoxShadow(color: _accentDark, offset: Offset(4, 4))]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        canOpen
                            ? (widget.errorMsg != null ? 'REINTENTAR' : 'TOCA PARA ABRIR')
                            : 'SIN SOBRES',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Categorías con colores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CatLabel(label: 'JUGADOR', color: const Color(0xFF5B4FD8)),
                      _Sep(),
                      _CatLabel(label: 'EQUIPO', color: const Color(0xFF1DAA75)),
                      _Sep(),
                      _CatLabel(label: 'COPA', color: const Color(0xFFF59E0B)),
                      _Sep(),
                      _CatLabel(label: 'EVENTO', color: const Color(0xFFE0435A)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FASE opening — sobre plano + loading
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
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -12).animate(
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
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _float,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _float.value),
                child: const _FlatPack(scale: 1.15),
              ),
            ),
            const SizedBox(height: 44),
            const Text(
              'ABRIENDO SOBRE...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: _muted,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final v = ((_ctrl.value + i / 3) % 1.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 9, height: 9,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.2 + 0.8 * v),
                      border: Border.all(color: _border, width: 1),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FASE revealing — grid 2×2, cartas ocultas/reveladas
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
        // Sub-header "TUS CARTAS" + indicadores
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _border, width: 1)),
          ),
          child: Row(
            children: [
              const Text(
                'TUS CARTAS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _text,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(total, (i) => Container(
                  width: 15, height: 15,
                  margin: const EdgeInsets.only(left: 5),
                  color: revealed.contains(i) ? _accent : const Color(0xFFCBC6BA),
                )),
              ),
            ],
          ),
        ),

        // Grid 2×2
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: total,
            itemBuilder: (_, i) {
              if (revealed.contains(i)) {
                return _ResultCard(card: cards[i], index: i, animate: true);
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

// ════════════════════════════════════════════════════════════
//  FASE done — grid revelado + botón VER COLECCIÓN
// ════════════════════════════════════════════════════════════
class _DoneView extends StatefulWidget {
  final PackOpenResult result;
  final VoidCallback onViewCollection;

  const _DoneView({
    super.key,
    required this.result,
    required this.onViewCollection,
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
        vsync: this, duration: const Duration(milliseconds: 450));
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
          // Sub-header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                const Text(
                  'TUS CARTAS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _text,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(4, (i) => Container(
                    width: 15, height: 15,
                    margin: const EdgeInsets.only(left: 5),
                    color: i < cards.length ? _accent : const Color(0xFFCBC6BA),
                  )),
                ),
              ],
            ),
          ),

          // ¡SOBRE COMPLETADO! debajo del header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: const Text(
              '¡SOBRE COMPLETADO!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _accent,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Grid de cartas + botón VER COLECCIÓN en scroll — nada se tapa
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Column(
                children: [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (_, i) => _CardContent(card: cards[i], index: i),
                  ),
                  const SizedBox(height: 16),
                  // Botón VER COLECCIÓN al final del scroll
                  GestureDetector(
                    onTap: widget.onViewCollection,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        color: _accent,
                        border: Border.all(color: _border, width: 2),
                        boxShadow: const [
                          BoxShadow(color: _accentDark, offset: Offset(4, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'VER MI COLECCIÓN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SOBRE 2D — diseño mejorado sin zigzags
//  Gradiente oscuro · banda lateral morada · bordes redondeados
//  Escudo trofeo · "GLOBAL ALBUMS" · "25 / 26"
// ════════════════════════════════════════════════════════════
class _FlatPack extends StatelessWidget {
  final double scale;
  const _FlatPack({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final w     = 160.0 * scale;
    final h     = 240.0 * scale;
    final leftW = w * 0.22;   // banda morada ≈ 22%
    final ipad  = 10.0 * scale;
    final r     = 8.0 * scale; // radio de esquinas

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Sombra externa decorativa ───────────────────────
          Positioned(
            top: 6 * scale, left: 6 * scale,
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                color: _accentDark.withValues(alpha: 0.5),
              ),
            ),
          ),

          // ── Cuerpo principal con clip redondeado ────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  // Fondo degradado oscuro
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1C1830),
                            Color(0xFF0E0C1A),
                            Color(0xFF1A1428),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Stripes diagonales sutiles de fondo
                  Positioned.fill(
                    child: CustomPaint(painter: _PackBgStripePainter()),
                  ),

                  // Banda morada izquierda
                  Positioned(
                    top: 0, left: 0, bottom: 0,
                    child: Container(
                      width: leftW,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _accent,
                            _accentDark,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Línea separadora banda/panel
                  Positioned(
                    top: 0, bottom: 0,
                    left: leftW,
                    child: Container(
                      width: 1.5,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),

                  // Marco interior con borde sutil
                  Positioned(
                    top: ipad,
                    left: leftW + ipad,
                    right: ipad,
                    bottom: ipad,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4 * scale),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.30),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),

                  // Puntos decorativos sup-izq
                  Positioned(
                    top: ipad + 7 * scale,
                    left: leftW + ipad + 6 * scale,
                    child: _PackDots(scale: scale * 0.85),
                  ),

                  // Puntos decorativos inf-der
                  Positioned(
                    bottom: ipad + 6 * scale,
                    right: ipad + 6 * scale,
                    child: _PackDots(scale: scale * 0.85),
                  ),

                  // Cuadraditos esquinas del marco
                  Positioned(
                    top: ipad - 3 * scale,
                    left: leftW + ipad - 3 * scale,
                    child: Container(width: 6 * scale, height: 6 * scale,
                      color: _accent.withValues(alpha: 0.7)),
                  ),
                  Positioned(
                    top: ipad - 3 * scale,
                    right: ipad - 3 * scale,
                    child: Container(width: 6 * scale, height: 6 * scale,
                      color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  Positioned(
                    bottom: ipad - 3 * scale,
                    left: leftW + ipad - 3 * scale,
                    child: Container(width: 6 * scale, height: 6 * scale,
                      color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  Positioned(
                    bottom: ipad - 3 * scale,
                    right: ipad - 3 * scale,
                    child: Container(width: 6 * scale, height: 6 * scale,
                      color: _accent.withValues(alpha: 0.7)),
                  ),

                  // Reflejo/luz superior sutil
                  Positioned(
                    top: 0, left: leftW, right: 0,
                    child: Container(
                      height: h * 0.28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Contenido centrado
                  Positioned(
                    top: 0, bottom: 0,
                    left: leftW, right: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TrophyShield(size: 54 * scale),
                        SizedBox(height: 10 * scale),
                        Text(
                          'GLOBAL ALBUMS',
                          style: TextStyle(
                            fontSize: 8.5 * scale,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.90),
                            letterSpacing: 2.2,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        _PackSeparator(width: 68 * scale, scale: scale),
                        SizedBox(height: 8 * scale),
                        Text(
                          '25 / 26',
                          style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w700,
                            color: _accent.withValues(alpha: 0.9),
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Borde exterior del sobre
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
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
}

// Stripes diagonales muy sutiles para el fondo del sobre
class _PackBgStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width + size.height; x += 36) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PackBgStripePainter old) => false;
}

// ── Escudo pentagonal con icono trofeo ───────────────────────
class _TrophyShield extends StatelessWidget {
  final double size;
  const _TrophyShield({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: CustomPaint(
        painter: _TrophyShieldPainter(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.05),
            child: Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: size * 0.44,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrophyShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.1, 0)
      ..lineTo(w * 0.9, 0)
      ..lineTo(w, h * 0.18)
      ..lineTo(w, h * 0.58)
      ..quadraticBezierTo(w, h * 0.82, w * 0.5, h)
      ..quadraticBezierTo(0, h * 0.82, 0, h * 0.58)
      ..lineTo(0, h * 0.18)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.1)..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(_TrophyShieldPainter old) => false;
}

// ── Puntos 3×3 decorativos ───────────────────────────────────
class _PackDots extends StatelessWidget {
  final double scale;
  const _PackDots({required this.scale});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(17 * scale, 11 * scale),
      painter: _PackDotsPainter(scale: scale),
    );
  }
}

class _PackDotsPainter extends CustomPainter {
  final double scale;
  const _PackDotsPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _accent.withValues(alpha: 0.50)
      ..style = PaintingStyle.fill;
    final r = 1.3 * scale;
    const cols = 4;
    const rows = 3;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        canvas.drawCircle(
          Offset(col * 5.0 * scale + r, row * 5.0 * scale + r),
          r,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PackDotsPainter old) => false;
}

// ── Separador horizontal con cuadraditos en extremos ─────────
class _PackSeparator extends StatelessWidget {
  final double width;
  final double scale;
  const _PackSeparator({required this.width, required this.scale});

  @override
  Widget build(BuildContext context) {
    final sqSize = 4.0 * scale;
    return SizedBox(
      width: width,
      height: sqSize,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: sqSize, height: sqSize, color: _accent),
          Expanded(
            child: Container(
              height: 1,
              color: _accent.withValues(alpha: 0.55),
            ),
          ),
          Container(width: sqSize, height: sqSize, color: _accent),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CARTA OCULTA — estilo sobre: gradiente oscuro + escudo GA
// ════════════════════════════════════════════════════════════
class _HiddenRevealCard extends StatefulWidget {
  final int index;
  const _HiddenRevealCard({required this.index});

  @override
  State<_HiddenRevealCard> createState() => _HiddenRevealCardState();
}

class _HiddenRevealCardState extends State<_HiddenRevealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1C1830),
                Color(0xFF0E0C1A),
                Color(0xFF1A1428),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.18 + 0.14 * _pulse.value),
                blurRadius: 10 + 6 * _pulse.value,
                spreadRadius: 0,
              ),
              const BoxShadow(color: _shadow, offset: Offset(3, 3)),
            ],
          ),
          child: Stack(
            children: [
              // Stripes diagonales sutiles
              Positioned.fill(child: CustomPaint(painter: _PackBgStripePainter())),

              // Borde interior pulsante
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.25 + 0.30 * _pulse.value),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Reflejo superior
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Brackets esquinas
              Positioned(top: 10, left: 10, child: _Bracket()),
              Positioned(top: 10, right: 10, child: _Bracket(flipH: true)),
              Positioned(bottom: 10, left: 10, child: _Bracket(flipV: true)),
              Positioned(bottom: 10, right: 10, child: _Bracket(flipH: true, flipV: true)),

              // Escudo GA centrado con halo pulsante
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Halo exterior
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accent.withValues(
                            alpha: 0.04 + 0.06 * _pulse.value),
                      ),
                      child: Center(
                        child: _GaShield(scale: 0.85, accentColor: _accent),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GA · 25/26',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.22),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CARTA REVELADA — flip 3D + diseño referencia
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
  late final Animation<double> _flip;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flip = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
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
    return AnimatedBuilder(
      animation: _flip,
      builder: (_, __) {
        final angle = _flip.value * math.pi;
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
                  child: _CardContent(card: widget.card, index: widget.index),
                )
              : _CardBack(),
        );
      },
    );
  }
}

// Espalda de carta durante el flip
class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12101E),
        border: Border.all(color: _accent.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StripePainter())),
          Center(child: _GaShield(scale: 0.8, accentColor: _accent)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CARTA CONTENIDO — diseño referencia fiel
// ════════════════════════════════════════════════════════════
class _CardContent extends StatelessWidget {
  final AlbumCard card;
  final int index;
  const _CardContent({required this.card, required this.index});

  @override
  Widget build(BuildContext context) {
    final color  = _typeColor(card.cardType);
    final label  = _typeLabel(card.cardType);
    final stars  = card.significanceLevel ?? 1;
    final numStr = (index + 1).toString().padLeft(3, '0');
    final isGoat = card.isGoat;
    final borderC = isGoat ? _gold : color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderC, width: isGoat ? 2.5 : 1.5),
        boxShadow: [
          BoxShadow(color: _shadow, offset: const Offset(3, 3)),
          if (isGoat)
            BoxShadow(
              color: _gold.withValues(alpha: 0.3),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Número + tipo arriba
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  numStr,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (card.cardType != 'player')
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.5,
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
                name: card.name,
                color: color,
                isGoat: isGoat,
                cardType: card.cardType,
              ),
            ),
          ),

          // Estrellas
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  '★',
                  style: TextStyle(
                    fontSize: 10,
                    color: i < stars
                        ? (isGoat ? _gold : color)
                        : const Color(0xFFDDDAD4),
                  ),
                ),
              )),
            ),
          ),

          // Separador
          Container(height: 1, color: const Color(0xFFE8E4DC)),

          // Badge tipo + nombre
          Container(
            color: const Color(0xFFF2EFE8),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: _text,
                    height: 1.2,
                    letterSpacing: 0.3,
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
//  AVATAR CIRCULAR
// ════════════════════════════════════════════════════════════
const _supabaseStorageBase =
    'https://auquyjigjceqzwpjbbff.supabase.co/storage/v1/object/public/historical/';

String? _resolveImageUrl(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
  final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '$_supabaseStorageBase$path';
}

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
    const size = 76.0;
    final url = _resolveImageUrl(imagePath);

    return SizedBox(
      width: size + 14,
      height: size + 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Borde punteado del color del tipo
          CustomPaint(
            size: const Size(size + 14, size + 14),
            painter: _DashedCirclePainter(
              color: isGoat ? _gold : color,
              dashCount: 22,
              strokeWidth: 1.8,
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
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return _AvatarShimmer(color: color);
                      },
                      errorBuilder: (_, error, __) {
                        debugPrint('[PackOpening] image error: $error');
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
          // Halo GOAT doble anillo
          if (isGoat) ...[
            CustomPaint(
              size: const Size(size + 22, size + 22),
              painter: _DashedCirclePainter(
                color: _gold.withValues(alpha: 0.35),
                dashCount: 32,
                strokeWidth: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ESCUDO GA PENTAGONAL
// ════════════════════════════════════════════════════════════
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
            child: Text(
              'GA',
              style: TextStyle(
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
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.65)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.65)
      ..lineTo(0, h * 0.25)
      ..close();
    canvas.drawPath(path,
      Paint()..color = accentColor.withValues(alpha: 0.22)..style = PaintingStyle.fill);
    canvas.drawPath(path,
      Paint()
        ..color = accentColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.accentColor != accentColor;
}

// ════════════════════════════════════════════════════════════
//  PAINTERS Y HELPERS
// ════════════════════════════════════════════════════════════

// Dots grid fondo
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D2A40).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    const radius  = 1.3;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

// Stripes diagonales para cartas ocultas
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 13
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

// Barcode
class _BarcodePainter extends CustomPainter {
  final Color color;
  const _BarcodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    double x = 0;
    while (x < size.width) {
      final w = rng.nextDouble() * 3 + 1;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w, size.height),
        Paint()..color = color..style = PaintingStyle.fill,
      );
      x += w + rng.nextDouble() * 2 + 0.5;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => false;
}

// Borde punteado circular
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final dashAngle = (2 * math.pi) / dashCount;
    const gapFraction = 0.38;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle,
        dashAngle * (1 - gapFraction),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color || old.dashCount != dashCount;
}

// Bracket esquina
class _Bracket extends StatelessWidget {
  final bool flipH;
  final bool flipV;
  const _Bracket({this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1,
      scaleY: flipV ? -1 : 1,
      child: CustomPaint(
        size: const Size(11, 11),
        painter: _BracketPainter(
          color: Colors.white.withValues(alpha: 0.45),
          strokeWidth: 1.5,
        ),
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

// Shimmer avatar
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

// Fallback avatar sin imagen
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
      child: Icon(_typeIcon(cardType), size: 32, color: color.withValues(alpha: 0.5)),
    );
  }
}

// Dot de rareza en leyenda
class _RarityDot extends StatelessWidget {
  final Color color;
  final String label;
  const _RarityDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: _muted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
}

// Label de categoría en footer idle
class _CatLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _CatLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      );
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Text(
          '·',
          style: TextStyle(
            fontSize: 10,
            color: _muted.withValues(alpha: 0.6),
          ),
        ),
      );
}