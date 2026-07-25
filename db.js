const Database = require('better-sqlite3');
const path = require('path');

const db = new Database(path.join(__dirname, 'attendance.db'));

db.pragma('journal_mode = WAL');

// جدول الموظفين
db.exec(`
  CREATE TABLE IF NOT EXISTS employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_code TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    department TEXT,
    phone TEXT,
    active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT (datetime('now'))
  )
`);

// جدول سجلات الحضور والانصراف
db.exec(`
  CREATE TABLE IF NOT EXISTS attendance_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('check_in', 'check_out')),
    timestamp TEXT DEFAULT (datetime('now')),
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    distance_meters REAL,
    status TEXT NOT NULL CHECK(status IN ('accepted', 'rejected_out_of_range')),
    device_info TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(id)
  )
`);

// جدول محاولات مرفوضة (خارج النطاق) - نفس جدول السجلات لكن بحقل status='rejected_out_of_range'
// (تم دمجه أعلاه بدلاً من جدول منفصل لتبسيط الاستعلامات)

module.exports = db;
