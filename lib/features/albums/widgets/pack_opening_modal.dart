import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';
import '../data/albums_service.dart';

// ── Paleta
const _bg     = Color(0xFFF5F0E8);
const _card   = Color(0xFFEDE7DA);
const _border = Color(0xFF1A1A2E);
const _accent = Color(0xFF2D0CFF);
const _gold   = Color(0xFFFFD600);
const _shadow = Color(0x661A1A2E);
const _muted  = Color(0xFF555550);
const _text   = Color(0xFF1A1A2E);

Color _typeColor(String t) => switch (t) {
      'player'      => const Color(0xFF5B4FD8),
      'team'        => const Color(0xFF1D9E75),
      'competition' => const Color(0xFFF59E0B),
      'event'       => const Color(0xFFE55B5B),
      _             => _accent,
    };

String _typeLabel(String t) => switch (t) {
      'player'      => 'JUGADOR',
      'team'        => 'EQUIPO',
      'competition' => 'COPA',
      'event'       => 'EVENTO',
      _             => '?',
    };

// ════════════════════════════════════════════════════════════
//  ENTRY POINT
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
    ref.read(packOpenProvider.notifier).reset();
    ref.invalidate(albumsProvider);
  });
}

// ════════════════════════════════════════════════════════════
//  SHEET
// ════════════════════════════════════════════════════════════
class _PackOpeningSheet extends StatelessWidget {
  const _PackOpeningSheet();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border, width: 1.5)),
      ),
      child: const _PackOpeningFlow(),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MÁQUINA DE ESTADOS
//  idle → opening (llama API + muestra animación) → revealing → done
// ════════════════════════════════════════════════════════════
enum _Phase { idle, opening, revealing, done }

class _PackOpeningFlow extends ConsumerStatefulWidget {
  const _PackOpeningFlow();
  @override
  ConsumerState<_PackOpeningFlow> createState() => _PackOpeningFlowState();
}

class _PackOpeningFlowState extends ConsumerState<_PackOpeningFlow> {
  _Phase _phase = _Phase.idle;

  // Resultado guardado localmente — nunca depende del provider en el build
  PackOpenResult? _result;
  String? _errorMsg;

  // Cuántas cartas hemos revelado ya
  int _revealIndex = 0;

