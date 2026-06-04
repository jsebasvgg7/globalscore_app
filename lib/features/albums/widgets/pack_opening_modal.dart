// lib/features/albums/presentation/pack_opening_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';

// ── Paleta neobrut
const _bg     = Color(0xFFF5F0E8);
const _card   = Color(0xFFEDE7DA);
const _border = Color(0xFF1A1A2E);
const _accent = Color(0xFF2D0CFF);
const _gold   = Color(0xFFFFD600);
const _shadow = Color(0x661A1A2E);
const _muted  = Color(0xFF555550);
const _text   = Color(0xFF1A1A2E);

Color _typeColor(String type) => switch (type) {
      'player'      => const Color(0xFF5B4FD8),
      'team'        => const Color(0xFF1D9E75),
      'competition' => const Color(0xFFF59E0B),
      'event'       => const Color(0xFFE55B5B),
      _             => _accent,
    };

String _typeLabel(String type) => switch (type) {
      'player'      => 'JUGADOR',
      'team'        => 'EQUIPO',
      'competition' => 'COPA',
      'event'       => 'EVENTO',
      _             => '?',
    };

// ════════════════════════════════════════════════════════════
//  ENTRY POINT: muestra el modal
// ════════════════════════════════════════════════════════════
void showPackOpeningModal(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: const _PackOpeningSheet(),
    ),
  ).then((_) {
    // Al cerrar el modal (cualquier vía), resetea estado y refresca la page
    ref.read(packOpenProvider.notifier).reset();
    ref.invalidate(albumsProvider);
  });
}

// ════════════════════════════════════════════════════════════
//  SHEET WRAPPER
// ════════════════════════════════════════════════════════════
class _PackOpeningSheet extends ConsumerWidget {
  const _PackOpeningSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border, width: 1.5)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      child: const _PackOpeningFlow(),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FASES: 0=idle  1=iniciando  2=revelando  3=finalizado
// ════════════════════════════════════════════════════════════
class _PackOpeningFlow extends ConsumerStatefulWidget {
  const _PackOpeningFlow();

  @override
  ConsumerState<_PackOpeningFlow> createState() => _PackOpeningFlowState();
}

class _PackOpeningFlowState extends ConsumerState<_PackOpeningFlow> {
  int _phase       = 0;  // 0 idle → 1 iniciando → 2 revelando → 3 fin
  int _revealIndex = 0;  // qué carta se está revelando ahora

  @override
  Widget build(BuildContext context) {
    final packState = ref.watch(packOpenProvider);

    return Column(
      children: [
        _ModalHeader(phase: _phase),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: switch (_phase) {
              0 => _IdleView(onOpen: _startOpening),
              1 => _InitiatingView(
                  onReady: () => setState(() => _phase = 2),
                ),
              2 => _RevealingView(
                  result: packState.result!,
                  revealIndex: _revealIndex,
                  onRevealNext: _revealNext,
                ),
              _ => _FinishedView(result: packState.result!),
            },
          ),
        ),
      ],
    );
  }

  void _startOpening() {
    setState(() => _phase = 1);
    ref.read(packOpenProvider.notifier).open();
  }

  void _revealNext() {
    final cards = ref.read(packOpenProvider).result?.allCards ?? [];
    if (_revealIndex < cards.length - 1) {
      setState(() => _revealIndex++);
    } else {
      setState(() => _phase = 3);
    }
  }
}

// ══ HEADER ═══════════════════════════════════════════════
class _ModalHeader extends StatelessWidget {
  final int phase;
  const _ModalHeader({required this.phase});

  @override
  Widget build(BuildContext context) {
    final (step, label, sub) = switch (phase) {
      0 => ('00', 'LISTO', 'Abre tu sobre'),
      1 => ('01', 'INICIANDO', 'Apertura de sobre'),
      2 => ('02', 'REVELANDO', 'Descubriendo cartas'),
      _ => ('03', 'FINALIZANDO', 'Completando apertura'),
    };

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _accent,
              border: Border.all(color: _border, width: 1),
              boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1))],
            ),
            alignment: Alignment.center,
            child: Text(step,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _text)),
              Text(sub,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: _muted)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _bg,
                border: Border.all(color: _border, width: 1),
              ),
              child: const Icon(Icons.close, size: 14, color: _text),
            ),
          ),
        ],
      ),
    );
  }
}

