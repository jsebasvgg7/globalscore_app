import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/albums_model.dart';
import '../domain/albums_provider.dart';
import '../data/albums_service.dart';

// ════════════════════════════════════════════════════════════
//  PACK OPENING PAGE
//  Página completa en lugar del modal anterior.
//  VENTAJAS vs modal:
//  • Ciclo de vida propio — no hereda el contexto de AlbumsPage.
//  • No hay ref.invalidate() cruzado entre páginas.
//  • El Realtime de AlbumsPage está suspendido mientras esta
//    página está activa (StatefulShellRoute la mantiene viva
//    pero no visible).
//  • Un solo lugar donde se llama openPack — nunca duplicado.
//  • Al hacer pop() la AlbumsPage se refresca con refresh()
//    una sola vez y ya.
// ════════════════════════════════════════════════════════════

// ── Colores internos (idénticos al modal anterior) ──────────
const _bg         = Color(0xFFF5F2EC);
const _bgDark     = Color(0xFF12101F);
const _border     = Color(0xFF2D2A40);
const _accent     = Color(0xFF5B4FD8);
const _gold       = Color(0xFFFFD600);
const _shadow     = Color(0xFF302D41);
const _muted      = Color(0xFF9B9590);
const _text       = Color(0xFF1C1A2E);
const _supabaseStorageBase =
    'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/';

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

String? _resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '$_supabaseStorageBase$path';
}

// ════════════════════════════════════════════════════════════
//  PHASES
// ════════════════════════════════════════════════════════════
enum _Phase { opening, revealing, done, error }

// ════════════════════════════════════════════════════════════
//  PAGE
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

  // ── Guard: asegura que openPack se llame UNA sola vez ──────
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

      // Actualizar el contador en el provider SIN hacer fetch completo
      // (la misma lógica que updatePacksFromRpc en el provider anterior)
      // El servicio retorna el PackOpenResult pero no el rpcResult directamente;
      // lo actualizamos con refresh() al salir — así es UN solo fetch al volver.

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
          _opened   = false; // permite retry
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
    for (int i = 0; i < total; i++) {
      _revealed.add(i);
    }
    setState(() => _phase = _Phase.done);
  }

  /// Vuelve a AlbumsPage y hace refresh UNA sola vez.
  void _goBack() {
    // Refresh limpio del provider al volver — UN solo fetch.
    ref.read(albumsProvider.notifier).refresh();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _GaHeader(onClose: _goBack),
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
          result:   _result!,
          revealed: _revealed,
          onReveal: _revealCard,
          onRevealAll: _revealAll,
        ),
      _Phase.done      => _DoneView(
          result:  _result!,
          onBack:  _goBack,
        ),
      _Phase.error     => _ErrorView(
          msg:     _errorMsg ?? 'Error desconocido',
          onRetry: () {
            _opened = false;
            _startOpening();
          },
          onBack:  _goBack,
        ),
    };
  }
}

