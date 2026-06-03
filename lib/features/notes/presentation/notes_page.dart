import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notes_providers.dart';
import '../data/notes_service.dart';

// ── Paleta (misma que stats) ──────────────────────────────────────────
const _accent  = Color(0xFF2D0CFF);
const _accentL = Color(0xFF7B61FF);
const _exact   = Color(0xFFFF3C00);
const _correct = Color(0xFF00C48C);
const _gold    = Color(0xFFFFD600);
const _bg      = Color(0xFFF5F0E8);
const _card    = Color(0xFFEDE7DA);
const _border  = Color(0xFF1A1A2E);
const _text    = Color(0xFF1A1A2E);
const _muted   = Color(0xFF555550);
const _shadow  = Color(0x661A1A2E);

// ── Colores de notas ──────────────────────────────────────────────────
const _noteColors = {
  'purple': Color(0xFF8B7FC7),
  'green':  Color(0xFF1D9E75),
  'gold':   Color(0xFFC9A227),
  'red':    Color(0xFFE07070),
  'blue':   Color(0xFF60A5FA),
  'gray':   Color(0xFF8186A0),
};

Color _noteColor(String key) => _noteColors[key] ?? const Color(0xFF8B7FC7);

// ── Formato de fecha ──────────────────────────────────────────────────
String _fmtDate(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Ahora mismo';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  final months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
  return '${dt.day} ${months[dt.month - 1]}';
}

