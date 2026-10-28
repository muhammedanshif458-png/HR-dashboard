# Comprehensive Mock Data and Hardcoded Business Data Audit Report
**Project:** LY SOFTWARE HR Management Dashboard (Flutter Web/Desktop)  
**Client Path:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**Backend Reference:** `C:\Users\Admin\Downloads\HrsystemBackend`  
**Audit Date:** 2026-10-28  
**Audit Scope:** AUDIT ONLY (No source code, database, or API contracts modified)  

---

## Executive Summary

A comprehensive code audit was conducted across the entire Flutter project codebase (`flutter_src`), spanning all screens, widgets, providers, state management, models, repositories, API services, interceptors, and automated test suites. The audit evaluated how dynamic business data is acquired, mapped, and presented in comparison with the live Node.js/Express/MongoDB backend (`HrsystemBackend`).

### Key Audit Findings:
1. **Production UI Source of Truth:**  
   The production UI paths (`_isTestModeSeeded == false`) are largely integrated with the live backend APIs (`ApiService` / `HrsystemBackend`). If the backend API fails or network drops, production screens display honest loading indicators, empty states, or error banners with retry actions rather than silently fabricating mock data.
2. **Co-located Mock Data Fixtures in Production Provider (`hr_provider.dart`):**  
   Over **800 lines of hardcoded mock records** (`_initMockData()`, `staffList`, `attendanceList`, `tasksList`, `leaveRequests`, `payrollList`, `documentsList`, `chatThreads`, `departmentChatThreads`, and `_computeLocalBirthdays()`) physically reside inside `lib/providers/hr_provider.dart`. While currently gated behind `@visibleForTesting` and `enableTestFixtures`, this mock code inflates the production binary, introduces risk of accidental leakage, and causes maintenance overhead.
3. **Hardcoded User Attribution (`admin_1`):**  
   In `lib/models/hr_models.dart`, `lib/features/chat/department_chat_view.dart`, and `lib/providers/hr_provider.dart`, the sender ID `'admin_1'` is hardcoded for unread message calculation, preview formatting, and fallback caller attribution. In live production, real users authenticate with MongoDB ObjectIds (`_currentUser?.id`), causing message ownership checks to fail or misattribute messages.
4. **Unsupported Endpoints & Legacy Chat Methods:**  
   `ApiService.getPrivateMessages()` and `ApiService.sendPrivateMessage()` in `lib/services/api_service.dart` target non-existent endpoints (`/api/hr/chat/messages/:participantId`). The production UI (`chat_view.dart`) already correctly informs users that 1-on-1 direct chat is unsupported and routes them to Department Chat.
5. **Hardcoded Fallback Department Definitions:**  
   `_getDefaultDepartments()` in `hr_provider.dart` defines hardcoded `tech` and `telecalling` structures with synthetic lead names and hardcoded styling constants.

---

## 1. Classification Scheme

Every discovered item is classified into one of the following five standardized categories:

* **Category A:** Mock/dummy business data that should be removed from production.
* **Category B:** Hardcoded business values that should come from the backend or existing configuration.
* **Category C:** Legitimate static UI content that must remain (labels, titles, icons, navigation menus, validation messages, supported dropdown options, design tokens).
* **Category D:** Test-only fixtures and mock data that should remain isolated in tests.
* **Category E:** Legitimate defaults and configuration values that require review before changing.

---

## 2. Complete Inventory of Audit Findings

### Module 1: Provider State Management & Mock Fixtures (`lib/providers/hr_provider.dart`)

