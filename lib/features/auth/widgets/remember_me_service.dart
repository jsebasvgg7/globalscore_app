import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════
//  REMEMBER ME SERVICE
//  Guarda y recupera el email del usuario usando SharedPreferences.
//  Uso:
//    final email = await RememberMeService.load();
//    await RememberMeService.save(email);
//    await RememberMeService.clear();
// ═══════════════════════════════════════════════════════════

class RememberMeService {
  static const _kKey = 'remember_me_email';

  /// Devuelve el email guardado, o null si no hay ninguno.
  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kKey);
  }

  /// Guarda el email para la próxima vez que el usuario abra la app.
  static Future<void> save(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, email);
  }

  /// Borra el email guardado (cuando el usuario desmarca "Recordarme").
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}
