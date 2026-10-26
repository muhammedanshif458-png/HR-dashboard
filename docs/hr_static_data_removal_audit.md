# LY SOFTWARE HR Management — Static Data Removal & Backend Source of Truth Audit

## Executive Summary

A comprehensive, project-wide audit of the **LY SOFTWARE HR Management Flutter Dashboard** (`C:\Users\Admin\Downloads\HR-dashboard\flutter_src`) was conducted against the backend service (`C:\Users\Admin\Downloads\HrsystemBackend`) and API contract (`docs/hr_backend_api_contract.md`).

All static, mock, dummy, and fabricated fallback data have been eliminated from production execution paths. Backend REST APIs are now the sole source of truth for business data across every production screen. When backend data is loading, empty, or fails, screens honestly present loading indicators, clear empty states, or error messages with retry actions instead of falling back to fabricated records.

Test fixtures have been strictly isolated to automated testing environments via `HRProvider.enableTestFixtures`, ensuring production code cannot inadvertently display mock data.

---

## 1. Inventory of Static / Mock Data Sources Discovered & Removed

During the project-wide code audit, static data and fabricated business records were discovered primarily in `lib/providers/hr_provider.dart` and certain UI screens:

| Feature / Domain | File & Location | Discovered Static Data | Production Resolution |
| :--- | :--- | :--- | :--- |
| **Provider Initialization** | `lib/providers/hr_provider.dart:227` | Unconditional call to `_initMockData()` in default constructor, seeding fake employees, attendance, tasks, leaves, and documents on app start. | Removed from production constructor. Provider initializes with empty collections (`staffList = []`, `departments = []`, `attendanceList = []`, `tasksList = []`, `leaveRequests = []`, `documentsList = []`). Gated behind `enableTestFixtures` for isolated unit tests. |
| **Authentication Fallback** | `lib/providers/hr_provider.dart:2100` | Synchronous `login()` method hardcoded name to `"Anita Rao"`. | Removed hardcoded employee name. Defaults to `"HR Administrator"`, and live production login uses `loginWithApi()` with backend token and user data. |
| **Department Chat Fallback** | `lib/providers/hr_provider.dart:2543` | `sendDepartmentMessage()` defaulted sender name to `"Anita Roy (HR Manager)"`. | Replaced with `_currentUser?.name ?? 'HR Administrator'`. |
| **Department Cards** | `lib/providers/hr_provider.dart:1200` | `_getDefaultDepartments()` had hardcoded department leads and fallback lists. | Removed lead names; `departments` list starts empty and populates strictly from `GET /api/hr/departments`. Failure sets `departmentsError` and shows error banner with retry. |
| **Department Details** | `lib/providers/hr_provider.dart:1240` | `fetchDepartmentDetail(deptKey)` fell back to synthetic local Department object if API request failed. | Removed synthetic fallback. On error, `selectedDepartmentDetail` is set to `null` and `departmentDetailError` is populated. |
| **Dashboard Metrics** | `lib/providers/hr_provider.dart:1010, 1870` | Fallback getter `dashboardMetrics` returned static calculations based on mock staff when `apiDashboardMetrics` was absent. | Removed static calculations. When no API data has loaded or when the request fails, metrics return zeroed/honest metrics (`totalStaff: 0`, `presentToday: 0`, `onLeaveToday: 0`, `remoteToday: 0`), and an error banner is displayed. |
| **Birthdays List** | `lib/services/api_service.dart:1210`, `hr_provider.dart:1077` | Swallowing non-200 responses and computing local birthdays from mock staff list in production. | `ApiService.getCompanyBirthdays()` flags HTTP errors. `fetchBirthdays()` clears birthday lists to empty and sets `birthdaysError`. Production screens render empty or error state. |
| **1-on-1 Direct Chat** | `lib/features/chat/chat_view.dart` | Mock chat conversations (`chatThreads`) between Anita Rao, Arjun Desai, Neha Sharma, and Priya Patel with hardcoded dummy messages. | Rewritten `chat_view.dart` to clearly state that 1-on-1 direct messaging is currently unsupported by the backend API contract and directs users to Department Chat. |
| **Attendance Fallback** | `lib/providers/hr_provider.dart:1900` | Filtered attendance queries fell back to `attendanceList` with hardcoded date `'2026-10-12'`. | Removed static attendance list fallback. All filtered queries operate on `apiAttendanceRecords` fetched from `GET /api/hr/attendance`. |
| **Leave Management Fallback** | `lib/providers/hr_provider.dart:1890` | Filtered leave queries fell back to `leaveRequests` mock list. | Removed mock list fallback. All leave lists and counts operate on `apiLeaveRecords` from `GET /api/hr/leaves`. |
| **Payroll Calculations** | `lib/providers/hr_provider.dart:1920` | `effectivePayrollSummary` generated synthetic salary aggregates from local mock staff list. | Removed synthetic payroll aggregates. Production returns zero metrics when API data is not loaded or on API error. |
| **Reports & Analytics** | `lib/providers/hr_provider.dart:1940` | `effectiveAttendanceReport` and `effectiveLeaveReport` returned hardcoded department ratios (Tech: 2, Telecalling: 3). | Removed hardcoded department counts. Returns empty report structures with honest error banners when backend fails. |
| **Staff Profile Cross-Queries** | `lib/features/dashboard/staff_profile_view.dart` | Queried local `attendanceList`, `tasksList`, and `leaveRequests` directly for employee tabs. | Updated to strictly query API-backed records (`apiAttendanceRecords`, `apiTasksList`, `apiLeaveRecords`). |
| **Mutation Silent Success** | `lib/providers/hr_provider.dart` | `addStaff`, `updateStaff`, `editSalary`, `approveLeave`, `rejectLeave`, `assignTask`, `updateTaskStatus`, `deleteTask`, `uploadDocument`, `replaceDocument`, `archiveDocument` returned `true` (fabricated success) on API failure by mutating local state. | Removed fabricated success in production. Errors are caught, error properties are populated, and methods return `false`. Data is reloaded from backend on success. |