| Finding ID | File & Line Reference | Item Description | Category | Production Impact | Required Backend API | Recommended Minimal Change | Dependencies & Risks |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| **F-01** | `lib/providers/hr_provider.dart:351-365` | `enableTestFixtures` flag, `_isTestModeSeeded` boolean, and `seedMockDataForTesting()` method. | **D / A** | No (Gated behind testing flags). | None | Extract mock initialization logic from production provider into a dedicated test-only helper/fixture class in `test/fixtures/`. | Existing unit tests rely on `enableTestFixtures` or `seedTestData: true`. Must preserve test compatibility. |
| **F-02** | `lib/providers/hr_provider.dart:366-499` | Hardcoded `staffList` in `_initMockData()`: Anita Rao, Arjun Desai, Neha Sharma, Vikram Mehta, etc. with salaries (₹85k, ₹75k, etc.) and synthetic dates. | **A / D** | Low in prod; active if `_isTestModeSeeded == true`. | `GET /api/hr/employees` | Move `staffList` seed data to `test/fixtures/mock_staff_fixtures.dart`. In production, keep `staffList = []` initialized. | Automated tests in `widget_test.dart` and `static_data_removal_audit_test.dart` inspect seeded staff. |
| **F-03** | `lib/providers/hr_provider.dart:500-676` | Hardcoded `attendanceList` in `_initMockData()`: Fake punches, break times, and lateness records for October 2026. | **A / D** | Low in prod; active if `_isTestModeSeeded == true`. | `GET /api/hr/attendance` | Relocate to `test/fixtures/mock_attendance_fixtures.dart`. Keep `attendanceList = []` in production. | Unit tests verifying offline attendance filtering rely on these records. |
| **F-04** | `lib/providers/hr_provider.dart:677-739` | Hardcoded `tasksList` in `_initMockData()`: Synthetic tasks ("Refactor API client", "Figma Design Review", etc.). | **A / D** | Low in prod; active if `_isTestModeSeeded == true`. | `GET /api/hr/tasks` | Relocate to `test/fixtures/mock_task_fixtures.dart`. Keep `tasksList = []` in production. | Widget tests checking task state. |
| **F-05** | `lib/providers/hr_provider.dart:740-797` | Hardcoded `leaveRequests` in `_initMockData()`: Synthetic leave applications with fake reasons and medical certificate paths. | **A / D** | Low in prod; active if `_isTestModeSeeded == true`. | `GET /api/hr/leaves` | Relocate to `test/fixtures/mock_leave_fixtures.dart`. Keep `leaveRequests = []` in production. | Tests checking leave filtering in test mode. |
| **F-06** | `lib/providers/hr_provider.dart:798-814` | Hardcoded `dailyUpdatesList` in `_initMockData()`: Synthetic updates ("Integrated attendance...", "Completed 65 telecalling..."). | **A / D** | Low in prod; active if `_isTestModeSeeded == true`. | `GET /api/hr/daily-updates` | Relocate to test fixtures. In production, load strictly from `ApiService.getDailyUpdatesPage()`. | Minimal risk. |
| **F-07** | `lib/providers/hr_provider.dart:816-938` | Hardcoded `chatThreads` in `_initMockChatData()`: Fake 1-on-1 chat conversations between Anita Rao, Arjun Desai, Neha Sharma, Priya Patel. | **A** | None in UI (Direct 1-on-1 chat disabled in `chat_view.dart`), but takes up memory in provider. | None (1-on-1 chat unsupported). | Delete `_initMockChatData()` and remove `chatThreads` mock initialization. | Zero risk to production UI. |
| **F-08** | `lib/providers/hr_provider.dart:939-1034` | Hardcoded `departmentChatThreads` in `_initMockChatData()`: Synthetic messages for Tech & Engineering and Telecalling. | **A / D** | Low (overwritten by `loadDepartmentMessages()`). | `GET /api/hr/departments/:deptKey/messages` | Initialize `departmentChatThreads = []` and populate strictly on `loadDepartmentMessages()`. Relocate mock threads to test fixture. | Ensure department chat tests continue to pass. |
| **F-09** | `lib/providers/hr_provider.dart:1036-1166` | Hardcoded `documentsList` in `_initMockData()`: 7 fake employee documents (Employment Agreement, Degree Cert, Aadhaar, PAN, Medical Cert). | **A / D** | Low in prod; active if `_isTestModeSeeded == true`. | `GET /api/hr/employees/:id/documents` | Relocate to test fixtures. Production already uses `loadEmployeeDocuments(id)` hitting live API. | Preserves document preview and download tests. |
| **F-10** | `lib/providers/hr_provider.dart:1311-1377` | `_computeLocalBirthdays()`: Calculates company birthdays locally from `staffList` when in seeded test mode without tokens. | **A / D** | No impact in prod with token. | `GET /api/hr/birthdays` | Retain as test-only helper; ensure production path strictly relies on `ApiService.getCompanyBirthdays()`. | None. |
| **F-11** | `lib/providers/hr_provider.dart:1384-1414` | `_getDefaultDepartments()`: Returns hardcoded departments for `tech` and `telecalling` with hardcoded styling and count calculations. | **B / E** | Minimal (production calls `GET /api/hr/departments` on init). | `GET /api/hr/departments` | If API fails, retain minimal fallback structure with empty counts, or surface clear error banner. | Must not break department dropdowns if API is unreachable. |
| **F-12** | `lib/providers/hr_provider.dart:2492-2509` | Synchronous `login(String email, String password)`: Fabricates `Staff(id: 'admin_1', name: 'HR Administrator', role: 'HR Manager')`. | **D / B** | **Zero impact on live user login** (production uses `loginWithApi()`). Used in `test/widget_test.dart`. | `POST /api/auth/login` | Annotate `@visibleForTesting` or rename to `loginForTesting()`. | Tests in `test/widget_test.dart` call `hrProvider.login()`. |
| **F-13** | `lib/providers/hr_provider.dart:2988, 3094, 3225` | Fallback user ID `'admin_1'` in message dispatch and read tracking. | **B** | **High in Chat UI**: Messages from real users with MongoDB ObjectId do not match `'admin_1'`. | Session user from `_currentUser.id` | Replace `'admin_1'` with `currentUser?.id ?? ''`. | Fixes unread count and message alignment for live users. |
| **F-14** | `lib/providers/hr_provider.dart:3909-3939` | Metric fallback in `dashboardMetrics` when `_isTestModeSeeded` is true. | **D** | Zero in production (`_isTestModeSeeded == false` returns 0). | `GET /api/hr/dashboard` | Keep zero metrics on non-API production states; isolate fallback in test suites. | Verified clean in production. |
| **F-15** | `lib/providers/hr_provider.dart:4049-4105` | Filtered leave calculation fallback to `leaveRequests` when in seeded test mode. | **D** | Zero in production. | `GET /api/hr/leaves` | Isolate in test environment. | None. |
| **F-16** | `lib/providers/hr_provider.dart:4224-4261` | Filtered attendance calculation fallback to `attendanceList` when in seeded test mode. | **D** | Zero in production. | `GET /api/hr/attendance` | Isolate in test environment. | None. |
| **F-17** | `lib/providers/hr_provider.dart:4390-4508` | Filtered payroll calculation fallback to synthetic gross/deduction math on `staffList` and `attendanceList`. | **D** | Zero in production (returns `const []` or live `apiPayrollRecords`). | `GET /api/hr/payroll/employees` | Isolate in test environment. | None. |

