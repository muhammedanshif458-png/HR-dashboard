# LY SOFTWARE HR Management System - Final Pending-Feature Audit Report

**Date of Audit:** October 16, 2026  
**Audited Codebases:**
- **Frontend (Flutter):** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`
- **Backend (Node.js/Express/MongoDB):** `C:\Users\Admin\Downloads\HrsystemBackend`
- **Live Backend Server Host:** `http://localhost:5000` (Node.js daemon, local MongoDB `hr_management`)

---

## Executive Summary & Verification Methodology

This audit was executed by directly inspecting actual source code files, running the backend and Flutter test suites, and executing automated live HTTP requests against the active server daemon on port 5000. 

### Automated Test Suite Results
1. **Backend System Test Suite (`scripts/verifySystem.js`):**
   - **Result:** `35 / 35 verifications PASSED` (Exit Code: 0).
   - Validated auth, RBAC (401/403), employee CRUD, attendance punch-in/out, duplicate check-in prevention (400), leave conflict prevention (409), leave approval, tasks, payroll, department chat, and birthdays.
2. **Backend Birthday Celebration Suite (`scripts/verifyBirthdays.js`):**
   - **Result:** `110 / 110 test assertions PASSED` (Exit Code: 0).
   - Validated edge cases: Dec 30 -> Jan 5 year-end rollover, leap year Feb 29 (Feb 28 in non-leap year vs Feb 29 in leap year), privacy field isolation, query validation (`daysAhead` 0–365), and RBAC boundaries.
3. **Flutter Static Analysis (`flutter analyze --no-fatal-infos`):**
   - **Result:** `0 errors, 0 warnings` (Exit Code: 0).
4. **Flutter Unit & Widget Test Suite (`flutter test`):**
   - **Result:** `183 / 183 tests PASSED` (Exit Code: 0, 1m 14s execution time). All existing tests and 4 newly added focused tests for role-based birthday routing, mock-fallback prevention, and role-based department chat pass.

### Live HTTP Verification Evidence (Executed against `http://localhost:5000`)
- `POST /api/auth/login` (HR Admin: `admin@hrmanagement.com`) -> **HTTP 200 OK** (Role: HR)
- `POST /api/auth/login` (Staff: `staff.audit@hrmanagement.com`) -> **HTTP 200 OK** (Role: STAFF)
- `GET /api/hr/dashboard` -> **HTTP 200 OK** (53ms)
- `GET /api/hr/birthdays?daysAhead=30` (with HR Token) -> **HTTP 200 OK** (8ms, Real API data)
- `GET /api/staff/birthdays?daysAhead=30` (with Staff Token) -> **HTTP 200 OK** (21ms, Real API data)
- `GET /api/hr/birthdays?daysAhead=30` (with Staff Token) -> **HTTP 403 Forbidden** (HR Access Required)
- `GET /api/staff/birthdays?daysAhead=30` (with HR Token) -> **HTTP 403 Forbidden** (Staff Access Required)
- `GET /api/hr/employees?page=1&limit=5` -> **HTTP 200 OK**
- `GET /api/hr/departments` -> **HTTP 200 OK**
- `GET /api/hr/attendance?page=1&limit=5` -> **HTTP 200 OK**
- `GET /api/hr/leaves?page=1&limit=5` -> **HTTP 200 OK**
- `GET /api/hr/payroll/summary?month=10&year=2026` -> **HTTP 200 OK**
- `GET /api/hr/payroll/employees?month=10&year=2026` -> **HTTP 200 OK**
- `GET /api/hr/tasks?page=1&limit=5` -> **HTTP 200 OK**
- `POST /api/hr/departments/tech/messages` (HR Token) -> **HTTP 201 Created**
- `POST /api/staff/departments/tech/messages` (Staff Token) -> **HTTP 201 Created**
- `GET /api/hr/departments/tech/messages` (HR Token) -> **HTTP 200 OK**
- `GET /api/staff/departments/tech/messages` (Staff Token) -> **HTTP 200 OK**
- `PATCH /api/staff/departments/tech/messages/:id/delete-for-me` (Staff Token) -> **HTTP 200 OK**
- `DELETE /api/staff/departments/tech/messages/:id` (Staff Token on own message) -> **HTTP 200 OK**
- `DELETE /api/staff/departments/tech/messages/:id` (Staff Token on HR message) -> **HTTP 403 Forbidden**
- `DELETE /api/hr/departments/tech/messages/:id` (HR Token on any message) -> **HTTP 200 OK**
- `GET /api/hr/reports/attendance` -> **HTTP 200 OK**
- `GET /api/hr/reports/leaves` -> **HTTP 200 OK**
- `GET /api/hr/announcements` -> **HTTP 404 Not Found**
- `GET /api/hr/notifications` -> **HTTP 404 Not Found**
- `GET /api/hr/reports/export` -> **HTTP 404 Not Found**

