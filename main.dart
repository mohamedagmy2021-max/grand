import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AlImanAttendanceApp());
}

class AlImanAttendanceApp extends StatelessWidget {
  const AlImanAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حضور وانصراف - مصنع الإيمان',
      debugShowCheckedModeBanner: false,
      // دعم الاتجاه من اليمين لليسار للواجهة العربية
      locale: const Locale('ar', ''),
      supportedLocales: const [Locale('ar', ''), Locale('en', '')],
      theme: ThemeData(
        primaryColor: const Color(0xFF1F4E3D),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4E3D)),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      home: const _StartupGate(),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}

/// يحدد الشاشة الأولى: هل الموظف مسجل دخول بالفعل أم يحتاج تسجيل الكود؟
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('employee_code') != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data! ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
