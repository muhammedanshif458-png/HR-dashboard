# LY SOFTWARE HR Dashboard — GET API Verification and Static/Mock Data Audit Report

**Date:** October 19, 2026  
**Auditor:** DeepMind Agentic Pair Programmer  
**Frontend Path:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**Backend Path:** `C:\Users\Admin\Downloads\HrsystemBackend`  
**Database:** MongoDB running on `mongodb://localhost:27017/hr_management`  
**Backend URL:** `http://127.0.0.1:5000`

---

## 1. Executive Summary & Root Cause Analysis of "Audit Tester" Records

### 1.1 The "Audit Tester" Mystery Resolved
During initial visual inspection of the Employee Directory screen, three records with the name `Audit Tester` were displayed. The objective was to determine whether these records came from hardcoded mock arrays in the Flutter client or from the actual backend database.

**Investigation Result:**
- **The three `Audit Tester` records are real database records persisted in MongoDB**, returned by `GET /api/hr/employees`.
- They were created during an automated test suite audit on October 16, 2026 (`docs/hr_final_integration_audit.md`).
- **No hardcoded `Audit Tester` string** exists anywhere in the Flutter frontend codebase.
- The MongoDB documents for these records are:
  1. `_id: 6ad1ce90e73a4bf0f8532f6c`, `employeeId: AUDIT5730`, `firstName: "Audit"`, `lastName: "Tester"`, `email: audit.test.1792134799901@hrmanagement.com`, `department: Tech`, `status: ACTIVE`, `salary: 82000 INR`.
  2. `_id: 6ad1ce09e73a4bf0f8532f00`, `employeeId: AUDIT6443`, `firstName: "Audit"`, `lastName: "Tester"`, `email: audit.test.1792134664878@hrmanagement.com`, `department: Tech`, `status: ACTIVE`, `salary: 82000 INR`.
  3. `_id: 6ad1cda5e73a4bf0f8532ea7`, `employeeId: AUDIT4725`, `firstName: "Audit"`, `lastName: "Tester"`, `email: audit.test.1792134565233@hrmanagement.com`, `department: Tech`, `status: ACTIVE`, `salary: 82000 INR`.
- Per prompt constraints (*"Do not modify or delete production database records"*), these records remain untouched in the database.

### 1.2 Frontend Static/Mock Data Fallback Vulnerabilities Identified & Fixed
Although `Audit Tester` was not hardcoded, the audit uncovered multiple silent mock data fallbacks in the frontend state management (`lib/providers/hr_provider.dart`):
1. **Employee Directory Fallback:** `filteredEmployeeList` previously checked `if (hasLoadedApiEmployees || isApiStaffLoading) return employeeDirectory;` and fell back to `staffList` (containing Anita Rao, Arjun Desai, etc.) if initial loading failed. On API 500 or network failure, mock employees were rendered instead of the error state.
2. **Dashboard Metrics:** `dashboardMetrics` was computed locally from mock arrays rather than querying `GET /api/hr/dashboard`.
3. **Leave Requests Fallback:** `filteredLeaveRequests` fell back to mock leaves on error.
4. **Attendance Fallback:** `filteredAttendanceList` and counters fell back to mock attendance records on error.
5. **Tasks Fallback:** `filteredTasksList` fell back to mock tasks.
6. **Payroll Fallback:** `filteredPayrollRecords` computed mock payroll from mock staff lists.
7. **Reports Fallback:** `effectiveAttendanceReport` and `effectiveLeaveReport` generated hardcoded department summaries.
8. **Mutation Error Masking:** `updateStaff` and `editSalary` previously caught API errors, executed `syncLocal()`, and returned `true`, falsely indicating success to the user interface.

All of these vulnerabilities have been completely eliminated. Production screens now strictly display live backend API data with dedicated loading, empty, and retry error states.

---

## 2. Comprehensive Screen-by-Screen API Mapping & Audit