---

## Screen-by-Screen Audit Matrix

| Screen / Feature | Frontend Status | Backend / API Status | Live Verification Status | Pending Work | Required Next Action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Authentication & Role Routing** (`lib/features/auth/login_view.dart`) | Complete. Validates fields, handles loading, errors (401/403/offline/malformed), parses `accessToken`, stores in `ApiService`, tracks role (`HR`/`STAFF`), routes HR to Dashboard, Staff to Staff Portal. | Complete. `POST /api/auth/login` issues signed JWT tokens (`1d` expiration) with role payload (`HR` or `STAFF`). Protected routes validate Bearer token. | **Verified Live**: HTTP 200 on valid credentials; HTTP 401 on bad credentials; HTTP 422 on malformed body. | None. Fully operational. | No action required. |
| **2. HR Dashboard Overview** (`lib/features/dashboard/hr_dashboard_view.dart`) | Complete. KPI stat cards (Total Staff, Present Today, On Leave, Pending Leaves), Quick Actions, recent attendance/leaves tables, Birthday Celebration section. | Complete. `GET /api/hr/dashboard` returns aggregated counts, quick actions, recent records. | **Verified Live**: HTTP 200 returns valid JSON payload; response parsed without unbound height issues. | None. Live metrics update from MongoDB. | No action required. |
| **3. Company-Wide Birthday Celebrations** (`lib/widgets/birthday_section.dart`) | **Fixed & Verified**. Renders Today's Birthday card and Upcoming (next 30 days) cards. Preserves birth year privacy. `ApiService.getCompanyBirthdays({daysAhead, isStaff})` dynamically selects `/api/staff/birthdays` or `/api/hr/birthdays`. Silent mock fallback removed. | Complete. `GET /api/hr/birthdays` (HR) and `GET /api/staff/birthdays` (Staff) with leap-year handling (Feb 29 -> Feb 28), Dec->Jan rollover, privacy masking. | **Verified Live**: HTTP 200 for HR on `/api/hr/birthdays`; HTTP 200 for Staff on `/api/staff/birthdays`. Mock data is never populated on empty or failed API responses. | None. Defect resolved and verified across HR and Staff portals. | No action required. |
| **4. Employee Directory** (`lib/features/employees/employees_view.dart`) | Complete. Paginated employee table, department filters, search, Add/Edit Employee modal, Status toggle modal, Detail Drawer. | Complete. `GET /api/hr/employees`, `POST /api/hr/employees`, `PUT /api/hr/employees/:id`, `PATCH /api/hr/employees/:id/status`. Auto-generates user account. | **Verified Live**: HTTP 200 on list & get; HTTP 201 on create; HTTP 200 on edit and status toggle. | None. CRUD mutations persist to MongoDB. | No action required. |
| **5. Employee Salary History & Documents** (`lib/widgets/modals.dart`) | Complete. Salary history list, inline salary raise update, document upload (multipart), binary document download, archive document. | Complete. `PUT /api/hr/employees/:id/salary` with audit trail; `POST /api/hr/employees/:id/documents` (Multer), `GET .../download`, `PATCH .../archive`. | **Verified Live**: HTTP 200 on salary update; Multer uploads and downloads binary files directly without JSON corruption. | None. Fully persisted. | No action required. |
| **6. Departments Roster** (`lib/features/departments/departments_view.dart`) | Complete. Roster grouped by Tech, Telecalling, HR, Sales, Design. Live staff counts, KPI badges, member drawers. | Complete. `GET /api/hr/departments` aggregates MongoDB employees by department; `GET /api/hr/departments/:key` returns active members. | **Verified Live**: HTTP 200 returns populated department structures and counts. | Department creation/deletion is not dynamic (departments are defined by organizational enum/set). | Local/staged: Add dynamic department management API if multi-tenant dynamic org units are needed in v2.0. |
| **7. Attendance Management** (`lib/features/attendance/attendance_view.dart`) | Complete. Live paginated attendance table, date picker filter, status filter (PRESENT, ABSENT, HALF_DAY, LEAVE), manual punch modal, search. | Complete. `GET /api/hr/attendance`, `POST /api/hr/attendance/punch`, `PATCH /api/hr/attendance/:id/status`, `POST /api/staff/attendance/check-in`, `check-out`. | **Verified Live**: HTTP 200 on list, HTTP 201 on check-in, duplicate check-in blocked with HTTP 400. | WFH session tracking / Remote work mode is not part of backend `Attendance.js` schema. | WFH metrics are local-only. If backend WFH support is needed, add `workMode` field to `Attendance.js`. |
| **8. Leave Management** (`lib/features/leaves/leave_management_view.dart`) | Complete. Leave summary counters, filter tabs (All, Pending, Approved, Rejected), live action buttons (Approve / Reject), Apply Leave modal. | Complete. `GET /api/hr/leaves`, `PUT /api/hr/leaves/:id/approve`, `PUT /api/hr/leaves/:id/reject`, `POST /api/staff/leaves`. Overlapping leave prevention (409). | **Verified Live**: HTTP 200 on list, HTTP 201 on apply, HTTP 409 on overlap conflict, HTTP 200 on approve. | None. Approval and rejection mutations persist to MongoDB. | No action required. |
| **9. Payroll Management** (`lib/features/payroll/payroll_view.dart`) | Complete. Monthly summary KPI cards, department calendars, employee salary table, inline salary adjustment, payslip modal breakdown. | Complete. `GET /api/hr/payroll/summary`, `GET /api/hr/payroll/employees`, `GET /api/hr/payroll/employees/:id`, `PUT /api/hr/employees/:id/salary`. | **Verified Live**: HTTP 200 returns dynamic calculated payroll expenditure, deductions, and net pay. | Backend v1.0 does not support PDF payslip export or bulk disbursement processing. | Export button is intentionally disabled with informational notice. Server-side PDF generation can be added in v2.0. |
| **10. Task Management** (`lib/features/tasks/tasks_view.dart`) | Complete. Paginated task list, status filter tabs (All, Pending, In-Progress, Done, Cancelled), department filter, create/update/delete task modals. | Complete. `GET /api/hr/tasks`, `POST /api/hr/tasks`, `PUT /api/hr/tasks/:id`, `DELETE /api/hr/tasks/:id`, `PATCH /api/staff/tasks/:id/status`. | **Verified Live**: HTTP 200 on list, HTTP 201 on create, HTTP 200 on update & delete. | 1. `models/Task.js` has no `priority` field (priority is local-only). 2. Daily Work Updates has no backend model (local state only). | If task priority or daily work updates must persist, add `priority` enum to `Task.js` and create `DailyWorkUpdate.js` model. |
| **11. Department Chat** (`lib/features/chat/department_chat_view.dart`) | **Fixed & Verified**. Department channels (Tech, Telecalling, etc.), message feed, input bar, sender bubble formatting, Delete-for-Me, Delete-for-Everyone. Routes to `/api/staff/departments/...` when user is Staff. | Complete. Both `/api/hr/departments/:deptKey/messages` and `/api/staff/departments/:deptKey/messages` supported with GET, POST, DELETE, and PATCH (delete-for-me). | **Verified Live**: HTTP 200 on message list, HTTP 201 on send, HTTP 200 on delete-for-me, HTTP 200 on delete-for-everyone for both HR and Staff roles. RBAC 403 verified. | None for department channels. (Private 1-on-1 chat remains unmounted on backend v1.0). | No action required for department channels. |
| **12. Announcements & Notifications** (`lib/features/announcements/announcements_notifications_view.dart`) | Implemented in UI. Staged announcement feed, department filter, notification listing with mark-as-read, Create Announcement dialog. | **Missing on Backend**. No `Announcement.js` or `Notification.js` models. No mounted routes in `server.js` or `hrRoutes.js`. | **Verified Live**: `GET /api/hr/announcements` -> **HTTP 404**; `GET /api/hr/notifications` -> **HTTP 404**. | Announcements and notifications are stored strictly in local in-memory state in `HRProvider`. Data is lost on page reload. | Requires full backend implementation: Models, Validators, Services, Controllers, and Routes for Announcements and Notifications. |
| **13. Reports & Analytics** (`lib/features/reports/reports_view.dart`) | Complete. Attendance breakdown by status and department, Leave distribution by status and type, date range & department filters. | Complete for attendance & leaves. `GET /api/hr/reports/attendance`, `GET /api/hr/reports/leaves`. | **Verified Live**: HTTP 200 returns live MongoDB aggregation pipeline results. Filters apply server-side. | 1. Server-side PDF/CSV export returns HTTP 404 (handled via UI snackbar). 2. WFH metrics not tracked on backend. | Implement backend CSV/PDF streaming endpoints if file download is needed. |
| **14. Staff Portal Self-Service** (`lib/features/staff/staff_portal_view.dart`) | **Fixed & Verified**. Staff punch in/out, view own attendance history, apply for leave, view personal leave balances, view assigned tasks, view live birthdays. | Complete. `GET /api/staff/dashboard`, `POST /api/staff/attendance/check-in`, `check-out`, `GET /api/staff/leaves`, `POST /api/staff/leaves`, `GET /api/staff/birthdays`. | **Verified Live**: All Staff endpoints return HTTP 200/201 when authenticated with staff JWT. | None. Birthday celebration card now successfully fetches and displays real API data via `/api/staff/birthdays`. | No action required. |