---

### Module 2: Chat & Messaging Models and Views

| Finding ID | File & Line Reference | Item Description | Category | Production Impact | Required Backend API | Recommended Minimal Change | Dependencies & Risks |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| **F-18** | `lib/models/hr_models.dart:1023, 1066, 1071` | Hardcoded `'admin_1'` check in `DepartmentChatThread.unreadCount` and `lastMessagePreview`: `senderId != 'admin_1'` and `msg.senderId == 'admin_1' ? 'You: ' : ...`. | **B** | **High in Live Chat**: Messages sent by authenticated users are not recognized as "You" and inflate unread counts. | None (Derived from current user auth state). | Pass `currentUserId` to getter or compute dynamically: `msg.senderId == currentUserId ? 'You: ' : ...`. | Resolves chat attribution bug in live department channels. |
| **F-19** | `lib/features/chat/department_chat_view.dart:336` | `final callerId = hrProvider.currentUser?.id ?? 'admin_1';` fallback. | **B** | Medium: If user session is uninitialized, falls back to `'admin_1'`. | None | Ensure `currentUser?.id` is always available before entering chat; otherwise disable send. | Low risk. |
| **F-20** | `lib/features/chat/chat_view.dart:128-148` | Explanatory message stating 1-on-1 direct messaging is unsupported by backend REST contract. | **C** | Legitimate UI informational message. | None | Retain as is. Honest representation of backend capabilities. | None. |
| **F-21** | `lib/services/api_service.dart:1423-1453` | Dead API methods `getPrivateMessages()` and `sendPrivateMessage()` querying `/api/hr/chat/messages/:participantId` which does not exist in backend. | **A / E** | None (UI never calls them). | None (Unsupported by backend). | Deprecate or remove dead private message methods to prevent confusion. | None. |

---

### Module 3: Employee Directory, Staff Profile, and Modals

