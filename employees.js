const express = require('express');
const router = express.Router();
const db = require('../db');

// إضافة موظف جديد
router.post('/', (req, res) => {
  const { employee_code, full_name, department, phone } = req.body;

  if (!employee_code || !full_name) {
    return res.status(400).json({ error: 'كود الموظف والاسم مطلوبان' });
  }

  try {
    const stmt = db.prepare(
      `INSERT INTO employees (employee_code, full_name, department, phone) VALUES (?, ?, ?, ?)`
    );
    const result = stmt.run(employee_code, full_name, department || null, phone || null);
    res.status(201).json({ id: result.lastInsertRowid, employee_code, full_name, department, phone });
  } catch (err) {
    if (err.message.includes('UNIQUE')) {
      return res.status(409).json({ error: 'كود الموظف مستخدم بالفعل' });
    }
    res.status(500).json({ error: 'خطأ في الخادم', details: err.message });
  }
});

// قائمة كل الموظفين
router.get('/', (req, res) => {
  const employees = db.prepare(`SELECT * FROM employees ORDER BY full_name`).all();
  res.json(employees);
});

// البحث عن موظف بكوده (يستخدمه تطبيق الموبايل لتسجيل الدخول)
router.get('/:code', (req, res) => {
  const employee = db.prepare(
    `SELECT * FROM employees WHERE employee_code = ? AND active = 1`
  ).get(req.params.code);

  if (!employee) {
    return res.status(404).json({ error: 'الموظف غير موجود أو غير نشط' });
  }
  res.json(employee);
});

// تعطيل/تفعيل موظف
router.patch('/:code/status', (req, res) => {
  const { active } = req.body;
  const result = db.prepare(
    `UPDATE employees SET active = ? WHERE employee_code = ?`
  ).run(active ? 1 : 0, req.params.code);

  if (result.changes === 0) {
    return res.status(404).json({ error: 'الموظف غير موجود' });
  }
  res.json({ success: true });
});

module.exports = router;