---

## 3. Specific Audit Findings & Resolution Status

1. **Company-Wide Birthday Celebrations (Resolved):**
   - **Previous Defect:** `ApiService.getCompanyBirthdays()` unconditionally called `/api/hr/birthdays`. When authenticated as Staff, request received **HTTP 403 Forbidden** and silently fell back to local mock data.
   - **Resolution:** Added role-aware endpoint selection: `ApiService.getCompanyBirthdays({daysAhead, isStaff})` selects `/api/staff/birthdays` when caller is Staff, and `/api/hr/birthdays` for HR. Removed silent mock data fallback when API requests return empty or fail in API mode.
   - **Live Evidence:** Tested against localhost:5000:
     - HR Token -> `GET /api/hr/birthdays`: **HTTP 200 OK**
     - Staff Token -> `GET /api/staff/birthdays`: **HTTP 200 OK**
     - Staff Token -> `GET /api/hr/birthdays`: **HTTP 403 Forbidden** (Confirmed security boundary)

2. **Department Chat Role-Based Routing (Resolved):**
   - **Previous Defect:** Flutter chat methods only targeted `/api/hr/departments/...`, which would reject Staff users with HTTP 403.
   - **Resolution:** Updated `ApiService.getDepartmentMessages`, `sendDepartmentMessage`, `deleteDepartmentMessageForMe`, and `deleteDepartmentMessageForEveryone` with role-aware path selection (`api/staff/...` vs `api/hr/...`).
   - **Live Evidence:**
     - HR Token -> `POST /api/hr/departments/tech/messages`: **HTTP 201 Created**
     - Staff Token -> `POST /api/staff/departments/tech/messages`: **HTTP 201 Created**
     - Staff Token -> `GET /api/staff/departments/tech/messages`: **HTTP 200 OK**
     - Staff Token -> `PATCH .../delete-for-me`: **HTTP 200 OK**
     - Staff Token -> `DELETE ...` (Own Message): **HTTP 200 OK**
     - Staff Token -> `DELETE ...` (HR Message): **HTTP 403 Forbidden** (RBAC Enforced)
     - HR Token -> `DELETE ...` (HR Authority): **HTTP 200 OK**