// ═════════════════════════════════════════════════════════════════════
//  NOTES PAGE — router de vista lista / editor
// ═════════════════════════════════════════════════════════════════════
class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  Note? _activeNote;

  void _openNote(Note note) => setState(() => _activeNote = note);

  void _closeNote() {
    setState(() => _activeNote = null);
    ref.read(notesProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween(
            begin: _activeNote != null
                ? const Offset(1, 0)
                : const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        child: _activeNote == null
            ? _NotesList(key: const ValueKey('list'), onOpen: _openNote)
            : _NoteEditor(key: ValueKey(_activeNote!.id), note: _activeNote!, onBack: _closeNote),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  LISTA DE NOTAS
// ═════════════════════════════════════════════════════════════════════
class _NotesList extends ConsumerWidget {
  final void Function(Note) onOpen;
  const _NotesList({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final filtered   = ref.watch(filteredNotesProvider);
    final search     = ref.watch(notesSearchProvider);
    final isCreating = ValueNotifier(false);

    return Column(
      children: [
        // ── Top bar
        _ListTopBar(
          count: notesAsync.asData?.value.length ?? 0,
          onCreate: () async {
            isCreating.value = true;
            final note = await ref.read(notesProvider.notifier).createNote();
            isCreating.value = false;
            if (note != null) onOpen(note);
          },
        ),
        // ── Search
        _SearchBar(
          value: search,
          onChange: (v) => ref.read(notesSearchProvider.notifier).set(v),
          onClear: () => ref.read(notesSearchProvider.notifier).set(''),
        ),
        // ── Body
        Expanded(
          child: notesAsync.when(
            loading: () => _SkeletonList(),
            error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
            data: (_) {
              if (filtered.isEmpty) {
                return _EmptyState(hasSearch: search.isNotEmpty);
              }
              final pinned   = filtered.where((n) => n.isPinned).toList();
              final unpinned = filtered.where((n) => !n.isPinned).toList();

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (pinned.isNotEmpty) ...[
                    _GroupLabel(label: 'FIJADAS', icon: Icons.push_pin_rounded),
                    ...pinned.map((n) => _NoteCard(note: n, onTap: () => onOpen(n))),
                  ],
                  if (unpinned.isNotEmpty) ...[
                    if (pinned.isNotEmpty) _GroupLabel(label: 'TODAS'),
                    ...unpinned.map((n) => _NoteCard(note: n, onTap: () => onOpen(n))),
                  ],
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Top Bar lista ─────────────────────────────────────────────────────
class _ListTopBar extends StatelessWidget {
  final int count;
  final VoidCallback onCreate;
  const _ListTopBar({required this.count, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 0),
      height: 52 + topPad,
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 22, color: _accentL),
          const SizedBox(width: 8),
          const Text(
            'MIS NOTAS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: _text),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _accentL,
              border: Border.all(color: _border, width: 1),
              boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onCreate,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _accent,
                border: Border.all(color: _border, width: 1),
                boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buscador ──────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final String value;
  final void Function(String) onChange;
  final VoidCallback onClear;
  const _SearchBar({required this.value, required this.onChange, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 14, color: _muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChange,
              style: const TextStyle(fontSize: 12, color: _text),
              decoration: const InputDecoration(
                hintText: 'Buscar en notas...',
                hintStyle: TextStyle(fontSize: 12, color: _muted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (value.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 14, color: _muted),
            ),
        ],
      ),
    );
  }
}

// ── Etiqueta de grupo ─────────────────────────────────────────────────
class _GroupLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _GroupLabel({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: _gold),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de nota ───────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = _noteColor(note.color);
    final preview = note.content.split('\n').first.characters.take(60).toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: _bg,
          border: Border(bottom: BorderSide(color: _border, width: 1)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: c),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title.isEmpty ? 'Sin título' : note.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: note.title.isEmpty ? _muted : _text,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (note.isPinned) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.push_pin_rounded, size: 11, color: _gold),
                          ],
                        ],
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          preview.isEmpty ? 'Sin contenido' : preview,
                          style: const TextStyle(fontSize: 11, color: _muted, height: 1.4),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 9, color: _muted),
                          const SizedBox(width: 4),
                          Text(
                            _fmtDate(note.updatedAt),
                            style: const TextStyle(fontSize: 9, color: _muted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, size: 16, color: _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        height: 68,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border, width: 1)),
        ),
        child: Row(
          children: [
            Container(width: 4, color: _card),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 140, color: _card),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 200, color: _card),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _border, width: 1),
                boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
              ),
              child: Icon(
                hasSearch ? Icons.search_off : Icons.note_alt_outlined,
                size: 28,
                color: _accentL,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'SIN RESULTADOS' : 'SIN NOTAS AÚN',
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: _text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch ? 'Prueba con otra búsqueda.' : 'Pulsa + para crear tu primera nota.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  EDITOR DE NOTA
// ═════════════════════════════════════════════════════════════════════
class _NoteEditor extends ConsumerStatefulWidget {
  final Note note;
  final VoidCallback onBack;
  const _NoteEditor({super.key, required this.note, required this.onBack});

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late String _color;
  bool _dirty = false;
  bool _saving = false;
  bool _saved  = false;
  bool _showColors = false;
  bool _showDeleteModal = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _titleCtrl   = TextEditingController(text: widget.note.title);
    _contentCtrl = TextEditingController(text: widget.note.content);
    _color       = widget.note.color;

    _titleCtrl.addListener(_onChanged);
    _contentCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_dirty) setState(() => _dirty = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _save);
  }

  Future<void> _save() async {
    if (!_dirty) return;
    setState(() { _saving = true; _saved = false; });
    final ok = await ref.read(notesProvider.notifier).updateNote(
      widget.note.id,
      title:   _titleCtrl.text,
      content: _contentCtrl.text,
      color:   _color,
    );
    if (mounted) {
      setState(() { _saving = false; _dirty = false; if (ok) _saved = true; });
      if (ok) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saved = false);
        });
      }
    }
  }

  Future<void> _handleBack() async {
    if (_dirty) await _save();
    widget.onBack();
  }

  Future<void> _handleDelete() async {
    await ref.read(notesProvider.notifier).deleteNote(widget.note.id);
    widget.onBack();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _noteColor(_color);
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(height: topPad),
            // ── Editor top bar
            _EditorTopBar(
              dirty: _dirty,
              saving: _saving,
              saved: _saved,
              isPinned: widget.note.isPinned,
              color: c,
              showColors: _showColors,
              onBack: _handleBack,
              onToggleColors: () => setState(() => _showColors = !_showColors),
              onTogglePin: () => ref.read(notesProvider.notifier).togglePin(widget.note.id),
              onDelete: () => setState(() => _showDeleteModal = true),
            ),
            // ── Barra de color
            Container(height: 4, color: c),
            // ── Color picker
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: _showColors ? _ColorPicker(
                selected: _color,
                onSelect: (key) {
                  setState(() { _color = key; _showColors = false; _dirty = true; });
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), _save);
                },
              ) : const SizedBox.shrink(),
            ),
            // ── Título
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: TextField(
                controller: _titleCtrl,
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  color: _text, letterSpacing: -0.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Título…',
                  hintStyle: TextStyle(color: _muted, fontWeight: FontWeight.w700),
                  border: InputBorder.none,
                  isDense: true,
                ),
                maxLines: 1,
                textInputAction: TextInputAction.next,
              ),
            ),
            // ── Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _contentCtrl,
                  style: const TextStyle(fontSize: 13, color: _text, height: 1.8),
                  decoration: const InputDecoration(
                    hintText: 'Escribe aquí…\n\nSolo tú puedes leer esto.',
                    hintStyle: TextStyle(
                      color: _muted, fontStyle: FontStyle.italic, fontSize: 12, height: 1.8,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
            // ── Footer
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: _card,
                border: Border(top: BorderSide(color: _border, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 10, color: _accentL),
                  const SizedBox(width: 6),
                  const Text(
                    'NOTA PRIVADA',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: _muted),
                  ),
                  const Spacer(),
                  Text(
                    '${_contentCtrl.text.length} chars',
                    style: const TextStyle(fontSize: 8, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Modal de borrado
        if (_showDeleteModal)
          _DeleteModal(
            title: _titleCtrl.text.isEmpty ? 'Sin título' : _titleCtrl.text,
            onConfirm: () { setState(() => _showDeleteModal = false); _handleDelete(); },
            onCancel: () => setState(() => _showDeleteModal = false),
          ),
      ],
    );
  }
}

