// API LIST — HR DASHBOARD

const String baseUrl = 'https://hrsystembackend-4xzs.onrender.com';

// ───────────── AUTH ─────────────
const String authLogin = '/api/auth/login'; // POST

// ───────────── DASHBOARD ─────────────
const String dashboard = '/api/hr/dashboard'; // GET
const String birthdaysToday = '/api/birthdays/today'; // GET

// ───────────── EMPLOYEES ─────────────
const String employees = '/api/hr/employees'; // GET, POST
const String employeeById = '/api/hr/employees/:id'; // GET, PUT, DELETE
const String employeeStatus = '/api/hr/employees/:id/status'; // PATCH
const String employeeSalary = '/api/hr/employees/:id/salary'; // PUT
const String employeeDeactivate = '/api/hr/employees/:id/deactivate'; // POST
const String employeeReactivate = '/api/hr/employees/:id/reactivate'; // POST
const String employeeResign = '/api/hr/employees/:id/resign'; // POST

// ───────────── DEPARTMENTS ─────────────
const String departments = '/api/hr/departments'; // GET
const String departmentByKey = '/api/hr/departments/:deptKey'; // GET

// ───────────── ATTENDANCE ─────────────
const String attendance = '/api/hr/attendance'; // GET
const String attendanceByEmployee = '/api/hr/attendance/:employeeId'; // GET
const String attendanceCheckedOutCount = '/api/hr/attendance/checked-out/count'; // GET
const String staffCheckIn = '/api/staff/attendance/check-in'; // POST
const String staffCheckOut = '/api/staff/attendance/check-out'; // POST

// ───────────── LEAVES ─────────────
const String leaves = '/api/hr/leaves'; // GET, DELETE
const String leavesAll = '/api/hr/leaves/all'; // DELETE
const String leaveById = '/api/hr/leaves/:id'; // GET
const String leaveApprove = '/api/hr/leaves/:id/approve'; // PUT
const String leaveReject = '/api/hr/leaves/:id/reject'; // PUT

// ───────────── DOCUMENTS ─────────────
const String employeeDocuments = '/api/hr/employees/:id/documents'; // GET, POST
const String documentById = '/api/hr/documents/:docId'; // GET, PUT
const String documentDownload = '/api/hr/documents/:docId/download'; // GET
const String documentArchive = '/api/hr/documents/:docId/archive'; // PATCH

// ───────────── TASKS ─────────────
const String tasks = '/api/hr/tasks'; // GET, POST
const String taskById = '/api/hr/tasks/:id'; // GET, PUT, DELETE

// ───────────── DAILY UPDATES ─────────────
const String dailyUpdates = '/api/hr/daily-updates'; // GET, DELETE
const String dailyUpdatesAll = '/api/hr/daily-updates/all'; // DELETE

// ───────────── REPORTS ─────────────
const String reportAttendance = '/api/hr/reports/attendance'; // GET
const String reportLeaves = '/api/hr/reports/leaves'; // GET

// ───────────── DEPARTMENT CHAT ─────────────
const String chatMessages = '/api/hr/departments/:deptKey/messages'; // GET, POST
const String chatSearch = '/api/hr/departments/:deptKey/messages/search'; // GET
const String chatClear = '/api/hr/departments/:deptKey/messages/clear'; // POST
const String chatMessageById = '/api/hr/departments/:deptKey/messages/:messageId'; // DELETE
const String chatDeleteForMe = '/api/hr/departments/:deptKey/messages/:messageId/delete-for-me'; // PATCH

// ───────────── PAYROLL ─────────────
const String payrollSummary = '/api/hr/payroll/summary'; // GET
const String payrollEmployees = '/api/hr/payroll/employees'; // GET
const String payrollEmployeeById = '/api/hr/payroll/employees/:id'; // GET
const String payrollBatches = '/api/hr/payroll/batches'; // GET
const String payrollDraftBatch = '/api/hr/payroll/batches/draft'; // POST
const String payrollBatchById = '/api/hr/payroll/batches/:batchId'; // GET
const String payrollBatchFinalize = '/api/hr/payroll/batches/:batchId/finalize'; // POST
const String payrollBatchPay = '/api/hr/payroll/batches/:batchId/pay'; // POST
const String payrollPayslip = '/api/hr/payroll/batches/:batchId/employees/:employeeId/payslip'; // GET
const String payrollConflicts = '/api/hr/payroll/conflicts'; // GET
const String payrollConflictResolve = '/api/hr/payroll/conflicts/:conflictId/resolve'; // POST
const String payrollConflictsArchive = '/api/hr/payroll/conflicts/archive-resolved'; // POST
const String payrollPayments = '/api/hr/payroll/payments'; // GET
const String payrollPaymentsSummary = '/api/hr/payroll/payments/summary'; // GET
const String payrollPaymentsHistory = '/api/hr/payroll/payments/history'; // GET
const String payrollPaymentById = '/api/hr/payroll/payments/:id'; // GET
const String payrollPaymentMarkPaid = '/api/hr/payroll/payments/:id/mark-paid'; // POST
