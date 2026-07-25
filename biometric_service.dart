import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// يستخدم بصمة الإصبع أو الوجه المسجّلة على الهاتف نفسه للتأكد إن الشخص
  /// اللي بيوقع هو صاحب الجهاز الفعلي، كطبقة تحقق محلية قبل إرسال التوقيع للخادم.
  static Future<BiometricResult> authenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        return BiometricResult(
          success: false,
          message: 'جهازك لا يدعم البصمة أو التعرف على الوجه، أو لم يتم تسجيل أي بصمة على الجهاز.',
        );
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'برجاء التحقق ببصمتك لتسجيل الحضور/الانصراف',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return BiometricResult(
        success: didAuthenticate,
        message: didAuthenticate ? 'تم التحقق بنجاح' : 'فشل التحقق من البصمة',
      );
    } catch (e) {
      return BiometricResult(success: false, message: 'خطأ في التحقق من البصمة: $e');
    }
  }
}

class BiometricResult {
  final bool success;
  final String message;
  BiometricResult({required this.success, required this.message});
}