// ── Editor top bar ────────────────────────────────────────────────────
class _EditorTopBar extends StatelessWidget {
  final bool dirty, saving, saved, isPinned, showColors;
  final Color color;
  final VoidCallback onBack, onToggleColors, onTogglePin, onDelete;

  const _EditorTopBar({
    required this.dirty,
    required this.saving,
    required this.saved,
    required this.isPinned,
    required this.showColors,
    required this.color,
    required this.onBack,
    required this.onToggleColors,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _bg,
                border: Border.all(color: _border, width: 1),
                boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
              ),
              child: const Icon(Icons.arrow_back, size: 16, color: _text),
            ),
          ),
          const SizedBox(width: 10),
          // Estado
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: saving
                  ? _StatusChip(key: const ValueKey('saving'), label: 'Guardando…', color: _muted)
                  : saved
                      ? _StatusChip(key: const ValueKey('saved'), label: '✓ Guardado', color: _correct)
                      : dirty
                          ? _StatusChip(key: const ValueKey('dirty'), label: 'Sin guardar', color: _exact)
                          : const SizedBox.shrink(key: ValueKey('none')),
            ),
          ),
          // Acciones
          Row(
            children: [
              // Color dot
              GestureDetector(
                onTap: onToggleColors,
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: _bg,
                    border: Border.all(color: _border, width: 1),
                    boxShadow: showColors
                        ? const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)]
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(color: _border, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
              // Pin
              GestureDetector(
                onTap: onTogglePin,
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: isPinned ? _gold : _bg,
                    border: Border.all(color: _border, width: 1),
                    boxShadow: isPinned
                        ? const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)]
                        : null,
                  ),
                  child: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 14,
                    color: isPinned ? _text : _muted,
                  ),
                ),
              ),
              // Delete
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: _bg,
                    border: Border.all(color: _border, width: 1),
                    boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
                  ),
                  child: const Icon(Icons.delete_outline, size: 14, color: _exact),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    );
  }
}

// ── Color picker ──────────────────────────────────────────────────────
class _ColorPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _ColorPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _noteColors.entries.map((e) {
          final active = e.key == selected;
          return GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: active ? 26 : 22,
              height: active ? 26 : 22,
              decoration: BoxDecoration(
                color: e.value,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? _border : Colors.transparent,
                  width: active ? 2 : 0,
                ),
                boxShadow: active
                    ? const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)]
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Modal de borrado ──────────────────────────────────────────────────
class _DeleteModal extends StatelessWidget {
  final String title;
  final VoidCallback onConfirm, onCancel;
  const _DeleteModal({required this.title, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // absorb
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _bg,
                border: Border.all(color: _border, width: 1),
                boxShadow: const [BoxShadow(color: _shadow, offset: Offset(3, 3), blurRadius: 0)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _exact,
                      border: Border.all(color: _border, width: 1),
                      boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ELIMINAR NOTA',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '«$title» se eliminará definitivamente.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: _muted, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: _bg,
                              border: Border.all(color: _border, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'CANCELAR',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: _text),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: _exact,
                              border: Border.all(color: _border, width: 1),
                              boxShadow: const [BoxShadow(color: _shadow, offset: Offset(1, 1), blurRadius: 0)],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'ELIMINAR',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white),
                            ),
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