---

## 2. Production Source of Truth & Endpoint Mapping

Every supported screen is bound to documented backend endpoints through `ApiService`:

| Screen / Feature | HTTP Method | Endpoint URL | Source of Truth State | Mutations & Post-Mutation Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Authentication** | `POST` | `/api/auth/login` | `ApiService.accessToken`, `_currentUser` | Stores JWT token, validates role (`HR`, `HR MANAGER`, `ADMIN`, `SUPER_ADMIN`), routes to HR dashboard. |
| **HR Dashboard** | `GET` | `/api/hr/dashboard` | `apiDashboardMetrics` | Triggers parallel load of staff directory, attendance, tasks, leaves, and birthdays. Displays retry banner on failure. |
| **Company Birthdays** | `GET` | `/api/hr/birthdays?daysAhead=30` | `todayBirthdays`, `upcomingBirthdays` | Supports both HR and Staff endpoints (`/api/staff/birthdays`). Displays empty state if no birthdays upcoming. |
| **Employee Directory** | `GET` | `/api/hr/employees` | `employeeDirectory`, `employeeTotal` | `POST /api/hr/employees` (add), `PUT /api/hr/employees/:id` (edit), `PUT /api/hr/employees/:id/salary` (salary), `DELETE /api/hr/employees/:id` (deactivate). Success triggers `loadEmployeeDirectory()`. |
| **Employee Details** | `GET` | `/api/hr/employees/:id` | `selectedStaffDetail` | `PUT /api/hr/employees/:id`, `PUT /api/hr/employees/:id/salary`. Refreshes details on success. |
| **Employee Documents** | `GET` | `/api/hr/employees/:id/documents` | `documentsList` | `POST /api/hr/employees/:id/documents` (upload), `PUT /api/hr/documents/:id` (replace), `PATCH /api/hr/documents/:id/archive` (archive). Success triggers `loadEmployeeDocuments(id)`. |
| **Departments** | `GET` | `/api/hr/departments` | `departments` | `GET /api/hr/departments/:deptKey` (detail modal). Shows loading skeleton and retry button on network error. |
| **Attendance Management** | `GET` | `/api/hr/attendance` | `apiAttendanceRecords` | Paginated query with date/department/status filters. Shows error card with Retry button on API failure. |
| **Leave Management** | `GET` | `/api/hr/leaves` | `apiLeaveRecords`, `leavesTotal` | `PUT /api/hr/leaves/:id/approve` (approve), `PUT /api/hr/leaves/:id/reject` (reject). Success triggers `loadLeaves(page)`. |
| **Payroll Management** | `GET` | `/api/hr/payroll/summary`<br>`GET /api/hr/payroll/employees` | `apiPayrollSummary`, `apiPayrollRecords` | `GET /api/hr/payroll/employees/:id` for detailed payslip breakdown. Failure shows error banner and zeroed totals. |
| **Task Management** | `GET` | `/api/hr/tasks` | `apiTasksList`, `tasksTotal` | `POST /api/hr/tasks` (create), `PUT /api/hr/tasks/:id` (status/edit), `DELETE /api/hr/tasks/:id` (delete). Success triggers `loadTasks(page)`. |
| **Department Chat** | `GET` | `/api/hr/departments/:deptKey/messages` | `departmentChatThreads` | `POST /api/hr/departments/:deptKey/messages` (send), `PATCH .../hide` (delete for me), `DELETE .../delete` (delete for everyone). Reloads messages on mutation. |
| **Reports & Analytics** | `GET` | `/api/hr/reports/attendance`<br>`GET /api/hr/reports/leaves` | `apiAttendanceReport`, `apiLeaveReport` | Shows real backend aggregates. Shows error state with retry if analytics service fails. |