| Finding ID | File & Line Reference | Item Description | Category | Production Impact | Required Backend API | Recommended Minimal Change | Dependencies & Risks |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| **F-22** | `lib/features/dashboard/staff_profile_view.dart:88` | Fallback lookup to `hrProvider.staffList` if employee is not found in `hrProvider.employeeDirectory`. | **B / D** | Low in prod; if employee is not in directory, falls back to mock list if seeded. | `GET /api/hr/employees/:id` | If not found in directory, rely strictly on `hrProvider.selectedStaffDetail` from `GET /api/hr/employees/:id`. | Ensures profile displays fresh backend data. |
| **F-23** | `lib/widgets/modals.dart:134` | Default password hint: `'Leave blank for default (Password@123)'`. | **C / E** | Informational form hint text matching backend validator default. | `POST /api/hr/employees` | Retain as design constant matching backend default. | Must remain aligned with backend `createEmployeeValidator`. |
| **F-24** | `lib/widgets/modals.dart:842-846` | In `showAssignTaskModal`: `staffSource = provider.employeeDirectory.isNotEmpty ? provider.employeeDirectory : provider.staffList;` and `targetStaffId = defaultStaffId ?? ...`. | **B / D** | Low: If directory has not loaded, falls back to `staffList`. | `GET /api/hr/employees` | Remove `provider.staffList` fallback; show loader or prompt to load staff directory. | Avoids assigning tasks to mock employees. |
| **F-25** | `lib/core/department_helper.dart:19-28` | Static list of supported departments: `['Tech', 'Telecalling']`. | **C** | Legitimate architectural design constraint enforcing organizational departments. | None | Retain as supported dropdown constants. | Preserves dropdown integrity across modals and tables. |

---

### Module 4: Base Configuration & Network Layer

| Finding ID | File & Line Reference | Item Description | Category | Production Impact | Required Backend API | Recommended Minimal Change | Dependencies & Risks |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| **F-26** | `lib/core/config.dart:4, 28, 49` | Default API URL: `'http://localhost:5000'`. | **E** | Legitimate default for local development. Overridden via `API_BASE_URL` or `setApiBaseUrl()`. | None | Retain default, with runtime environment variable configuration. | Critical for debug/dev environments. |

---

### Module 5: Test Suites & Fixtures (`flutter_src/test/`)

| Finding ID | File & Line Reference | Item Description | Category | Production Impact | Required Backend API | Recommended Minimal Change | Dependencies & Risks |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| **F-27** | `test/widget_test.dart` (31 test suites) | `MockClient` HTTP response fixtures, synthetic JWT tokens, and sample Staff/Attendance data. | **D** | **Zero production impact** (completely isolated to `flutter test`). | N/A | Retain in test directory. Test fixtures should never leak into production code. | Essential for CI/CD and regression testing. |
| **F-28** | `test/static_data_removal_audit_test.dart` | Tests asserting zero mock data in production mode, zero metrics on uninitialized state, and no silent failure mock injection. | **D** | **Zero production impact**. | N/A | Retain and expand to verify complete extraction of `_initMockData()`. | Guard against accidental reintroduction of mock data. |

---

## 3. Backend API Coverage & Source of Truth Matrix

Every module was verified against the actual backend controllers and routes in `HrsystemBackend`:

