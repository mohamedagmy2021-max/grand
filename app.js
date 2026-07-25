// عدّل هذا الرابط ليطابق عنوان الخادم الفعلي بعد رفعه
const API_BASE = 'http://localhost:3000/api';

const typeLabels = { check_in: 'حضور', check_out: 'انصراف' };
const statusLabels = { accepted: 'مقبول', rejected_out_of_range: 'مرفوض - خارج النطاق' };

function todayStr() {
  return new Date().toISOString().split('T')[0];
}

async function loadSummary() {
  try {
    const res = await fetch(`${API_BASE}/attendance/summary/today`);
    const data = await res.json();
    document.getElementById('statTotal').textContent = data.total_employees;
    document.getElementById('statIn').textContent = data.checked_in_today;
    document.getElementById('statOut').textContent = data.not_checked_in;
    document.getElementById('statRejected').textContent = data.rejected_attempts_out_of_range;
  } catch (e) {
    console.error('تعذر تحميل الملخص:', e);
  }
}

async function loadRecords() {
  const date = document.getElementById('dateFilter').value || '';
  const employeeCode = document.getElementById('employeeFilter').value.trim();

  const params = new URLSearchParams();
  if (date) params.set('date', date);
  if (employeeCode) params.set('employee_code', employeeCode);

  const tbody = document.getElementById('recordsBody');

  try {
    const res = await fetch(`${API_BASE}/attendance/records?${params.toString()}`);
    const records = await res.json();

    if (!records.length) {
      tbody.innerHTML = `<tr><td colspan="6" class="empty-state">لا توجد سجلات مطابقة</td></tr>`;
      return;
    }

    tbody.innerHTML = records.map(r => `
      <tr>
        <td><strong>${r.full_name}</strong><br><span class="distance-mono">${r.employee_code}</span></td>
        <td>${r.department || '—'}</td>
        <td><span class="pill ${r.type}">${typeLabels[r.type]}</span></td>
        <td class="distance-mono">${r.timestamp}</td>
        <td class="distance-mono">${r.distance_meters} م</td>
        <td><span class="pill ${r.status === 'accepted' ? 'accepted' : 'rejected'}">${statusLabels[r.status]}</span></td>
      </tr>
    `).join('');
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="6" class="empty-state">تعذر الاتصال بالخادم</td></tr>`;
  }
}

document.getElementById('dateFilter').value = todayStr();
document.getElementById('dateFilter').addEventListener('change', loadRecords);
document.getElementById('employeeFilter').addEventListener('input', () => {
  clearTimeout(window._filterTimeout);
  window._filterTimeout = setTimeout(loadRecords, 300);
});

loadSummary();
loadRecords();
setInterval(loadSummary, 30000); // تحديث الملخص كل 30 ثانية
