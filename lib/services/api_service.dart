import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Generic PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Authenticated GET request
  Future<Map<String, dynamic>> getWithAuth(
    String endpoint,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Authenticated POST request
  Future<Map<String, dynamic>> postWithAuth(
    String endpoint,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> result = {
      'success': response.statusCode >= 200 && response.statusCode < 300,
      'statusCode': response.statusCode,
    };

    try {
      final data = jsonDecode(response.body);
      result['data'] = data;
    } catch (e) {
      result['data'] = response.body;
    }

    if (!result['success']) {
      result['error'] = result['data']?['message'] ?? 'Request failed';
    }

    return result;
  }

  // Handle errors
  Map<String, dynamic> _handleError(dynamic error) {
    return {'success': false, 'error': error.toString()};
  }
}