// ══ FASE 0: IDLE ═════════════════════════════════════════
class _IdleView extends StatelessWidget {
  final VoidCallback onOpen;
  const _IdleView({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AnimatedPackIcon(tapping: false),
        const SizedBox(height: 32),
        const Text('GLOBALALBUMS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3, color: _muted)),
        const SizedBox(height: 8),
        const Text('1 sobre disponible',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _text)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: _accent,
              border: Border.all(color: _border, width: 1.5),
              boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3))],
            ),
            child: const Text(
              'ABRIR SOBRE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ══ FASE 1: INICIANDO ════════════════════════════════════
class _InitiatingView extends ConsumerStatefulWidget {
  final VoidCallback onReady; // callback cuando animación + resultado listos
  const _InitiatingView({required this.onReady});

  @override
  ConsumerState<_InitiatingView> createState() => _InitiatingViewState();
}

class _InitiatingViewState extends ConsumerState<_InitiatingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;
  bool _animDone   = false;
  bool _resultDone = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animDone = true;
        _tryAdvance();
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tryAdvance() {
    if (_animDone && _resultDone && mounted) widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el resultado del provider
    ref.listen(packOpenProvider, (_, next) {
      if (next.status == PackOpenStatus.success ||
          next.status == PackOpenStatus.error) {
        _resultDone = true;
        _tryAdvance();
      }
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AnimatedPackIcon(tapping: true),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              const Text('Preparando contenido...',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 1)),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => Column(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(border: Border.all(color: _border, width: 1)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progress.value,
                        child: Container(color: _accent),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(_progress.value * 100).round()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══ FASE 2: REVELANDO ════════════════════════════════════
class _RevealingView extends StatelessWidget {
  final PackOpenResult result;
  final int revealIndex;
  final VoidCallback onRevealNext;
  const _RevealingView({
    required this.result,
    required this.revealIndex,
    required this.onRevealNext,
  });

  @override
  Widget build(BuildContext context) {
    final cards = result.allCards;
    final total = cards.length;

    return Column(
      children: [
        const SizedBox(height: 16),
        // Progreso numérico
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                'Revelando carta ${revealIndex + 1} de $total...',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                decoration: BoxDecoration(border: Border.all(color: _border, width: 1)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (revealIndex + 1) / total,
                  child: Container(color: _accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Grid de cartas — las reveladas se muestran, resto gris
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemCount: total,
              itemBuilder: (_, i) {
                if (i <= revealIndex) {
                  return _FlipCard(card: cards[i], animate: i == revealIndex);
                }
                return _HiddenCard(index: i);
              },
            ),
          ),
        ),
        // Botón siguiente / finalizar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: GestureDetector(
            onTap: onRevealNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: revealIndex == total - 1 ? _gold : _accent,
                border: Border.all(color: _border, width: 1.5),
                boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3))],
              ),
              alignment: Alignment.center,
              child: Text(
                revealIndex == total - 1 ? 'VER RESUMEN →' : 'SIGUIENTE CARTA →',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: _border,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Carta oculta (antes de revelar)
class _HiddenCard extends StatelessWidget {
  final int index;
  const _HiddenCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border, width: 1),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(2, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              border: Border.all(color: _border.withValues(alpha: 0.2), width: 1),
            ),
            child: const Icon(Icons.help_outline, color: _muted, size: 24),
          ),
          const SizedBox(height: 8),
          const Text('???',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 2)),
        ],
      ),
    );
  }
}

// ── Carta con flip animation
class _FlipCard extends StatefulWidget {
  final AlbumCard card;
  final bool animate;
  const _FlipCard({required this.card, required this.animate});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1;
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
        final angle = _flip.value * 3.14159;
        final isFront = angle < 1.5708; // π/2

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isFront
              ? _CardBack()
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159),
                  child: _CardFront(card: widget.card),
                ),
        );
      },
    );
  }
}