---

## 3. Unsupported Features & Intentional Scope Exclusions

1. **1-on-1 Direct Chat:**
   - **Status:** Unsupported by backend REST contract. The backend only implements department channels (`/api/hr/departments/:deptKey/messages` and `/api/staff/departments/:deptKey/messages`).
   - **Frontend UI Behavior:** `lib/features/chat/chat_view.dart` has been modified to display an honest informational card explaining that 1-on-1 direct messaging is not supported by the backend, with a direct button to navigate to Department Chat.
2. **Announcements & Notifications:**
   - **Status:** Intentionally removed from product scope as requested.
   - **Verification:** Verified that `/api/hr/announcements` and `/api/hr/notifications` return 404, and no routes, widgets, badges, or bell icons remain in the frontend application.
3. **Historical Audit Database Records (`AUDIT5730`, `AUDIT6443`, `AUDIT4725`):**
   - **Status:** Preserved intact in MongoDB. As instructed, no database records were modified or deleted during this frontend cleanup.

---

## 4. UI State Handling Verification

Every production screen implements the standard four-state UI lifecycle:

1. **Loading State:** Centered `CircularProgressIndicator` or linear loader prevents user interaction during network fetches.
2. **Success State:** Populates widgets strictly with data received from backend JSON responses.
3. **Empty State:** When the backend returns an empty array (`[]` or `total: 0`), screens render dedicated empty illustrations/cards (e.g. "No employees found", "No attendance records found", "No tasks found") rather than injecting fallback mock records.
4. **Error & Retry State:** When network fails or server responds with 4xx/5xx, screens display user-friendly error messages accompanied by a "Retry" or "Reload" action that re-invokes the backend endpoint.

---

## 5. Automated Test Suite Results

The complete Flutter test suite was executed:

```
flutter test
```

### Result:
- **Total Test Files:** 16
- **Total Tests Executed:** 244
- **Passed:** 244
- **Failed:** 0
- **Execution Time:** ~40 seconds

### Key Test Coverage Areas:
- `test/static_data_removal_audit_test.dart` (24 new tests):
  - Zero-mock initial state in production mode.
  - Zero metrics and empty collections when API data has not loaded.
  - No static fallback after API failure across all features (dashboard, employees, attendance, leaves, payroll, reports, department detail, birthdays).
  - Prevention of fabricated success messages on mutation failures (`addStaff`, `updateStaff`, `editSalary`, `approveLeave`, `rejectLeave`, `assignTask`, `updateTaskStatus`, `deleteTask`, `uploadDocument`, `replaceDocument`, `archiveDocument`).
  - Automatic API refresh triggered on successful mutations.
- `test/dashboard_api_test.dart` (12 tests): verifies error handling, authentication role routing, and absence of mock data fallback.
- `test/departments_api_test.dart` (23 tests): verifies department list, department detail, and error/empty/retry UI states.
- `test/department_chat_api_test.dart` (15 tests): verifies message fetch, dispatch, deletion permissions, and empty thread isolation.
- `test/employee_directory_api_test.dart`, `test/leave_management_api_test.dart`, `test/payroll_management_api_test.dart`, `test/task_management_api_test.dart`, `test/reports_analytics_api_test.dart`, `test/attendance_api_test.dart`, `test/widget_test.dart`.

### Static Analysis:
```
flutter analyze --no-fatal-infos
```
- **Errors:** 0
- **Warnings:** 0
- **Status:** Clean.

---