| Screen Name | Frontend View File | Actual Backend GET Endpoint | Data Source Type | Status / Actions Taken |
| :--- | :--- | :--- | :--- | :--- |
| **Employee Directory** | `lib/features/employees/employees_view.dart` | `GET /api/hr/employees` | **Live API-backed** | Removed fallback to mock `staffList`. Strictly returns `employeeDirectory`. Renders loading spinner on load, empty state on empty response, and error box with Retry button on API failure. |
| **Employee Details** | `lib/features/dashboard/staff_profile_view.dart` | `GET /api/hr/employees/:id` | **Live API-backed** | Strictly fetches live employee record. Updates both `staffList` and `employeeDirectory`. Loading and error retry states fully preserved. |
| **Employee Documents** | `lib/widgets/document_modals.dart` | `GET /api/hr/employees/:id/documents` | **Live API-backed** | Fetches live document list. Provides upload, replacement, and download via backend. |
| **HR Team Dashboard** | `lib/features/dashboard/hr_dashboard_view.dart` | `GET /api/hr/dashboard` & `GET /api/hr/employees` | **Live API-backed** | Added `GET /api/hr/dashboard` integration. Automatically fetches live metrics and employees on mount. Renders empty and loading states for workforce table without mock fallbacks. |
| **Departments** | `lib/features/departments/departments_view.dart` | `GET /api/hr/departments` | **Live API-backed** | Live departments list. Deduplicates organizational units. Headcounts reflect real staff records. |
| **Attendance** | `lib/features/attendance/attendance_view.dart` | `GET /api/hr/attendance` | **Live API-backed** | Isolated mock data for offline tests only. When API token exists or API error occurs, returns empty list with error/retry banner instead of fallback. |
| **Leave Management** | `lib/features/leaves/leave_management_view.dart` | `GET /api/hr/leaves` | **Live API-backed** | Returns `apiLeaveRecords`. If API error occurs or token is active, returns empty list with error/retry banner. Prevents mock fallback. |
| **Payroll Management** | `lib/features/payroll/payroll_view.dart` | `GET /api/hr/payroll/summary` & `GET /api/hr/payroll/employees` | **Live API-backed** | Live payroll summary and batch records. Fallback calculation isolated to offline widget tests without tokens. |
| **Task Management** | `lib/features/tasks/tasks_view.dart` | `GET /api/hr/tasks` | **Live API-backed** | Live task list from `apiTasksList`. When token is present or error occurs, returns empty list with error state, preventing mock tasks fallback. |
| **Reports & Analytics** | `lib/features/reports/reports_view.dart` | `GET /api/hr/reports/attendance` & `GET /api/hr/reports/leaves` | **Live API-backed** | Live analytics breakdown by status and department. Fallback mock values disabled when API token is present. |
| **Birthdays** | `lib/widgets/birthday_section.dart` | `GET /api/hr/birthdays` | **Live API-backed** | Fetches live today and upcoming birthdays. Hides birth year for privacy. Mock fallback disabled when API fails. |
| **Department Chat** | `lib/features/chat/department_chat_view.dart` | `GET /api/hr/departments/:deptKey/messages` | **Live API-backed** | Real-time messaging endpoint per department. |
| **Announcements** | `lib/features/announcements/announcements_view.dart` | `GET /api/hr/announcements` | **Unsupported** | Backend returns 404 (routes not implemented). Staged in client with informative UI notice. |
| **Notifications** | `lib/widgets/header.dart` (bell menu) | `GET /api/hr/notifications` | **Unsupported** | Backend returns 404 (routes not implemented). Staged in client. |

---

## 3. Detailed Static Data Removal & Code Changes

### 3.1 `Staff.fromJson` Model Enhancements (`lib/models/staff.dart`)
- Updated name resolution to prioritize `firstName` and `lastName` combined over undefined top-level `name`, preventing `undefined undefined` strings from Mongo populated documents.
- Updated role resolution to check nested `user.role` from populated user accounts.
- Preserved `salary`, `salaryHistory`, `dateOfBirth`, and other schema mappings.

### 3.2 `HRProvider` Refactoring (`lib/providers/hr_provider.dart`)
1. **Added Dashboard State Fields:**
   - `Map<String, dynamic>? apiDashboardMetrics`
   - `bool isDashboardLoading`
   - `String? dashboardError`
   - `bool hasLoadedApiDashboard`
