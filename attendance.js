const express = require('express');
const router = express.Router();
const db = require('../db');
const { distanceInMeters } = require('../geo');
const config = require('../config');

// دالة مشتركة لتسجيل حضور أو انصراف
function recordAttendance(req, res, type) {
  const { employee_code, latitude, longitude, device_info } = req.body;

  if (!employee_code || latitude === undefined || longitude === undefined) {
    return res.status(400).json({ error: 'كود الموظف والإحداثيات مطلوبة' });
  }

  const employee = db.prepare(
    `SELECT * FROM employees WHERE employee_code = ? AND active = 1`
  ).get(employee_code);

  if (!employee) {
    return res.status(404).json({ error: 'الموظف غير موجود أو غير نشط' });
  }

  const distance = distanceInMeters(
    latitude,
    longitude,
    config.COMPANY_LOCATION.latitude,
    config.COMPANY_LOCATION.longitude
  );

  const withinRange = distance <= config.ALLOWED_RADIUS_METERS;
  const status = withinRange ? 'accepted' : 'rejected_out_of_range';

  const stmt = db.prepare(`
    INSERT INTO attendance_records
      (employee_id, type, latitude, longitude, distance_meters, status, device_info)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);
  const result = stmt.run(
    employee.id, type, latitude, longitude, Math.round(distance), status, device_info || null
  );

  if (!withinRange) {
    return res.status(403).json({
      accepted: false,
      error: `أنت خارج نطاق العمل المسموح به (${config.ALLOWED_RADIUS_METERS} متر). المسافة الحالية: ${Math.round(distance)} متر`,
      distance_meters: Math.round(distance),
      record_id: result.lastInsertRowid
    });
  }

  res.status(201).json({
    accepted: true,
    message: type === 'check_in' ? 'تم تسجيل الحضور بنجاح' : 'تم تسجيل الانصراف بنجاح',
    record_id: result.lastInsertRowid,
    distance_meters: Math.round(distance),
    timestamp: new Date().toISOString()
  });
}

router.post('/check-in', (req, res) => recordAttendance(req, res, 'check_in'));
router.post('/check-out', (req, res) => recordAttendance(req, res, 'check_out'));

// سجلات الحضور (للوحة التحكم) - مع فلترة اختيارية بالتاريخ وكود الموظف
router.get('/records', (req, res) => {
  const { date, employee_code } = req.query;

  let query = `
    SELECT ar.id, e.employee_code, e.full_name, e.department, ar.type,
           ar.timestamp, ar.latitude, ar.longitude, ar.distance_meters, ar.status
    FROM attendance_records ar
    JOIN employees e ON e.id = ar.employee_id
    WHERE 1=1
  `;
  const params = [];

  if (date) {
    query += ` AND date(ar.timestamp) = ?`;
    params.push(date);
  }
  if (employee_code) {
    query += ` AND e.employee_code = ?`;
    params.push(employee_code);
  }

  query += ` ORDER BY ar.timestamp DESC`;

  const records = db.prepare(query).all(...params);
  res.json(records);
});

// ملخص اليوم (للوحة التحكم الرئيسية)
router.get('/summary/today', (req, res) => {
  const today = new Date().toISOString().split('T')[0];

  const totalEmployees = db.prepare(`SELECT COUNT(*) as c FROM employees WHERE active = 1`).get().c;

  const checkedIn = db.prepare(`
    SELECT COUNT(DISTINCT employee_id) as c FROM attendance_records
    WHERE type = 'check_in' AND status = 'accepted' AND date(timestamp) = ?
  `).get(today).c;

  const rejected = db.prepare(`
    SELECT COUNT(*) as c FROM attendance_records
    WHERE status = 'rejected_out_of_range' AND date(timestamp) = ?
  `).get(today).c;

  res.json({
    date: today,
    total_employees: totalEmployees,
    checked_in_today: checkedIn,
    not_checked_in: totalEmployees - checkedIn,
    rejected_attempts_out_of_range: rejected
  });
});

module.exports = router;
