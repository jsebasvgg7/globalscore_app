import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Constantes de cifrado (deben coincidir con React) ─────────────────
const _salt       = 'GlobalScore_Notes_v1';
const _iterations = 100000;
const _keyLen     = 32; // 256 bits

class Note {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String color;
  final bool isPinned;
  final DateTime updatedAt;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.color,
    required this.isPinned,
    required this.updatedAt,
    required this.createdAt,
  });

  // fromMap recibe las columnas crudas (title_enc, content_enc ya descifradas)
  factory Note.fromDecrypted(Map<String, dynamic> m, String title, String content) => Note(
        id:        m['id'] as String,
        userId:    m['user_id'] as String,
        title:     title,
        content:   content,
        color:     m['color'] as String? ?? 'purple',
        isPinned:  m['is_pinned'] as bool? ?? false,
        updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  Note copyWith({
    String? title,
    String? content,
    String? color,
    bool? isPinned,
    DateTime? updatedAt,
  }) => Note(
        id:        id,
        userId:    userId,
        title:     title    ?? this.title,
        content:   content  ?? this.content,
        color:     color    ?? this.color,
        isPinned:  isPinned ?? this.isPinned,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt,
      );
}

// ═════════════════════════════════════════════════════════════════════
//  CRYPTO — replica exacta del código React
// ═════════════════════════════════════════════════════════════════════
class _NoteCrypto {
  late Uint8List _keyBytes;

  /// Deriva la clave AES-256 desde authId usando PBKDF2-SHA256
  /// Mismo algoritmo que deriveKey() en notes.service.js
  void init(String authId) {
    final saltBytes  = Uint8List.fromList(utf8.encode(_salt));
    final passBytes  = Uint8List.fromList(utf8.encode(authId));

    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(saltBytes, _iterations, _keyLen));

    _keyBytes = pbkdf2.process(passBytes);
  }

  /// Descifra un string con formato "base64(iv).base64(ciphertext)"
  String decrypt(String cipher) {
    if (cipher.isEmpty) return '';
    try {
      final parts = cipher.split('.');
      if (parts.length != 2) return '[ilegible]';

      final iv         = base64.decode(parts[0]);
      final ciphertext = base64.decode(parts[1]);

      final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(_keyBytes), Uint8List.fromList(iv)),
        null,
      );

      final cipher_ = PaddedBlockCipher('AES/CBC/PKCS7')..init(false, params);
      final plain   = cipher_.process(Uint8List.fromList(ciphertext));
      return utf8.decode(plain);
    } catch (_) {
      return '[contenido ilegible]';
    }
  }

  /// Cifra un string y devuelve "base64(iv).base64(ciphertext)"
  String encrypt(String text) {
    if (text.isEmpty) return '';
    final iv        = _generateIV();
    final plaintext = Uint8List.fromList(utf8.encode(text));

    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(_keyBytes), iv),
      null,
    );

    final cipher_ = PaddedBlockCipher('AES/CBC/PKCS7')..init(true, params);
    final ciphertext = cipher_.process(plaintext);

    return '${base64.encode(iv)}.${base64.encode(ciphertext)}';
  }

  Uint8List _generateIV() {
    final secureRandom = FortunaRandom()
      ..seed(KeyParameter(Uint8List.fromList(
        List.generate(32, (i) => DateTime.now().microsecondsSinceEpoch & 0xFF),
      )));
    return secureRandom.nextBytes(16);
  }
}

// ═════════════════════════════════════════════════════════════════════
//  SERVICE
// ═════════════════════════════════════════════════════════════════════
class NotesService {
  final _db     = Supabase.instance.client;
  final _crypto = _NoteCrypto();
  bool _initialized = false;

  /// Debe llamarse una vez al cargar la pantalla
  Future<void> init() async {
    if (_initialized) return;
    final authId = _db.auth.currentUser!.id;
    _crypto.init(authId);
    _initialized = true;
  }

  Future<String> _getUserId() async {
    final authId = _db.auth.currentUser!.id;
    final data   = await _db.from('users').select('id').eq('auth_id', authId).single();
    return data['id'] as String;
  }

  Future<List<Note>> fetchNotes() async {
    await init();
    final userId = await _getUserId();
    final rows   = await _db
        .from('notes')
        .select()
        .eq('user_id', userId)
        .order('is_pinned', ascending: false)
        .order('updated_at', ascending: false);

    return (rows as List).map((r) {
      final m       = r as Map<String, dynamic>;
      final title   = _crypto.decrypt(m['title_enc']   as String? ?? '');
      final content = _crypto.decrypt(m['content_enc'] as String? ?? '');
      return Note.fromDecrypted(m, title, content);
    }).toList();
  }

  Future<Note> createNote() async {
    await init();
    final userId     = await _getUserId();
    final titleEnc   = _crypto.encrypt('');
    final contentEnc = _crypto.encrypt('');

    final row = await _db.from('notes').insert({
      'user_id':     userId,
      'title_enc':   titleEnc,
      'content_enc': contentEnc,
      'color':       'purple',
      'is_pinned':   false,
    }).select().single();

    return Note.fromDecrypted(row as Map<String, dynamic>, '', '');
  }

  Future<void> updateNote(String id, {String? title, String? content, String? color}) async {
    await init();
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (title   != null) payload['title_enc']   = _crypto.encrypt(title);
    if (content != null) payload['content_enc'] = _crypto.encrypt(content);
    if (color   != null) payload['color']        = color;

    await _db.from('notes').update(payload).eq('id', id);
  }

  Future<void> togglePin(String id, bool currentPin) async {
    await _db.from('notes').update({'is_pinned': !currentPin}).eq('id', id);
  }

  Future<void> deleteNote(String id) async {
    await _db.from('notes').delete().eq('id', id);
  }
}