| Feature / Domain | Frontend Data Source State | Live Backend Route | Backend Controller Method | Backend Existence | Status & Source of Truth Verification |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **User Authentication** | `ApiService.accessToken`, `_currentUser` | `POST /api/auth/login` | `authController.login` | **VERIFIED** | Live API only. Stores JWT, validates role (`HR`, `SUPER_ADMIN`, `STAFF`). No mock fallbacks in live login. |
| **Token Refresh** | `ApiService.refreshToken` | `POST /api/auth/refresh-token` | `authController.refreshToken` | **VERIFIED** | Live API only. |
| **HR Dashboard Summary** | `apiDashboardMetrics` | `GET /api/hr/dashboard` | `hrController.getDashboard` | **VERIFIED** | Live API only. Zeroes metrics and displays error card if API fails. |
| **Department List** | `departments` | `GET /api/hr/departments` | `hrController.getDepartments` | **VERIFIED** | Live API. Fallback minimal structure exists in provider if network fails. |
| **Department Detail** | `selectedDepartmentDetail` | `GET /api/hr/departments/:deptKey` | `hrController.getDepartmentByKey` | **VERIFIED** | Live API only. Returns null and shows error state on failure. |
| **Company Birthdays** | `todayBirthdays`, `upcomingBirthdays` | `GET /api/hr/birthdays`<br>`GET /api/staff/birthdays` | `hrController.getBirthdays`<br>`staffController.getBirthdays` | **VERIFIED** | Live API. Returns empty list and shows error message on API failure. |
| **Employee Directory** | `employeeDirectory`, `employeeTotal` | `GET /api/hr/employees` | `hrController.getEmployees` | **VERIFIED** | Live API with pagination (`page`, `limit`), search, and filters. Empty state on 0 records. |
| **Add / Edit Employee** | Local form -> API | `POST /api/hr/employees`<br>`PUT /api/hr/employees/:id` | `hrController.createEmployee`<br>`hrController.updateEmployee` | **VERIFIED** | Live API. Errors caught and displayed via `apiStaffError`. |
| **Employee Salary** | Local form -> API | `PUT /api/hr/employees/:id/salary` | `hrController.updateSalary` | **VERIFIED** | Live API. Tracks historical salary updates in database. |
| **Employee Documents** | `documentsList` | `GET /api/hr/employees/:id/documents`<br>`POST /api/hr/employees/:id/documents` | `documentController.getEmployeeDocuments`<br>`documentController.uploadDocument` | **VERIFIED** | Live API. Multipart file upload and secure retrieval. |
| **Document Actions** | Local action -> API | `PUT /api/hr/documents/:docId`<br>`PATCH /api/hr/documents/:docId/archive`<br>`GET /api/hr/documents/:docId/download` | `documentController.replaceDocument`<br>`documentController.archiveDocument`<br>`documentController.downloadDocument` | **VERIFIED** | Live API. |
| **Attendance Logs** | `apiAttendanceRecords`, `attendanceTotal` | `GET /api/hr/attendance` | `hrController.getAttendance` | **VERIFIED** | Live API with date, department, and workMode filters. Scheduled check-in/out mapped authoritatively from backend. |
| **Leave Management** | `apiLeaveRecords`, `leavesTotal` | `GET /api/hr/leaves`<br>`PUT /api/hr/leaves/:id/approve`<br>`PUT /api/hr/leaves/:id/reject` | `hrController.getLeaves`<br>`hrController.approveLeave`<br>`hrController.rejectLeave` | **VERIFIED** | Live API only. Mutation triggers automatic reload. |
| **Payroll Summary & List** | `apiPayrollSummary`, `apiPayrollRecords` | `GET /api/hr/payroll/summary`<br>`GET /api/hr/payroll/employees` | `payrollController.getSummary`<br>`payrollController.getEmployeesPayroll` | **VERIFIED** | Live API only. Returns empty state and zeroed totals on error. |
| **Task Management** | `apiTasksList`, `tasksTotal` | `GET /api/hr/tasks`<br>`POST /api/hr/tasks`<br>`PUT /api/hr/tasks/:id`<br>`DELETE /api/hr/tasks/:id` | `taskController.getTasks`<br>`taskController.createTask`<br>`taskController.updateTask`<br>`taskController.deleteTask` | **VERIFIED** | Live API with pagination. |
| **Daily Work Updates** | `apiDailyUpdatesList`, `dailyUpdatesTotal` | `GET /api/hr/daily-updates`<br>`GET /api/hr/employees/:id/daily-updates` | `dailyUpdateController.getHRDailyUpdates`<br>`dailyUpdateController.getEmployeeDailyUpdates` | **VERIFIED** | Live API with department filtering. |
| **Department Chat** | `departmentChatThreads` | `GET /api/hr/departments/:deptKey/messages`<br>`POST /api/hr/departments/:deptKey/messages` | `chatController.getDepartmentMessages`<br>`chatController.sendDepartmentMessage` | **VERIFIED** | Live API. Hides messages on error. Optimistic UI is backed by immediate API dispatch. |
| **Reports & Analytics** | `apiAttendanceReport`, `apiLeaveReport` | `GET /api/hr/reports/attendance`<br>`GET /api/hr/reports/leaves` | `hrController.getAttendanceReports`<br>`hrController.getLeaveReports` | **VERIFIED** | Live API only. Zero mock fallbacks. Shows retry button on failure. |
| **Staff Portal (Self-Service)** | `staffAttendanceHistory` | `GET /api/staff/attendance`<br>`POST /api/staff/attendance/check-in`<br>`POST /api/staff/attendance/check-out`<br>`POST /api/staff/attendance/break-start`<br>`POST /api/staff/attendance/break-end` | `staffController.getAttendance`<br>`staffController.checkIn`<br>`staffController.checkOut`<br>`staffController.startBreak`<br>`staffController.endBreak` | **VERIFIED** | Live API only. Personal staff punch actions and history. |
| **1-on-1 Direct Chat** | None | `/api/hr/chat/messages/:id` | None | **NOT SUPPORTED** | Correctly disabled in UI. `chat_view.dart` displays unsupported notice. |
| **Announcements & Notifications** | None | `/api/hr/announcements`<br>`/api/hr/notifications` | None | **REMOVED** | Removed from frontend scope; verified 404 in backend. |