  // ── Inicia todo: lanza la API y pasa a fase opening
  Future<void> _startOpening() async {
    setState(() {
      _phase    = _Phase.opening;
      _result   = null;
      _errorMsg = null;
    });

    try {
      final userId = await ref.read(albumsUserIdProvider.future);
      final result = await AlbumsService().openPack(userId);
      // Resultado listo — lo guardamos localmente
      if (mounted) {
        setState(() {
          _result      = result;
          _revealIndex = 0;
          _phase       = _Phase.revealing;
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

  void _revealNext() {
    final total = _result?.allCards.length ?? 0;
    if (_revealIndex < total - 1) {
      setState(() => _revealIndex++);
    } else {
      setState(() => _phase = _Phase.done);
    }
  }

  // ── Header step label
  (String, String, String) get _headerData => switch (_phase) {
        _Phase.idle      => ('00', 'LISTO',      'Abre tu sobre'),
        _Phase.opening   => ('01', 'ABRIENDO',   'Obteniendo cartas...'),
        _Phase.revealing => ('02', 'REVELANDO',  'Descubriendo cartas'),
        _Phase.done      => ('03', 'COMPLETADO', 'Apertura finalizada'),
      };

  @override
  Widget build(BuildContext context) {
    final (step, label, sub) = _headerData;

    return Column(
      children: [
        // ── Header
        _Header(step: step, label: label, sub: sub),

        // ── Contenido por fase
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (_phase) {
              _Phase.idle      => _IdleView(
                  key: const ValueKey('idle'),
                  onOpen: _startOpening,
                  errorMsg: _errorMsg,
                ),
              _Phase.opening   => const _OpeningView(
                  key: ValueKey('opening'),
                ),
              _Phase.revealing => _RevealingView(
                  key: const ValueKey('revealing'),
                  result: _result!,
                  revealIndex: _revealIndex,
                  onNext: _revealNext,
                ),
              _Phase.done      => _DoneView(
                  key: const ValueKey('done'),
                  result: _result!,
                ),
            },
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  HEADER
// ════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String step, label, sub;
  const _Header({required this.step, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
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
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _accent,
              border: Border.all(color: _border, width: 1),
              boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1))],
            ),
            alignment: Alignment.center,
            child: Text(step,
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 0.5)),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900,
                      letterSpacing: 1.5, color: _text)),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 9, color: _muted)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 28, height: 28,
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

// ════════════════════════════════════════════════════════════
//  FASE idle
// ════════════════════════════════════════════════════════════
class _IdleView extends StatelessWidget {
  final VoidCallback onOpen;
  final String? errorMsg;
  const _IdleView({super.key, required this.onOpen, this.errorMsg});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _PackVisual(shaking: false),
        const SizedBox(height: 32),
        const Text('GLOBALALBUMS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                letterSpacing: 3, color: _muted)),
        const SizedBox(height: 8),
        const Text('1 sobre disponible',
            style: TextStyle(fontSize: 13, color: _text)),
        if (errorMsg != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Error: $errorMsg',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFFE55B5B))),
          ),
        ],
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
            child: Text(
              errorMsg != null ? 'REINTENTAR' : 'ABRIR SOBRE',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                  letterSpacing: 2, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FASE opening — animación mientras esperamos la API
// ════════════════════════════════════════════════════════════
class _OpeningView extends StatefulWidget {
  const _OpeningView({super.key});
  @override
  State<_OpeningView> createState() => _OpeningViewState();
}

class _OpeningViewState extends State<_OpeningView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
        // Sobre animado
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, -10 * _ctrl.value),
            child: const _PackVisual(shaking: true),
          ),
        ),
        const SizedBox(height: 40),
        const Text('Abriendo sobre...',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: _muted, letterSpacing: 1)),
        const SizedBox(height: 16),
        // Dots animados
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final delay = i / 3;
                final val   = (((_ctrl.value + delay) % 1.0));
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.3 + 0.7 * val),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  FASE revealing
// ════════════════════════════════════════════════════════════
class _RevealingView extends StatelessWidget {
  final PackOpenResult result;
  final int revealIndex;
  final VoidCallback onNext;
  const _RevealingView({
    super.key,
    required this.result,
    required this.revealIndex,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final cards = result.allCards;
    final total = cards.length;
    final isLast = revealIndex == total - 1;

    return Column(
      children: [
        const SizedBox(height: 16),
        // Progreso
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Carta ${revealIndex + 1} de $total',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: _muted, letterSpacing: 1)),
              const SizedBox(height: 6),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  border: Border.all(color: _border, width: 1),
                ),
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
        // Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
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
                  return _FlipCard(
                    key: ValueKey('card_$i'),
                    card: cards[i],
                    animate: i == revealIndex,
                  );
                }
                return _HiddenCard(index: i);
              },
            ),
          ),
        ),
        // Botón
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isLast ? _gold : _accent,
                border: Border.all(color: _border, width: 1.5),
                boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3))],
              ),
              alignment: Alignment.center,
              child: Text(
                isLast ? 'VER RESUMEN →' : 'SIGUIENTE CARTA →',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                    letterSpacing: 2, color: _border),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Carta oculta
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
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              border: Border.all(color: _border.withValues(alpha: 0.2), width: 1),
            ),
            child: const Icon(Icons.help_outline, color: _muted, size: 24),
          ),
          const SizedBox(height: 8),
          const Text('???', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
              color: _muted, letterSpacing: 2)),
        ],
      ),
    );
  }
}

