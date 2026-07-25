import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiResult {
  final bool success;
  final Map<String, dynamic> data;
  ApiResult(this.success, this.data);
}

class ApiService {
  static Future<ApiResult> findEmployee(String employeeCode) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/employees/$employeeCode');
    final response = await http.get(uri);
    final data = jsonDecode(response.body);
    return ApiResult(response.statusCode == 200, data);
  }

  static Future<ApiResult> checkIn({
    required String employeeCode,
    required double latitude,
    required double longitude,
    required String deviceInfo,
  }) {
    return _postAttendance('check-in', employeeCode, latitude, longitude, deviceInfo);
  }

  static Future<ApiResult> checkOut({
    required String employeeCode,
    required double latitude,
    required double longitude,
    required String deviceInfo,
  }) {
    return _postAttendance('check-out', employeeCode, latitude, longitude, deviceInfo);
  }

  static Future<ApiResult> _postAttendance(
    String endpoint,
    String employeeCode,
    double latitude,
    double longitude,
    String deviceInfo,
  ) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/attendance/$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employee_code': employeeCode,
          'latitude': latitude,
          'longitude': longitude,
          'device_info': deviceInfo,
        }),
      );
      final data = jsonDecode(response.body);
      return ApiResult(response.statusCode == 201, data);
    } catch (e) {
      return ApiResult(false, {'error': 'تعذر الاتصال بالخادم: $e'});
    }
  }
}
