import 'package:geolocator/geolocator.dart';

/// نتيجة محاولة الحصول على الموقع
class LocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  LocationResult.ok(this.latitude, this.longitude)
      : success = true,
        errorMessage = null;

  LocationResult.error(this.errorMessage)
      : success = false,
        latitude = null,
        longitude = null;
}

class LocationService {
  /// يتأكد إن خدمة الموقع مفعّلة على الجهاز، ويطلب الصلاحية إذا لزم الأمر،
  /// ثم يرجع الإحداثيات الحالية. هذه هي الخطوة الإجبارية الأولى قبل أي توقيع.
  static Future<LocationResult> getCurrentLocation() async {
    // 1. تأكد إن GPS مفعّل على الهاتف نفسه
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.error(
        'خدمة الموقع (GPS) غير مفعّلة على جهازك. برجاء تفعيلها من الإعدادات أولاً.',
      );
    }

    // 2. تحقق من صلاحية الوصول للموقع واطلبها إذا لزم
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.error(
          'تم رفض صلاحية الموقع. لا يمكن تسجيل الحضور بدون تفعيل الموقع.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult.error(
        'صلاحية الموقع مرفوضة بشكل دائم. برجاء تفعيلها يدويًا من إعدادات التطبيق.',
      );
    }

    // 3. جلب الإحداثيات الحالية بدقة عالية
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LocationResult.ok(position.latitude, position.longitude);
    } catch (e) {
      return LocationResult.error('تعذر تحديد الموقع الحالي: $e');
    }
  }
}