class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _accent,
        border: Border.all(color: _border, width: 1.5),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(2, 2))],
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: Colors.white, size: 32),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final AlbumCard card;
  const _CardFront({required this.card});

  @override
  Widget build(BuildContext context) {
    final color  = _typeColor(card.cardType);
    final stars  = card.significanceLevel ?? 1;
    final isGoat = card.isGoat;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(
          color: isGoat ? _gold : color,
          width: isGoat ? 2.5 : 1.5,
        ),
        boxShadow: isGoat
            ? [BoxShadow(color: _gold.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)]
            : [const BoxShadow(color: _shadow, offset: Offset(2, 2))],
      ),
      child: Stack(
        children: [
          // Fondo gradiente suave del tipo
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),

          // Imagen
          if (card.imagePath != null)
            Positioned(
              top: 0, left: 0, right: 0,
              bottom: 52,
              child: Image.network(
                card.imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderImage(type: card.cardType),
              ),
            )
          else
            Positioned(
              top: 0, left: 0, right: 0, bottom: 52,
              child: _PlaceholderImage(type: card.cardType),
            ),

          // Stars top-left
          Positioned(
            top: 6, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              color: _border.withValues(alpha: 0.8),
              child: Text(
                '${stars}★',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: stars >= 4 ? _gold : Colors.white,
                ),
              ),
            ),
          ),

          // GOAT badge
          if (isGoat)
            Positioned(
              top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                color: _gold,
                child: const Text('GOAT',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: _border)),
              ),
            ),

          // Info bottom
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
              color: _border.withValues(alpha: 0.88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    color: color,
                    child: Text(
                      _typeLabel(card.cardType),
                      style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white),
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

class _PlaceholderImage extends StatelessWidget {
  final String type;
  const _PlaceholderImage({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _typeColor(type).withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Icon(
        switch (type) {
          'player'      => Icons.person,
          'team'        => Icons.shield,
          'competition' => Icons.emoji_events,
          _             => Icons.history_edu,
        },
        color: _typeColor(type).withValues(alpha: 0.4),
        size: 40,
      ),
    );
  }
}

// ══ FASE 3: FINALIZADO ═══════════════════════════════════
class _FinishedView extends StatefulWidget {
  final PackOpenResult result;
  const _FinishedView({required this.result});

  @override
  State<_FinishedView> createState() => _FinishedViewState();
}

class _FinishedViewState extends State<_FinishedView> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
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
    final hasGoat = widget.result.hasGoat;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Check animado
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: hasGoat ? _gold : const Color(0xFF00C48C),
                  border: Border.all(color: _border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (hasGoat ? _gold : const Color(0xFF00C48C)).withValues(alpha: 0.5),
                      blurRadius: hasGoat ? 20 : 8,
                      spreadRadius: hasGoat ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  hasGoat ? Icons.star : Icons.check,
                  size: 36,
                  color: hasGoat ? _border : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                Text(
                  hasGoat ? '¡CARTA GOAT OBTENIDA!' : '¡APERTURA COMPLETADA!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: hasGoat ? _gold : _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cards.length} / 4 cartas obtenidas',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Mini grid de las 4 cartas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              itemCount: cards.length,
              itemBuilder: (_, i) => _CardFront(card: cards[i]),
            ),
          ),
          const SizedBox(height: 20),
          // Botones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(), // .then() en showPackOpeningModal hace el resto
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _accent,
                      border: Border.all(color: _border, width: 1.5),
                      boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3))],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'VER MI COLECCIÓN →',
                      style: TextStyle(
                        fontSize: 12,
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ══ PACK ICON ANIMADO ════════════════════════════════════
class _AnimatedPackIcon extends StatefulWidget {
  final bool tapping;
  const _AnimatedPackIcon({required this.tapping});

  @override
  State<_AnimatedPackIcon> createState() => _AnimatedPackIconState();
}

class _AnimatedPackIconState extends State<_AnimatedPackIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounce = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, __) {
        final dy = widget.tapping ? -12 * _bounce.value : -6 * _bounce.value;
        return Transform.translate(
          offset: Offset(0, dy),
          child: _PackVisual(shaking: widget.tapping),
        );
      },
    );
  }
}

class _PackVisual extends StatelessWidget {
  final bool shaking;
  const _PackVisual({required this.shaking});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Sombra
        Container(
          width: 130,
          height: 170,
          margin: const EdgeInsets.only(top: 6, left: 6),
          color: _shadow,
        ),
        // Sobre principal
        Container(
          width: 130,
          height: 170,
          decoration: BoxDecoration(
            color: _accent,
            border: Border.all(color: _border, width: 2),
          ),
          child: Stack(
            children: [
              // Flap superior (triángulo)
              CustomPaint(
                size: const Size(130, 50),
                painter: _FlapPainter(open: shaking),
              ),
              // Logo centrado
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 10),
                    const Text('GLOBAL ALBUMS',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    const Text('1 SOBRE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlapPainter extends CustomPainter {
  final bool open;
  const _FlapPainter({required this.open});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A0CA8)
      ..style = PaintingStyle.fill;

    final path = Path();
    if (open) {
      // Flap abierto — diagonal hacia arriba
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, 8);
      path.lineTo(size.width / 2, 44);
      path.lineTo(0, 8);
      path.close();
    } else {
      // Flap cerrado — triángulo normal
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, 5);
      path.lineTo(size.width / 2, 40);
      path.lineTo(0, 5);
      path.close();
    }
    canvas.drawPath(path, paint);

    // Línea de sellado
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(0, 40),
      Offset(size.width, 40),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_FlapPainter old) => old.open != open;
}