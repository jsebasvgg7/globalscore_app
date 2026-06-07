import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../presentation/albums_page.dart' show Ds;

// ════════════════════════════════════════════════════════════
//  TICKET COUNTER CHIP
//  Widget compacto para el header de AlbumsPage.
//  Muestra el total de tickets y el botón ABRIR.
//  Si tickets == 0 el botón queda visible pero deshabilitado.
// ════════════════════════════════════════════════════════════
class TicketCounter extends StatelessWidget {
  final int tickets;
  final VoidCallback onOpen;

  const TicketCounter({
    super.key,
    required this.tickets,
    required this.onOpen,
  });

  bool get _canOpen => tickets > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Ds.bg,
        border: Border.all(color: Ds.border, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFB0AAA0), offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          // ── Banda morada izquierda ──────────────────────
          Container(width: 5, color: Ds.accent),

          // ── Ícono ticket + contador ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TicketIcon(hasTickets: _canOpen),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SOBRES',
                      style: TextStyle(
                        fontFamily: Ds.font,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Ds.muted,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$tickets',
                          style: TextStyle(
                            fontFamily: Ds.font,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            color: _canOpen ? Ds.accent : Ds.muted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _canOpen ? 'DISPONIBLES' : 'SIN TICKETS',
                          style: TextStyle(
                            fontFamily: Ds.font,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: _canOpen ? Ds.accent : Ds.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Separador vertical ──────────────────────────
          Container(width: 1.5, height: 56, color: Ds.borderSub),

          // ── Botón ABRIR ─────────────────────────────────
          _OpenTicketButton(
            enabled: _canOpen,
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

// ─── Ícono de ticket con animación de pulso si hay disponibles ──
class _TicketIcon extends StatefulWidget {
  final bool hasTickets;
  const _TicketIcon({required this.hasTickets});

  @override
  State<_TicketIcon> createState() => _TicketIconState();
}

class _TicketIconState extends State<_TicketIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.hasTickets) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TicketIcon old) {
    super.didUpdateWidget(old);
    if (widget.hasTickets && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.hasTickets && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0.85;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasTickets) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Ds.bgCard,
          border: Border.all(color: Ds.borderSub, width: 1.5),
        ),
        child: const Center(
          child: Icon(Icons.confirmation_num_outlined, size: 20, color: Ds.muted),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: _pulse.value,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Ds.accent,
            border: Border.all(color: Ds.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Ds.accent.withValues(alpha: 0.35 * _pulse.value),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.confirmation_num, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ─── Botón ABRIR con efecto press 3D ────────────────────────
class _OpenTicketButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _OpenTicketButton({required this.enabled, required this.onTap});

  @override
  State<_OpenTicketButton> createState() => _OpenTicketButtonState();
}

class _OpenTicketButtonState extends State<_OpenTicketButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? Ds.accent : Ds.muted;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: (_pressed && widget.enabled)
            ? (Matrix4.identity()..translate(3.0, 3.0))
            : Matrix4.identity(),
        width: 90,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          boxShadow: (_pressed || !widget.enabled)
              ? null
              : const [
                  BoxShadow(
                    color: Color(0xFF302D41),
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: Colors.white.withValues(alpha: widget.enabled ? 1 : 0.6),
            ),
            const SizedBox(height: 3),
            Text(
              'ABRIR',
              style: TextStyle(
                fontFamily: Ds.font,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                color: Colors.white.withValues(alpha: widget.enabled ? 1 : 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