---

## 4. Risk Identification and Assessment

1. **Memory & Binary Footprint Risk (High Maintenance Overhead):**  
   `hr_provider.dart` is currently **4,665 lines long**, with over 800 lines dedicated exclusively to legacy mock fixtures (`_initMockData()`, `_initMockChatData()`). While protected by `_isTestModeSeeded`, having mock data embedded inside the core state provider increases cognitive load and risks accidental references in future feature development.
2. **Sender Identification Bug in Chat (`admin_1`) (Functional Risk):**  
   In live chat, comparing incoming message `senderId` against hardcoded string `'admin_1'` (`hr_models.dart:1023, 1066, 1071`) breaks unread message badges and message labeling ("You:") for all authenticated users who have dynamic MongoDB IDs.
3. **Task Modal Fallback to Mock Staff (Edge Case Risk):**  
   In `modals.dart:842`, `showAssignTaskModal` checks `provider.staffList` if `provider.employeeDirectory` is empty. If test fixtures were ever enabled or leaked, a user could theoretically assign a task to a non-existent mock employee.
4. **Dead Network Calls in ApiService (Low Risk):**  
   `ApiService.getPrivateMessages()` and `sendPrivateMessage()` remain compiled in `api_service.dart`. While not called by the current UI, they reference nonexistent endpoints.

---

## 5. Items that Cannot Be Removed Until Backend API Exists

1. **1-on-1 Direct Messaging (`chatThreads`):**  
   Direct peer-to-peer chat requires a new backend model (`DirectMessage`), routes (`/api/hr/chat/private`), and WebSocket / polling infrastructure. Until this backend capability is implemented, the current informative placeholder in `chat_view.dart` must remain.
2. **Dynamic Department Icons and Color Customization:**  
   The backend `GET /api/hr/departments` currently returns `deptKey`, `title`, `description`, `staffCount`, and `activeCount`. Visual design attributes such as `iconName` (`computer`, `headset_mic`) and `colorHex` (`#2563EB`, `#DB2777`) are appropriately maintained in frontend configuration (`DepartmentHelper`).

---

## 6. Phased Implementation Plan

> [!IMPORTANT]
> This plan is proposed for implementation in future phases after formal review and approval. No code changes have been made during this audit phase.

### Phase 1: Fix Active Attribution Bugs (Immediate Priority)
- Update `lib/models/hr_models.dart` to compute `unreadCount` and `lastMessagePreview` using `currentUserId` rather than hardcoded `'admin_1'`.
- Update `lib/features/chat/department_chat_view.dart:336` and `lib/providers/hr_provider.dart:2988` to eliminate `'admin_1'` fallback in production.

### Phase 2: Eliminate Fallback Chains to Mock Staff
- Update `lib/widgets/modals.dart:842` (`showAssignTaskModal`) and `lib/features/dashboard/staff_profile_view.dart:88` to remove fallbacks to `staffList`. If directory data is unavailable, display a clean loading or empty state.

### Phase 3: Extract Mock Fixtures from Production Provider
- Create `test/fixtures/hr_test_fixtures.dart` in `flutter_src/test/`.
- Move `_initMockData()`, `_initMockChatData()`, and all hardcoded lists (`staffList`, `attendanceList`, `tasksList`, `leaveRequests`, `documentsList`, `chatThreads`) out of `lib/providers/hr_provider.dart` into `test/fixtures/`.
- Provide a clean test-only extension `extension HRProviderTestExtension on HRProvider { void seedMockDataForTesting() { ... } }` in the `test/` directory.
- Verify all 31 test suites continue to pass 100%.

### Phase 4: Clean Dead Methods in ApiService
- Safely remove or annotate `@deprecated` on `getPrivateMessages()` and `sendPrivateMessage()` in `lib/services/api_service.dart`.

---

## Conclusion

The LY SOFTWARE HR Dashboard frontend has already transitioned its active production data flows to real backend APIs. The remaining static elements fall into two distinct groups:
1. **Isolated Mock Fixtures in `hr_provider.dart`** that serve unit test suites but clutter the production provider.
2. **Hardcoded User ID References (`'admin_1'`)** in the chat model that need adjustment to dynamically recognize live authenticated user identities.

This concludes the audit. No files or database records have been modified. Standing by for review and approval to proceed with any recommended phase.

