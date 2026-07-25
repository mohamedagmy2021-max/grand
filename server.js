require('dotenv').config();
const express = require('express');
const cors = require('cors');
const config = require('./config');

const employeesRouter = require('./routes/employees');
const attendanceRouter = require('./routes/attendance');

const app = express();
app.use(cors());
app.use(express.json());

// نقطة فحص سريعة إن الخادم شغال، وتعرض إعدادات الموقع الحالية
app.get('/', (req, res) => {
  res.json({
    service: 'نظام حضور وانصراف - مصنع الإيمان',
    status: 'running',
    company_location: config.COMPANY_LOCATION,
    allowed_radius_meters: config.ALLOWED_RADIUS_METERS
  });
});

app.use('/api/employees', employeesRouter);
app.use('/api/attendance', attendanceRouter);

app.use((req, res) => {
  res.status(404).json({ error: 'المسار غير موجود' });
});

app.listen(config.PORT, () => {
  console.log(`✅ الخادم يعمل على http://localhost:${config.PORT}`);
  console.log(`📍 موقع المصنع: ${config.COMPANY_LOCATION.latitude}, ${config.COMPANY_LOCATION.longitude} (نطاق ${config.ALLOWED_RADIUS_METERS} متر)`);
});
