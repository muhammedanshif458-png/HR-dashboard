# LY SOFTWARE HR Dashboard - Reports & Analytics Integration Report

**Date:** 2026-10-16  
**Feature:** Reports & Analytics (Screen 12)  
**Frontend Path:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**Backend Path:** `C:\Users\Admin\Downloads\HrsystemBackend`  
**API Documentation Reference:** `C:\Users\Admin\Downloads\HrsystemBackend\docs\hr_backend_api_coverage.md` & `hr_backend_api_contract.md`  

---

## 1. Executive Summary

This report documents the audit, contract verification, and frontend integration of the **Reports & Analytics** feature for the LY SOFTWARE HR Management Dashboard.

Before integration, the reports screen relied entirely on static hardcoded values and did not communicate with the backend. An audit of the backend repository confirmed that the backend **does not** provide a unified `/api/hr/reports` endpoint, but does provide two specific, mounted aggregation endpoints:
1. `GET /api/hr/reports/attendance`
2. `GET /api/hr/reports/leaves`

All metrics displayed on the Reports screen have been evaluated against these documented endpoints. Supported metrics (such as attendance status summaries, calculated average daily hours, and leave application breakdowns) were wired directly to live server data. Unsupported metrics (such as WFH / Remote Session tracking and server-side PDF generation) have been explicitly designated with unsupported notices and demo tags to prevent misleading users.

---

## 2. API Contract & Endpoint Verification

### Documented & Supported Backend Endpoints

| Endpoint | Method | Query Parameters | Backend Controller & Service | Payload Structure |
|---|---|---|---|---|
| `/api/hr/reports/attendance` | `GET` | `startDate`, `endDate`, `department` | `hrController.getAttendanceReport` -> `hrService.getAttendanceReport` | `{ success: true, data: { statusSummary: [{ _id, count, avgWorkingHours }], departmentSummary: [{ department, status, count, totalHours }] } }` |
| `/api/hr/reports/leaves` | `GET` | `startDate`, `endDate` | `hrController.getLeaveReport` -> `hrService.getLeaveReport` | `{ success: true, data: { statusSummary: [{ _id, count }], typeSummary: [{ _id, count }] } }` |

*Note:* Backend route definitions in `HrsystemBackend/routes/hrRoutes.js` (lines 61–62) mount these under the `/api/hr/reports/` prefix with mandatory `authenticateToken` and `requireRole(['HR', 'ADMIN'])`.

---

## 3. Metric & Chart Mapping Matrix

| Metric / Chart Component | UI Section | Live Server Source | Backend Field(s) | Integration Status & Handling |
|---|---|---|---|---|
| **Total Punches / Overall Rate** | Key Metrics Cards | `GET /api/hr/reports/attendance` | Aggregated sum of `statusSummary[].count` | **Live Integrated** |
| **On-Time Arrival Rate** | Key Metrics Cards | `GET /api/hr/reports/attendance` | `PRESENT` count minus `LATE` count divided by total punches | **Live Integrated** |
| **Average Hours Worked** | Key Metrics Cards | `GET /api/hr/reports/attendance` | Weighted average from `statusSummary[].avgWorkingHours` | **Live Integrated** (previously hardcoded to `'7.8 hrs / day'`) |
| **WFH / Remote Sessions** | Key Metrics Cards | None (`Attendance` model has no `workMode`) | N/A | **Unsupported Metric** (clearly tagged with `Unsupported on Backend (v1.0)`) |
| **Leave Applications Breakdown** | Overview Card | `GET /api/hr/reports/leaves` | `statusSummary`: `APPROVED`, `PENDING`, `REJECTED` | **Live Integrated** |
| **Leave by Type Breakdown** | Overview Card | `GET /api/hr/reports/leaves` | `typeSummary`: `SICK`, `CASUAL`, `ANNUAL` | **Live Integrated** |
| **Department Attendance Table** | Department Breakdown | `GET /api/hr/reports/attendance` | `departmentSummary`: `[{ department, status, count, totalHours }]` | **Live Integrated** (renders live rows or empty indicator) |
| **Export Report Button** | Screen Header | None (no PDF/CSV generator endpoint) | N/A | **Notification Only** (triggers on-screen feedback detailing that export endpoint is not implemented on backend v1.0) |

---

## 4. Unsupported Metrics & Required Backend Capabilities

1. **WFH / Remote Session Metrics:**
   - *Backend Gap:* The backend `Attendance` mongoose schema (`HrsystemBackend/models/Attendance.js`) only tracks `status: ['PRESENT', 'ABSENT', 'HALF_DAY', 'LEAVE']` and `workingHours`. It does not store work mode (`WFH`, `REMOTE`, `OFFICE`).
   - *Required Backend API:* Add `workMode` enum to `Attendance` schema, and update `hrService.getAttendanceReport` aggregation pipeline to group by `workMode`.

