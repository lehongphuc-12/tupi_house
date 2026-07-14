import 'package:shared_preferences/shared_preferences.dart';

/// Lưu trữ cục bộ bằng SharedPreferences: dùng cho tính năng "Remember Me"
/// và lưu phiên đăng nhập hiện tại.
class StorageService {
  static const _kRememberMe = 'remember_me';
  static const _kSavedEmail = 'saved_email';
  static const _kLoggedUserId = 'logged_user_id';
  static const _kLoggedUserName = 'logged_user_name';
  static const _kLoggedUserEmail = 'logged_user_email';

  static Future<void> saveSession({
    required String userId,
    required String fullName,
    required String email,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLoggedUserId, userId);
    await prefs.setString(_kLoggedUserName, fullName);
    await prefs.setString(_kLoggedUserEmail, email);
    await prefs.setBool(_kRememberMe, rememberMe);
    if (rememberMe) {
      await prefs.setString(_kSavedEmail, email);
    } else {
      await prefs.remove(_kSavedEmail);
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedUserId);
    await prefs.remove(_kLoggedUserName);
    await prefs.remove(_kLoggedUserEmail);
    // Không xóa remember_me/saved_email để lần sau vẫn gợi ý email đã lưu.
  }

  static Future<Map<String, String>?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_kLoggedUserId);
    if (userId == null) return null;
    return {
      'userId': userId,
      'fullName': prefs.getString(_kLoggedUserName) ?? '',
      'email': prefs.getString(_kLoggedUserEmail) ?? '',
    };
  }

  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRememberMe) ?? false;
  }

  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSavedEmail);
  }
}
