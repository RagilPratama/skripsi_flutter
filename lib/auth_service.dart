class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<bool> login(String email, String password) async {
    // Simulasi API call
    await Future.delayed(const Duration(seconds: 2));

    // Validasi sederhana untuk demo
    if (email == 'admin@gmail.com' && password == 'admin123') {
      _isLoggedIn = true;
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoggedIn = false;
  }

  Future<bool> register(String name, String email, String password) async {
    // Simulasi API call
    await Future.delayed(const Duration(seconds: 2));

    // Untuk demo, selalu return true
    return true;
  }
}
