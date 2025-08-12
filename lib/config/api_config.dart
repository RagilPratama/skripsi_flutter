class ApiConfig {
  // Centralized API configuration
  static const String baseUrl = 'https://8f9f6e2f555e.ngrok-free.app';

  // API Endpoints
  static const String login = '/user/login';

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Auth headers with token
  static Map<String, String> getAuthHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