3. **Announcements and Notifications Persistence (Pending Backend Work):**
   - **Fact:** Announcements and notifications are **not** persisted in MongoDB. Backend routes `/api/hr/announcements` and `/api/hr/notifications` return **HTTP 404 Not Found**.
   - In Flutter, `announcementsList` and `notificationsList` are held in temporary in-memory Dart state inside `HRProvider`. Data resets on application reload.

4. **Unsupported Features (Confirmed Scope Boundaries):**
   - **PDF/CSV Export:** No backend endpoints exist. Frontend displays an informational notice: *"Server-side export is not supported in Backend API Contract v1.0. Viewing live report metrics on-screen."*
   - **WFH Metrics:** Backend `models/Attendance.js` only tracks `status` (`PRESENT`, `ABSENT`, `HALF_DAY`, `LEAVE`) and working hours. There is no `workMode` field.
   - **Payroll Payslip Export:** Backend calculates payouts but has no PDF rendering engine.
   - **Task Priority:** `models/Task.js` lacks a `priority` field. Priority is local-only.
   - **Daily Work Updates:** No backend model or endpoints exist; staged locally.
   - **Private 1-on-1 Chat:** Flutter references `$baseUrl/hr/chat/messages/$participantId`, but backend only supports department group channels.

---

## 4. Prioritized List of Remaining Tasks