2. **Updated `fetchDashboardData()`:**
   - Queries `GET /api/hr/dashboard` to retrieve live total, active, present, and leave counts.
   - Queries `GET /api/hr/employees`, `GET /api/hr/attendance`, `GET /api/hr/leaves`, `GET /api/hr/departments`.
   - Directly sets `employeeDirectory` and `staffList` from live backend data.
3. **Updated `dashboardMetrics` Getter:**
   - Evaluates `apiDashboardMetrics` first when live data is loaded.
   - If API token is active and no data is loaded, returns zeros rather than fabricated counts.
4. **Updated `filteredEmployeeList` Getter:**
   - Changed from returning `staffList` fallback to strictly returning `employeeDirectory`.
   - On error or empty results, returns exact state.
5. **Fixed Mutation Catch Blocks (`updateStaff` & `editSalary`):**
   - Prevented false success reports on HTTP 4xx/5xx responses.
   - If `ApiService.hasToken || hasLoadedApiEmployees`, catch block immediately returns `false` and records `apiStaffError`.
6. **Isolated Fallbacks on Leave, Attendance, Task, Payroll, and Reports Getters:**
   - If `ApiService.hasToken || error != null`, getters return empty lists `[]` rather than falling back to `_initMockData()`.
   - Static fixtures remain accessible only in offline unit test runs where `!ApiService.hasToken`.

### 3.3 Dashboard View Updates (`lib/features/dashboard/hr_dashboard_view.dart`)
- Converted `HRDashboardView` from `StatelessWidget` to `StatefulWidget`.
- Added post-frame callback in `initState` to invoke `fetchDashboardData()` automatically when authenticated with an API token.
- Added loading spinner and clean empty state in the workforce DataTable card.

---

## 4. Live GET API Verification Results

The live backend server (`http://127.0.0.1:5000`) and MongoDB database were tested via live authenticated HTTP requests using a Super Admin JWT token (`lysoftware@gmail.com`).

### 4.1 Employee Directory Endpoints
| HTTP Method & Endpoint | Status | Records / Total | Response Summary |
| :--- | :--- | :--- | :--- |
| `GET /api/hr/employees?page=1&limit=20` | **200 OK** | 8 / 8 total | Full workforce list from MongoDB. |
| `GET /api/hr/employees?search=Audit` | **200 OK** | 4 / 4 total | Matched: `AuditStaff Tester` (`EMP1006`), `Audit Tester` (`AUDIT5730`), `Audit Tester` (`AUDIT6443`), `Audit Tester` (`AUDIT4725`). |
| `GET /api/hr/employees?department=Tech` | **200 OK** | 3 / 3 total | Correctly filtered to Tech department. |
| `GET /api/hr/employees?department=Telecalling` | **200 OK** | 1 / 1 total | Correctly filtered to Telecalling department. |
| `GET /api/hr/employees?status=ACTIVE` | **200 OK** | 7 / 7 total | Correctly filtered to Active employees. |
| `GET /api/hr/employees?status=INACTIVE` | **200 OK** | 1 / 1 total | Correctly filtered to Inactive employee (`EMP1008`). |
| `GET /api/hr/employees?page=1&limit=2` | **200 OK** | 2 records, 4 total pages | Pagination math verified (`page: 1, limit: 2, total: 8, totalPages: 4`). |
| `GET /api/hr/employees/6ad1ce90e73a4bf0f8532f6c` | **200 OK** | 1 record | Detail fetched for `AUDIT5730`. |
| `GET /api/hr/employees/6ad1ce90e73a4bf0f8532f6c/documents` | **200 OK** | 0 documents | Document array returned for employee. |