// ── Carta con flip
class _FlipCard extends StatefulWidget {
  final AlbumCard card;
  final bool animate;
  const _FlipCard({super.key, required this.card, required this.animate});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _flip;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _flip = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 80), () {
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
        final angle  = _flip.value * 3.14159;
        final isFront = angle < 1.5708;
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
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _accent,
          border: Border.all(color: _border, width: 1.5),
          boxShadow: const [BoxShadow(color: _shadow, offset: Offset(2, 2))],
        ),
        child: const Center(
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 32)),
      );
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
        border: Border.all(color: isGoat ? _gold : color,
            width: isGoat ? 2.5 : 1.5),
        boxShadow: isGoat
            ? [BoxShadow(color: _gold.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)]
            : [const BoxShadow(color: _shadow, offset: Offset(2, 2))],
      ),
      child: Stack(
        children: [
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
          // Imagen o placeholder
          Positioned(
            top: 0, left: 0, right: 0, bottom: 52,
            child: card.imagePath != null
                ? Image.network(card.imagePath!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Placeholder(type: card.cardType))
                : _Placeholder(type: card.cardType),
          ),
          // Stars
          Positioned(
            top: 6, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              color: _border.withValues(alpha: 0.8),
              child: Text('${stars}★',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                      color: stars >= 4 ? _gold : Colors.white)),
            ),
          ),
          // Badge GOAT
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
                  Text(card.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: Colors.white, height: 1.2)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    color: color,
                    child: Text(_typeLabel(card.cardType),
                        style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900,
                            color: Colors.white)),
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

class _Placeholder extends StatelessWidget {
  final String type;
  const _Placeholder({required this.type});
  @override
  Widget build(BuildContext context) => Container(
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

// ════════════════════════════════════════════════════════════
//  FASE done
// ════════════════════════════════════════════════════════════
class _DoneView extends StatefulWidget {
  final PackOpenResult result;
  const _DoneView({super.key, required this.result});
  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
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
    final cards   = widget.result.allCards;
    final hasGoat = widget.result.hasGoat;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: hasGoat ? _gold : const Color(0xFF00C48C),
                  border: Border.all(color: _border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (hasGoat ? _gold : const Color(0xFF00C48C))
                          .withValues(alpha: 0.5),
                      blurRadius: hasGoat ? 20 : 8,
                      spreadRadius: hasGoat ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(hasGoat ? Icons.star : Icons.check,
                    size: 36, color: hasGoat ? _border : Colors.white),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                      letterSpacing: 1.5, color: hasGoat ? _gold : _text),
                ),
                const SizedBox(height: 4),
                Text('${cards.length} / 4 cartas obtenidas',
                    style: const TextStyle(fontSize: 11, color: _muted)),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _accent,
                  border: Border.all(color: _border, width: 1.5),
                  boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3))],
                ),
                alignment: Alignment.center,
                child: const Text('VER MI COLECCIÓN →',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                        letterSpacing: 2, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  PACK VISUAL
// ════════════════════════════════════════════════════════════
class _PackVisual extends StatelessWidget {
  final bool shaking;
  const _PackVisual({required this.shaking});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 130, height: 170,
          margin: const EdgeInsets.only(top: 6, left: 6),
          color: _shadow,
        ),
        Container(
          width: 130, height: 170,
          decoration: BoxDecoration(
            color: _accent,
            border: Border.all(color: _border, width: 2),
          ),
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(130, 50),
                painter: _FlapPainter(open: shaking),
              ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 10),
                    const Text('GLOBAL ALBUMS',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    const Text('1 SOBRE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                            color: Colors.white60, letterSpacing: 1)),
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
      path..moveTo(0, 0)..lineTo(size.width, 0)
          ..lineTo(size.width, 8)..lineTo(size.width / 2, 44)
          ..lineTo(0, 8)..close();
    } else {
      path..moveTo(0, 0)..lineTo(size.width, 0)
          ..lineTo(size.width, 5)..lineTo(size.width / 2, 40)
          ..lineTo(0, 5)..close();
    }
    canvas.drawPath(path, paint);
    canvas.drawLine(
      const Offset(0, 40), Offset(size.width, 40),
      Paint()..color = Colors.white.withValues(alpha: 0.2)..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_FlapPainter old) => old.open != open;
}