// ════════════════════════════════════════════════════════════
//  HEADER
// ════════════════════════════════════════════════════════════
class _GaHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _GaHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: _bgDark,
        border: Border(bottom: BorderSide(color: _border, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Logo GA
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: _accent,
              border: Border.all(color: _border, width: 1.5),
            ),
            child: const Center(
              child: Text('GA',
                style: TextStyle(
                  fontFamily: 'DM Mono', fontSize: 9,
                  fontWeight: FontWeight.w900, color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('GLOBAL ALBUMS',
                  style: TextStyle(
                    fontFamily: 'DM Mono', fontSize: 7.5,
                    fontWeight: FontWeight.w700, color: _muted,
                    letterSpacing: 1.5,
                  ),
                ),
                Text('APERTURA DE SOBRE',
                  style: TextStyle(
                    fontFamily: 'DM Mono', fontSize: 12,
                    fontWeight: FontWeight.w900, color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Botón X
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                border: Border.all(color: _border, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.close, size: 14, color: _muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  OPENING VIEW — animación del sobre
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
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
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
          animation: _pulse,
          builder: (_, __) => Transform.scale(
            scale: 0.95 + 0.05 * _pulse.value,
            child: const _PackIllustration(),
          ),
        ),
        const SizedBox(height: 32),
        // Indicador de carga
        SizedBox(
          width: 160,
          child: Column(
            children: [
              const Text(
                'ABRIENDO SOBRE...',
                style: TextStyle(
                  fontFamily: 'DM Mono', fontSize: 9,
                  fontWeight: FontWeight.w900, color: _muted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              ClipRect(
                child: SizedBox(
                  height: 2,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => LinearProgressIndicator(
                      value: null,
                      backgroundColor: _border.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(_accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Tipos de cartas
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TypeChip(label: 'JUGADOR', color: _accent),
            _Dot(),
            _TypeChip(label: 'EQUIPO', color: Color(0xFF1DAA75)),
            _Dot(),
            _TypeChip(label: 'COPA', color: Color(0xFFF59E0B)),
            _Dot(),
            _TypeChip(label: 'EVENTO', color: Color(0xFFE0435A)),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label,
      style: TextStyle(
        fontFamily: 'DM Mono', fontSize: 7.5,
        fontWeight: FontWeight.w700, color: color,
        letterSpacing: 1,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Text('•', style: TextStyle(color: _muted, fontSize: 8)),
    );
  }
}

// ── Ilustración del sobre ────────────────────────────────────
class _PackIllustration extends StatelessWidget {
  const _PackIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sombra trasera (segundo sobre)
          Positioned(
            top: 10, left: 6,
            child: _PackBody(
              color: _border.withValues(alpha: 0.35),
              accentColor: _accent.withValues(alpha: 0.2),
            ),
          ),
          // Sobre principal
          const _PackBody(color: _bgDark, accentColor: _accent),
          // Texto encima
          Positioned(
            bottom: 46,
            child: Column(
              children: [
                const Text('GLOBAL ALBUMS',
                  style: TextStyle(
                    fontFamily: 'DM Mono', fontSize: 9,
                    fontWeight: FontWeight.w900, color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: _accent.withValues(alpha: 0.5), width: 1),
                  ),
                  child: const Text('GS-25/26',
                    style: TextStyle(
                      fontFamily: 'DM Mono', fontSize: 7,
                      color: _muted, letterSpacing: 1.5,
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

class _PackBody extends StatelessWidget {
  final Color color;
  final Color accentColor;
  const _PackBody({required this.color, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, height: 220,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _border, width: 2),
        boxShadow: [BoxShadow(color: _shadow, offset: const Offset(5, 5))],
      ),
      child: Stack(
        children: [
          // Grid de puntos
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          // Rayas diagonales
          Positioned.fill(child: CustomPaint(painter: _StripePainter())),
          // Escudo GA centrado
          Center(
            child: _GaShield(scale: 1.0, accentColor: accentColor),
          ),
          // Brackets de esquina
          const Positioned(top: 8, left: 8, child: _Bracket()),
          const Positioned(top: 8, right: 8, child: _Bracket(flipH: true)),
          const Positioned(bottom: 8, left: 8, child: _Bracket(flipV: true)),
          const Positioned(bottom: 8, right: 8, child: _Bracket(flipH: true, flipV: true)),
          // Código de barras decorativo
          Positioned(
            top: 18,
            child: SizedBox(
              width: 160,
              child: Center(
                child: SizedBox(
                  width: 70, height: 10,
                  child: CustomPaint(painter: _BarcodePainter()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  REVEALING VIEW — grid de cartas para revelar
// ════════════════════════════════════════════════════════════
class _RevealingView extends StatelessWidget {
  final PackOpenResult result;
  final Set<int> revealed;
  final void Function(int) onReveal;
  final VoidCallback onRevealAll;

  const _RevealingView({
    required this.result,
    required this.revealed,
    required this.onReveal,
    required this.onRevealAll,
  });

  @override
  Widget build(BuildContext context) {
    final cards = result.allCards;
    final total = cards.length;
    final revealedCount = revealed.length;
    final allRevealed = revealedCount >= total;

    return Column(
      children: [
        // Header de sección
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              const Text('TUS CARTAS',
                style: TextStyle(
                  fontFamily: 'DM Mono', fontSize: 12,
                  fontWeight: FontWeight.w900, color: _text,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              // Indicadores de cartas
              Row(
                children: List.generate(total, (i) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: revealed.contains(i) ? _accent : Colors.transparent,
                      border: Border.all(color: _border, width: 1.5),
                    ),
                  ),
                )),
              ),
            ],
          ),
        ),
        // Grid 2x2
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(total, (i) => _FlipCard(
                card: cards[i],
                isRevealed: revealed.contains(i),
                onTap: () => onReveal(i),
              )),
            ),
          ),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border, width: 1)),
          ),
          child: GestureDetector(
            onTap: allRevealed ? null : onRevealAll,
            child: Text(
              allRevealed
                  ? '¡TOCA VER RESULTADO!'
                  : 'TOCA CADA CARTA PARA REVELARLA  •  $revealedCount/$total',
              style: TextStyle(
                fontFamily: 'DM Mono', fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: allRevealed ? _accent : _muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Carta con flip 3D ────────────────────────────────────────
class _FlipCard extends StatefulWidget {
  final AlbumCard card;
  final bool isRevealed;
  final VoidCallback onTap;

  const _FlipCard({
    required this.card,
    required this.isRevealed,
    required this.onTap,
  });

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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.isRevealed && !old.isRevealed) {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRevealed ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final angle = _anim.value * math.pi;
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

// ── Reverso de carta ─────────────────────────────────────────
class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgDark,
        border: Border.all(color: _border, width: 2),
        boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3))],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StripePainter())),
          Center(child: _GaShield(scale: 0.85, accentColor: _accent)),
        ],
      ),
    );
  }
}

// ── Frente de carta ──────────────────────────────────────────
class _CardFront extends StatelessWidget {
  final AlbumCard card;
  const _CardFront({required this.card});

  @override
  Widget build(BuildContext context) {
    final color  = _typeColor(card.cardType);
    final label  = _typeLabel(card.cardType);
    final isGoat = card.isGoat;
    final stars  = card.significanceLevel ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isGoat ? _gold : color,
          width: isGoat ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isGoat
                ? _gold.withValues(alpha: 0.4)
                : color.withValues(alpha: 0.25),
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: número + tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                Text(
                  card.cardType == 'player' ? '001' :
                  card.cardType == 'team' ? '002' :
                  card.cardType == 'competition' ? '003' : '004',
                  style: TextStyle(
                    fontFamily: 'DM Mono', fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: color.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(label,
                    style: TextStyle(
                      fontFamily: 'DM Mono', fontSize: 6,
                      fontWeight: FontWeight.w900, color: color,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Avatar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _CircularAvatar(
                imagePath: card.imagePath,
                name: card.name,
                color: color,
                isGoat: isGoat,
                cardType: card.cardType,
              ),
            ),
          ),
          // Estrellas (solo jugadores)
          if (card.cardType == 'player') ...[
            const SizedBox(height: 4),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  Icons.star,
                  size: 10,
                  color: i < stars
                      ? (isGoat ? _gold : color)
                      : _muted.withValues(alpha: 0.3),
                )),
              ),
            ),
          ],
          // Nombre
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Text(card.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'DM Mono', fontSize: 8,
                fontWeight: FontWeight.w900, color: _text,
                letterSpacing: 0.3,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  DONE VIEW — resultado final
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

    // Stats de rareza
    final stars4 = cards.where((c) => (c.significanceLevel ?? 0) >= 4).length;
    final stars3 = cards.where((c) => c.significanceLevel == 3).length;

    return Column(
      children: [
        // Subtítulo
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Text('TUS CARTAS',
                style: TextStyle(
                  fontFamily: 'DM Mono', fontSize: 12,
                  fontWeight: FontWeight.w900, color: _text,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        // Grid de cartas reveladas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cards.map((c) => _CardFront(card: c)).toList(),
            ),
          ),
        ),
        // Resumen de rareza
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text('$total CARTAS', style: const TextStyle(
                fontFamily: 'DM Mono', fontSize: 8,
                fontWeight: FontWeight.w900, color: _muted,
                letterSpacing: 1,
              )),
              if (stars4 > 0) ...[
                const Text('  •  ', style: TextStyle(color: _muted, fontSize: 8)),
                Text('$stars4 ÉPICA${stars4 > 1 ? 'S' : ''}',
                  style: const TextStyle(
                    fontFamily: 'DM Mono', fontSize: 8,
                    fontWeight: FontWeight.w900, color: Color(0xFFF59E0B),
                    letterSpacing: 0.8,
                  )),
              ],
              if (goat) ...[
                const Text('  •  ', style: TextStyle(color: _muted, fontSize: 8)),
                const Text('1 GOAT', style: TextStyle(
                  fontFamily: 'DM Mono', fontSize: 8,
                  fontWeight: FontWeight.w900, color: _gold,
                  letterSpacing: 0.8,
                )),
              ],
            ],
          ),
        ),
        // Botón VER MI COLECCIÓN
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: _BigButton(
            label: 'VER MI COLECCIÓN',
            onTap: onBack,
          ),
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

  const _ErrorView({
    required this.msg,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isNoTickets = msg.contains('No tienes');
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: _border, width: 2),
            ),
            child: Icon(
              isNoTickets ? Icons.confirmation_num_outlined : Icons.error_outline,
              size: 28,
              color: isNoTickets ? _muted : Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isNoTickets ? 'SIN SOBRES' : 'ERROR',
            style: const TextStyle(
              fontFamily: 'DM Mono', fontSize: 14,
              fontWeight: FontWeight.w900, color: _text,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Mono', fontSize: 9,
              color: _muted, letterSpacing: 0.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          if (!isNoTickets)
            _BigButton(label: 'REINTENTAR', onTap: onRetry),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onBack,
            child: const Text('VOLVER',
              style: TextStyle(
                fontFamily: 'DM Mono', fontSize: 9,
                fontWeight: FontWeight.w700, color: _muted,
                letterSpacing: 1.5,
                decoration: TextDecoration.underline,
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
class _BigButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _BigButton({required this.label, required this.onTap});

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: _pressed
            ? (Matrix4.identity()..translate(3.0, 3.0))
            : Matrix4.identity(),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _accent,
          boxShadow: _pressed
              ? null
              : const [BoxShadow(color: _shadow, offset: Offset(4, 4))],
        ),
        child: Center(
          child: Text(widget.label,
            style: const TextStyle(
              fontFamily: 'DM Mono', fontSize: 11,
              fontWeight: FontWeight.w900, color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Avatares y painters ──────────────────────────────────────
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
    const size = 72.0;
    final url = _resolveImageUrl(imagePath);
    return SizedBox(
      width: size + 14, height: size + 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size + 14, size + 14),
            painter: _DashedCirclePainter(
              color: isGoat ? _gold : color,
              dashCount: 22, strokeWidth: 1.8,
            ),
          ),
          ClipOval(
            child: Container(
              width: size, height: size,
              color: color.withValues(alpha: 0.08),
              child: url != null
                  ? Image.network(url, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AvatarFallback(name: name, cardType: cardType, color: color))
                  : _AvatarFallback(name: name, cardType: cardType, color: color),
            ),
          ),
        ],
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
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
          color: color.withValues(alpha: 0.7))));
    }
    return Center(child: Icon(_typeIcon(cardType), size: 28, color: color.withValues(alpha: 0.5)));
  }
}

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
                fontSize: 17 * scale, fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: 1,
              )),
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
  bool shouldRepaint(_ShieldPainter old) => old.accentColor != accentColor;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D2A40).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    const spacing = 20.0; const radius = 1.2;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override bool shouldRepaint(_DotGridPainter old) => false;
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width + size.height; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override bool shouldRepaint(_StripePainter old) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;
  const _DashedCirclePainter({required this.color, required this.dashCount, this.strokeWidth = 1.8});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    final dashAngle = (2 * math.pi) / dashCount;
    const gapFraction = 0.38;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          i * dashAngle, dashAngle * (1 - gapFraction), false, paint);
    }
  }

  @override bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.25)..style = PaintingStyle.fill;
    final rng = math.Random(42);
    double x = 0;
    while (x < size.width) {
      final w = rng.nextDouble() * 3 + 1;
      if (rng.nextBool()) canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w + rng.nextDouble() * 2;
    }
  }

  @override bool shouldRepaint(_BarcodePainter old) => false;
}

class _Bracket extends StatelessWidget {
  final bool flipH;
  final bool flipV;
  const _Bracket({this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1, scaleY: flipV ? -1 : 1,
      child: CustomPaint(
        size: const Size(11, 11),
        painter: _BracketPainter(
          color: Colors.white.withValues(alpha: 0.45), strokeWidth: 1.5,
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
    final paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override bool shouldRepaint(_BracketPainter old) => false;
}