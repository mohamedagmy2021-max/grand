// إعدادات الموقع الجغرافي للمصنع ونطاق السماح بالتوقيع
// عدّل هذه القيم لتطابق إحداثيات موقع مصنع الإيمان الفعلي (يمكن الحصول عليها من Google Maps
// بالضغط بزر الفأرة الأيمن على موقع المصنع ثم نسخ الإحداثيات)

module.exports = {
  COMPANY_LOCATION: {
    latitude: parseFloat(process.env.COMPANY_LAT) || 31.4165,   // دمياط - إحداثي افتراضي، يجب تعديله
    longitude: parseFloat(process.env.COMPANY_LNG) || 31.8133,  // دمياط - إحداثي افتراضي، يجب تعديله
    name: process.env.COMPANY_NAME || "مصنع الإيمان للمراتب والمفروشات"
  },
  // نصف قطر النطاق المسموح بالتوقيع بداخله (بالمتر)
  ALLOWED_RADIUS_METERS: parseInt(process.env.ALLOWED_RADIUS_METERS) || 150,
  PORT: process.env.PORT || 3000
};
