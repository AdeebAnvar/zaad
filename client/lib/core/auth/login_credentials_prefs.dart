import 'package:shared_preferences/shared_preferences.dart';

/// Optional remember-me storage for the local login form (not synced).
class LoginCredentialsPrefs {
  LoginCredentialsPrefs._();

  static const _usernameKey = 'login_saved_username';
  static const _passwordKey = 'login_saved_password';

  static String? readUsername(SharedPreferences p) {
    final u = p.getString(_usernameKey)?.trim();
    if (u == null || u.isEmpty) return null;
    return u;
  }

  static String? readPassword(SharedPreferences p) {
    final pw = p.getString(_passwordKey);
    if (pw == null || pw.isEmpty) return null;
    return pw;
  }

  static bool hasSaved(SharedPreferences p) =>
      readUsername(p) != null && readPassword(p) != null;

  static Future<void> save(SharedPreferences p, String username, String password) async {
    await p.setString(_usernameKey, username.trim());
    await p.setString(_passwordKey, password);
  }

  static Future<void> clear(SharedPreferences p) async {
    await p.remove(_usernameKey);
    await p.remove(_passwordKey);
  }
}