2. **Server-Side Report Export (PDF / CSV):**
   - *Backend Gap:* The backend lacks an export endpoint (e.g. `POST /api/hr/reports/export` or `GET /api/hr/reports/attendance/export?format=csv`).
   - *Required Backend API:* Endpoint streaming formatted CSV or PDF buffers.

---

## 5. UI State & Isolation Architecture

1. **Lifecycle & Automatic Loading:**
   - `ReportsView` converted to `StatefulWidget` with `WidgetsBinding.instance.addPostFrameCallback` calling `HRProvider.loadReports()`.
2. **Loading State:**
   - Displays a `CircularProgressIndicator` centered with the text `"Fetching live reports & analytics from server..."`.
3. **Error Isolation & Prevention of Mock Disguise:**
   - When the backend report aggregation fails (e.g., HTTP 500 or network offline), `effectiveAttendanceReport` and `effectiveLeaveReport` return empty dataset objects rather than falling back to mock data.
   - An error banner is rendered with the exact server error message and a functional **Retry Connection** button.
4. **Header Status & Filtering:**
   - An active status badge displays `● LIVE API ACTIVE` when data has been successfully fetched from the backend.
   - A **Refresh** button triggers `loadReports()` directly.
   - Department filter changes reload reports with `department` query parameters.

---

## 6. Files Changed

1. `lib/models/hr_models.dart`:
   - Added typed response models: `AttendanceStatusSummaryItem`, `DepartmentAttendanceSummaryItem`, `AttendanceReportData`, `LeaveStatusSummaryItem`, `LeaveTypeSummaryItem`, and `LeaveReportData`.
2. `lib/services/api_service.dart`:
   - Updated `getAttendanceReport` to call `GET /api/hr/reports/attendance` with `startDate`, `endDate`, and `department` query parameters.
   - Updated `getLeavesReport` to call `GET /api/hr/reports/leaves` with `startDate` and `endDate` query parameters.
   - Implemented error message extraction from backend JSON envelopes.
3. `lib/providers/hr_provider.dart`:
   - Added state flags: `isReportsLoading`, `reportsError`, `hasLoadedApiReports`, `apiAttendanceReport`, `apiLeaveReport`, `reportsDepartmentFilter`, `reportsStartDate`, and `reportsEndDate`.
   - Added `loadReports()`, `setReportsDepartmentFilter()`, and `setReportsDateRange()`.
   - Implemented isolated getters `effectiveAttendanceReport` and `effectiveLeaveReport`.
4. `lib/features/reports/reports_view.dart`:
   - Integrated live metrics, live status badge, loading indicators, error containers with retry, dynamic average hours calculation, live department attendance breakdown table, and explicit unsupported metric notice tags.
5. `test/reports_analytics_api_test.dart`:
   - Created 9 targeted unit and widget tests for API response parsing, HTTP error handling, HRProvider parallel loading, stale mock prevention on failure, department filter reloading, and UI state rendering.

---

## 7. Verification & Test Results

### Static Analysis & Formatting
- `dart format`: Exited with code `0` (all files formatted).
- `flutter analyze --no-fatal-infos`: Exited with code `0` (zero errors, zero warnings across all project files).

### Targeted Reports & Analytics Tests
Command: `flutter test test/reports_analytics_api_test.dart`
- **Result:** `All 9 tests passed!`
- **Exit Code:** `0`
- **Test Scenarios Covered:**
  1. `getAttendanceReport` parses envelope and fields (`statusSummary`, `departmentSummary`, `totalPunches`, `presentCount`, `lateCount`, `avgWorkingHours`).
  2. `getAttendanceReport` handles HTTP 400 with descriptive error message.
  3. `getLeavesReport` parses `statusSummary` and `typeSummary`.
  4. `getLeavesReport` handles HTTP 500 with descriptive error message.
  5. `HRProvider.loadReports()` populates attendance and leave reports and sets `hasLoadedApiReports = true`.
  6. `loadReports()` failure sets `reportsError` and prevents stale mock data from being presented as live.
  7. Filter changes trigger live reloads with query parameters.
  8. `ReportsView` widget renders header, notice banner, metric cards, and unsupported metric labels.
  9. `ReportsView` widget renders error state with working retry button.

### Full Regression Suite
Command: `flutter test`
- **Result:** `01:08 +179: All tests passed!`
- **Exit Code:** `0`
- **Regressions:** `0` (Total test suite increased from 170 to 179 passing tests).

---

## 8. Verification Distinctions & Blockers

- **Mocked Verification:** All 179 Flutter tests run using `MockClient` simulating HTTP requests and responses matching `HrsystemBackend` contracts.
- **Live HTTP Backend Verification:** Not performed because the backend development server is currently offline (`localhost:5000` refused connection). No live verification is claimed without an active backend HTTP daemon.
- **Remaining Blockers:** None for frontend integration. Live backend verification can be executed once MongoDB and the Express backend (`npm run dev`) are booted.