### Priority 1: High (Pending Backend Implementation for Staged Features)
1. **Implement Announcements Backend Persistence:**
   - Create `models/Announcement.js` with fields: `title`, `content`, `category`, `department`, `author` (User ref), `isPinned`, `publishedAt`.
   - Implement `hrController.getAnnouncements`, `createAnnouncement`, `updateAnnouncement`, `deleteAnnouncement`.
   - Mount routes at `/api/hr/announcements` and `/api/staff/announcements`.
   - Connect Flutter `ApiService.getAnnouncements` and `createAnnouncement` to live persistence.

2. **Implement Notifications Backend Persistence:**
   - Create `models/Notification.js` with fields: `recipient` (User ref), `title`, `message`, `type`, `isRead`, `link`.
   - Implement `getNotifications`, `markAsRead`, `markAllAsRead`.
   - Mount routes at `/api/staff/notifications` and `/api/hr/notifications`.

3. **Add Task Priority Schema Support:**
   - Add `priority: { type: String, enum: ['low', 'medium', 'high', 'urgent'], default: 'medium' }` to `models/Task.js` and update `taskValidator.js`.

### Priority 2: Medium (Enhancements & Future Contract Additions)
4. **Server-Side PDF/CSV Export:**
   - Add `pdfkit` / `csv-writer` to `HrsystemBackend` and implement `/api/hr/reports/attendance/export` and `/api/hr/payroll/payslips/:id/download`.
   - Enable Export Report button in `reports_view.dart` and Download Payslip in `payroll_view.dart`.

5. **WFH Session Tracking:**
   - Add `workMode: { type: String, enum: ['OFFICE', 'REMOTE'], default: 'OFFICE' }` to `models/Attendance.js`.
   - Include WFH totals in `hrService.getAttendanceReports`.

6. **Private 1-on-1 Chat Messaging:**
   - Create `models/PrivateChatMessage.js`.
   - Mount `/api/hr/chat/messages/:participantId` and `/api/staff/chat/messages/:participantId`.
