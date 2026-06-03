import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notes_service.dart';

// ── Lista de notas ────────────────────────────────────────────────────
class NotesNotifier extends AsyncNotifier<List<Note>> {
  final _service = NotesService();

  @override
  Future<List<Note>> build() => _service.fetchNotes();

  List<Note> get _current => state.asData?.value ?? [];

  Future<Note?> createNote() async {
    try {
      final note = await _service.createNote();
      state = AsyncData([note, ..._current]);
      return note;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateNote(String id, {String? title, String? content, String? color}) async {
    try {
      await _service.updateNote(id, title: title, content: content, color: color);
      state = AsyncData(
        _current.map((n) {
          if (n.id != id) return n;
          return n.copyWith(
            title: title,
            content: content,
            color: color,
            updatedAt: DateTime.now(),
          );
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> togglePin(String id) async {
    final note = _current.firstWhere((n) => n.id == id);
    await _service.togglePin(id, note.isPinned);
    final updated = _current
        .map((n) => n.id == id ? n.copyWith(isPinned: !n.isPinned) : n)
        .toList()
      ..sort((a, b) {
        if (a.isPinned == b.isPinned) return b.updatedAt.compareTo(a.updatedAt);
        return a.isPinned ? -1 : 1;
      });
    state = AsyncData(updated);
  }

  Future<void> deleteNote(String id) async {
    await _service.deleteNote(id);
    state = AsyncData(_current.where((n) => n.id != id).toList());
  }

  void refresh() => ref.invalidateSelf();
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

// ── Búsqueda local (Riverpod 3: Notifier en lugar de StateProvider) ───
class NotesSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final notesSearchProvider =
    NotifierProvider<NotesSearchNotifier, String>(NotesSearchNotifier.new);

final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider).asData?.value ?? [];
  final q = ref.watch(notesSearchProvider).toLowerCase().trim();
  if (q.isEmpty) return notes;
  return notes
      .where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q))
      .toList();
});