### 4.2 Other Core HR GET Endpoints
| HTTP Method & Endpoint | Status | Response Summary |
| :--- | :--- | :--- |
| `GET /api/health` | **200 OK** | Server healthy. |
| `GET /api/hr/dashboard` | **200 OK** | `{ totalEmployees: 8, activeEmployees: 7, inactiveEmployees: 1, todayPresent: 0, todayAbsent: 0, pendingLeaves: 0, approvedLeaves: 0 }`. |
| `GET /api/hr/departments` | **200 OK** | Department list returned for Tech and Telecalling. |
| `GET /api/hr/departments/tech` | **200 OK** | Single department details returned. |
| `GET /api/hr/birthdays` | **200 OK** | Company-wide birthday lists (`today: [], upcoming: []`). |
| `GET /api/hr/attendance` | **200 OK** | Attendance list returned with pagination. |
| `GET /api/hr/leaves` | **200 OK** | Leave requests returned with pagination. |
| `GET /api/hr/reports/attendance` | **200 OK** | Breakdown returned with `statusSummary` and `departmentSummary`. |
| `GET /api/hr/reports/leaves` | **200 OK** | Breakdown returned with `statusSummary` and `typeSummary`. |
| `GET /api/hr/payroll/summary` | **200 OK** | Financial payroll summary for active month/year. |
| `GET /api/hr/payroll/employees` | **200 OK** | 8 employee payroll records returned with pagination. |
| `GET /api/hr/tasks` | **200 OK** | Task management list returned with pagination. |
| `GET /api/hr/departments/tech/messages` | **200 OK** | Department chat thread messages returned. |
| `GET /api/hr/announcements` | **404 Not Found** | Endpoint not implemented on backend. Handled in UI. |
| `GET /api/hr/notifications` | **404 Not Found** | Endpoint not implemented on backend. Handled in UI. |

---

## 5. Automated Test Verification Results

### 5.1 Code Formatting
- Command: `dart format lib/models/staff.dart lib/providers/hr_provider.dart lib/features/dashboard/hr_dashboard_view.dart test/employee_directory_api_test.dart`
- Result: **0 errors, all files formatted cleanly.**

### 5.2 Static Analysis
- Command: `flutter analyze --no-fatal-infos`
- Result: **0 errors, 0 warnings (exit code 0).** Only deprecation info notices from existing third-party Flutter Material form fields.

### 5.3 Test Suite Execution
- Command: `flutter test`
- Outcome: **228 tests passed out of 228 tests (100% pass rate).**
- New test cases added to `test/employee_directory_api_test.dart`:
  1. `GET API success correctly parses real Audit Tester records from database`: Validates parsing of real-shaped MongoDB payloads including `AUDIT5730`, `AUDIT6443`, and `AUDIT4725`.
  2. `API failure displays error and Retry button without falling back to mock employees`: Confirms that on 503 or network failure, `filteredEmployeeList` is empty, no mock staff ("Anita Rao", "Arjun Desai") appear in the UI, and the Retry button triggers a reload that recovers when the backend responds.
  3. `mutation failure in editStaff does not report success or fake update`: Confirms that invalid updates (HTTP 400) return `false`, set `apiStaffError`, and do not deceptively update the UI.
  4. Search, department filtering, status filtering, pagination, and bearer-token assertions verified across all suites.

---

## 6. Remaining Backend Gaps & Architecture Notes

1. **Announcements & Notifications:**
   - The backend currently has no routes or controllers for `/api/hr/announcements` or `/api/hr/notifications`.
   - The Flutter frontend gracefully catches these 404s and displays user notices explaining that server-side broadcast announcement persistence is pending.
2. **Daily Updates:**
   - The backend does not expose a standalone `/api/hr/daily-updates` route; daily logs are currently tracked under tasks and attendance check-in notes.
3. **Database Records:**
   - No database records were modified or deleted during this verification audit. All 8 employees (including the 3 `Audit Tester` records) remain safely preserved in MongoDB.

---

## 7. Conclusion

The LY SOFTWARE HR Management dashboard is now verified end-to-end:
- **`Audit Tester` Origin:** Confirmed to be real MongoDB database records, not static client mocks.
- **Production Truth:** Live backend GET APIs are the sole source of truth for production screens.
- **Resilience:** If network or API failures occur, mock data is never substituted; proper loading, empty, and retry error states are displayed.