## 6. Live Backend HTTP Verification Results

Live end-to-end HTTP integration was verified against the running backend (`http://127.0.0.1:5000` connected to MongoDB `hr_management`):

```
node verifyLiveE2EIntegration.js
```

### Summary of Live Checks (49 / 49 Passed):
- **Server Health:** `GET /api/health` -> HTTP 200
- **Authentication & RBAC:**
  - Super Admin login -> HTTP 200 (Role: SUPER_ADMIN)
  - Invalid credentials -> HTTP 401
  - Unauthenticated request -> HTTP 401
  - Admin access on Staff endpoint -> HTTP 403
- **Dashboard:** `GET /api/hr/dashboard` -> HTTP 200
- **Employee Directory & Mutations:**
  - `GET /api/hr/employees` -> HTTP 200 (Found 11 employees, including historical audit records)
  - `POST /api/hr/employees` -> HTTP 201 (Created ephemeral test employee)
  - `GET /api/hr/employees/:id` -> HTTP 200 (Verified persistence)
  - `PUT /api/hr/employees/:id` -> HTTP 200 (Updated designation)
  - `PATCH /api/hr/employees/:id/status` -> HTTP 200 (Status change)
  - `PUT /api/hr/employees/:id/salary` -> HTTP 200 (Salary updated to 85,000 INR with history)
- **Attendance:**
  - `GET /api/hr/attendance` -> HTTP 200
  - `POST /api/staff/attendance/check-in` -> HTTP 201
  - `POST /api/staff/attendance/check-out` -> HTTP 200
  - `GET /api/staff/attendance` -> HTTP 200
- **Leave Management:**
  - `GET /api/hr/leaves` -> HTTP 200
  - `POST /api/staff/leaves` -> HTTP 201 (Created leave request)
  - `GET /api/hr/leaves/:id` -> HTTP 200 (Status: PENDING)
  - `PUT /api/hr/leaves/:id/approve` -> HTTP 200
  - `GET /api/hr/leaves/:id` -> HTTP 200 (Confirmed Status: APPROVED)
- **Payroll:**
  - `GET /api/hr/payroll/summary` -> HTTP 200
  - `GET /api/hr/payroll/employees` -> HTTP 200
  - `GET /api/hr/payroll/employees/:id` -> HTTP 200
- **Task Management:**
  - `GET /api/hr/tasks` -> HTTP 200
  - `POST /api/hr/tasks` -> HTTP 201
  - `PUT /api/hr/tasks/:id` -> HTTP 200 (Status: in-progress)
  - `DELETE /api/hr/tasks/:id` -> HTTP 200 (Soft delete)
  - `GET /api/hr/tasks/:id` -> HTTP 404 (Confirmed deleted)
- **Department Chat:**
  - `GET /api/hr/departments/tech/messages` -> HTTP 200
  - `POST /api/hr/departments/tech/messages` -> HTTP 201
  - `DELETE /api/hr/departments/tech/messages/:id` -> HTTP 200
- **Reports & Analytics:**
  - `GET /api/hr/reports/attendance` -> HTTP 200
  - `GET /api/hr/reports/leaves` -> HTTP 200
- **Company Birthdays:**
  - `GET /api/hr/birthdays` -> HTTP 200
- **Scope Verification:**
  - `GET /api/hr/announcements` -> HTTP 404 (Expected unsupported)
  - `GET /api/hr/notifications` -> HTTP 404 (Expected unsupported)
- **Employee Documents:**
  - `GET /api/hr/employees/:id/documents` -> HTTP 200
- **Cleanup:**
  - `DELETE /api/hr/employees/:id` -> HTTP 200 (Ephemeral test employee deactivated)

---

## 7. Remaining Work & Backend Recommendations

1. **1-on-1 Direct Messaging Endpoint:**
   - If 1-on-1 messaging between staff and HR is desired in future releases, the backend team must specify and implement direct conversation endpoints (e.g. `GET /api/hr/chat/conversations` and `POST /api/hr/chat/conversations/:id/messages`). The Flutter client currently safely routes users to Department Chat.
2. **Database Hygiene:**
   - The 3 test employees (`AUDIT5730`, `AUDIT6443`, `AUDIT4725`) created during previous testing cycles remain safely stored in MongoDB and are marked `ACTIVE`. If the customer wishes to clean these up from the database, a database administrator can execute a MongoDB query to set their status to `INACTIVE` or archive them.
