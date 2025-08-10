import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _usernameKey = 'username';

  // Save username to shared preferences
  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  // Get username from shared preferences
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Remove username from shared preferences
  static Future<void> removeUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
  }

  // Check if username exists
  static Future<bool> hasUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_usernameKey);
  }
}
