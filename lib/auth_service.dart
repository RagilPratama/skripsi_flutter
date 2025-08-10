import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  String? _token;
  String? _username;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get username => _username;

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: ApiConfig.headers,
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 201) {
        _username = username;
        _isLoggedIn = true;
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('Login failed: ${error['message'] ?? response.body}');
        return false;
      }
    } catch (e) {
      print('Network error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _username = null;
    _isLoggedIn = false;
  }
}
