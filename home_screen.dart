import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color factoryGreen = Color(0xFF1F4E3D);
  static const Color factoryGreenLight = Color(0xFF2E6B5E);

  String _employeeName = '';
  String _employeeCode = '';
  bool _busy = false;
  String _statusMessage = 'جاهز لتسجيل الحضور أو الانصراف';
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  Future<void> _loadEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _employeeName = prefs.getString('employee_name') ?? '';
      _employeeCode = prefs.getString('employee_code') ?? '';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  /// المسار الكامل للتوقيع: تفعيل الموقع أولاً (خطوة إجبارية) -> بصمة محلية -> إرسال للخادم
  Future<void> _handleAttendance(String type) async {
    setState(() {
      _busy = true;
      _statusMessage = 'جاري تحديد الموقع...';
      _statusColor = Colors.orange;
    });

    // 1) خطوة إجبارية: تفعيل الموقع والحصول على الإحداثيات
    final location = await LocationService.getCurrentLocation();
    if (!location.success) {
      setState(() {
        _busy = false;
        _statusMessage = location.errorMessage!;
        _statusColor = Colors.red;
      });
      return;
    }

    // 2) التحقق ببصمة الإصبع/الوجه المحلية على الجهاز
    setState(() => _statusMessage = 'جاري التحقق من البصمة...');
    final bio = await BiometricService.authenticate();
    if (!bio.success) {
      setState(() {
        _busy = false;
        _statusMessage = bio.message;
        _statusColor = Colors.red;
      });
      return;
    }

    // 3) إرسال التوقيع للخادم مع الإحداثيات، والخادم هو من يقرر القبول أو الرفض حسب النطاق
    setState(() => _statusMessage = 'جاري إرسال البيانات...');
    final deviceInfo = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

    final result = type == 'check_in'
        ? await ApiService.checkIn(
            employeeCode: _employeeCode,
            latitude: location.latitude!,
            longitude: location.longitude!,
            deviceInfo: deviceInfo,
          )
        : await ApiService.checkOut(
            employeeCode: _employeeCode,
            latitude: location.latitude!,
            longitude: location.longitude!,
            deviceInfo: deviceInfo,
          );

    setState(() {
      _busy = false;
      if (result.success) {
        _statusMessage = result.data['message'] ?? 'تم التسجيل بنجاح';
        _statusColor = factoryGreen;
      } else {
        _statusMessage = result.data['error'] ?? 'حدث خطأ أثناء التسجيل';
        _statusColor = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: factoryGreen,
        title: Text(_employeeName.isEmpty ? '...' : _employeeName),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    _busy
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _statusColor, strokeWidth: 2))
                        : Icon(Icons.info_outline, color: _statusColor),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_statusMessage, style: TextStyle(color: _statusColor))),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('تسجيل حضور', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: factoryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _busy ? null : () => _handleAttendance('check_in'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('تسجيل انصراف', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: factoryGreenLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _busy ? null : () => _handleAttendance('check_out'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
