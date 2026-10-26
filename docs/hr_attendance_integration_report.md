# LY SOFTWARE HR Management — Screen 6: HR Attendance Integration Report

**Date:** October 15, 2026  
**Project:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**API Reference:** `C:\Users\Admin\Downloads\HrsystemBackend\docs\hr_backend_api_contract.md`  
**Backend Reference:** `C:\Users\Admin\Downloads\HrsystemBackend`  

---

## 1. Executive Summary

Screen 6 (**HR Attendance Management**) of the LY SOFTWARE HR Management Flutter dashboard has been integrated with the documented backend HR Attendance API endpoints. The integration adheres strictly to the backend API contract, supports server-side pagination, date filtering, employee filtering, and status filtering, safely handles ISO date/time and populated employee records, and introduces responsive UI states (loading, empty, error with retry, live sync indicator, and pagination footer).

---

## 2. API Endpoints & Contract Adherence

Only documented HR attendance endpoints from the API contract are utilized. Staff self-service endpoints (`/api/staff/attendance/check-in`, `/api/staff/attendance/check-out`) were deliberately excluded from HR listing functionality.

| Endpoint | Method | Auth | Query Parameters | Description |
|---|---|---|---|---|
| `/api/hr/attendance` | `GET` | HR Bearer Token | `page`, `limit`, `employeeId`, `startDate`, `endDate`, `status` | Fetches paginated attendance records with populated employee details. |
| `/api/hr/attendance/:employeeId` | `GET` | HR Bearer Token | `page`, `limit`, `startDate`, `endDate` | Fetches historical attendance records scoped to a specific employee identifier. |

### Envelope & Field Mapping

Backend response envelope:
```json
{
  "success": true,
  "message": "Attendance records fetched successfully",
  "data": [
    {
      "_id": "67...a1",
      "employee": {
        "_id": "67...e1",
        "employeeId": "EMP1001",
        "firstName": "Anita",
        "lastName": "Rao",
        "department": "Tech",
        "designation": "Lead HR Manager"
      },
      "date": "2026-10-15T00:00:00.000Z",
      "checkIn": "2026-10-15T09:00:00.000Z",
      "checkOut": "2026-10-15T17:30:00.000Z",
      "status": "PRESENT",
      "workingHours": 8.5,
      "remarks": "On-time punch"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

- **Employee Identification:** Extracted from populated `employee.employeeId` (e.g. `EMP1001`) with fallback to `employee._id`.
- **Date/Time Handling:** Converted to local time via `.toLocal()` and formatted to `hh:mm a` for display.
- **Duration:** Computed from `workingHours` (e.g. `8.5` -> `"8h 30m"`).
- **Status Normalization:**
  - `PRESENT` with `checkOut != null` -> `"Checked Out"`
  - `PRESENT` with active punch -> `"Present"`
  - `HALF_DAY` -> `"Late"`
  - `ABSENT` -> `"Absent"`
  - `LEAVE` -> `"On Leave"`
- **Backend Status Filter Mapping:**
  - `"Present"` / `"Checked Out"` -> query param `status=PRESENT`
  - `"Late"` -> query param `status=HALF_DAY`
  - `"Absent"` -> query param `status=ABSENT`
  - `"On Leave"` -> query param `status=LEAVE`
  - `"all"` -> omitted from query params

---

## 3. UI States & User Experience

1. **Initial / Async Loading State:**
   - Triggers `loadAttendance()` on post-frame callback in `AttendanceView.initState` if live data is not yet loaded.
   - Replaces the table with a centered `CircularProgressIndicator` and status message `"Fetching attendance records from server..."`.
2. **Sync Button Interaction:**
   - "Sync Attendance" button in the header triggers `hrProvider.loadAttendance()`.
   - Displays an inline spinner and disables repeated clicks during inflight requests.
3. **Empty State:**
   - When no records match the criteria, displays a dedicated empty state with an icon, guidance text, and a "Refresh" / "Reset Filters" action.
4. **Error & Retry State:**
   - If initial fetch fails, displays an error card showing the server error message and a red "Retry" button.
   - If a background refresh fails while data is already loaded, renders a non-disruptive banner with a quick "Retry" button.
5. **Live vs Demo Data Badge:**
   - Shows a green badge (`Live Server Attendance Active`) when records are loaded from the backend.
   - Transparently avoids displaying mock records when an API error occurs.
6. **Server-Side Pagination Controls:**
   - Pagination bar beneath the table displays: `"Showing X to Y of Z records"` with `"Previous"`, `"Page X of Y"`, and `"Next"` action buttons linked to `hrProvider.setAttendancePage(page)`.

---

## 4. Modified & Added Files

1. **`lib/models/hr_models.dart`**
   - Enhanced `Attendance.fromJson` to parse populated `employee` map, ISO date/time timestamps, numerical working hours, duration strings, and status normalization.
2. **`lib/services/api_service.dart`**
   - Added `AttendancePage` class with `records`, `page`, `limit`, `total`, and `totalPages`.
   - Implemented `ApiService.getAttendancePage(...)` for `GET /api/hr/attendance`.
   - Implemented `ApiService.getAttendanceByEmployee(...)` for `GET /api/hr/attendance/:employeeId`.
   - Fixed path prefix for legacy attendance endpoints to include `/api/`.
3. **`lib/providers/hr_provider.dart`**
   - Added `isAttendanceLoading`, `attendanceError`, `attendancePage`, `attendanceLimit`, `attendanceTotal`, `attendanceTotalPages`, `hasLoadedApiAttendance`, and `apiAttendanceRecords`.
   - Added `loadAttendance({int? page})` and `setAttendancePage(int page)`.
   - Connected `setAttendanceStatusFilter`, `setAttendanceTab`, `setAttendanceSelectedDate`, and `setAttendanceDateRange` to live reload when `hasLoadedApiAttendance` is true.
   - Updated `filteredAttendanceList`, `presentTodayCount`, and `lateTodayCount` to prioritize live records and guard against mock leakage on errors.
4. **`lib/features/attendance/attendance_view.dart`**
   - Added `initState` to fetch live data.
   - Added loading spinner and disabled state to "Sync Attendance" button.
   - Added "Live Server Attendance Active" badge.
   - Added loading, error with retry, and empty state cards.
   - Added pagination controls bar in the table footer.
   - Corrected check-out cell fallback (`att.checkOutTime ?? (att.checkInTime != null ? 'Active' : '—')`).
5. **`test/attendance_api_test.dart`**
   - Added 15 comprehensive unit and widget tests covering API calls, parameter encoding, error handling, status parsing, provider state changes, and UI states.

---

## 5. Verification & Test Results

### 1. Code Formatting
```bash
dart format lib/models/hr_models.dart lib/services/api_service.dart lib/providers/hr_provider.dart lib/features/attendance/attendance_view.dart test/attendance_api_test.dart
```
**Result:** 5 files formatted in 0.34s. Exit code 0.

### 2. Static Analysis
```bash
flutter analyze --no-fatal-infos
```
**Result:** 0 errors, 0 warnings. 26 benign existing formatting infos. Exit code 0.

### 3. Screen 6 Targeted Mocked Attendance Tests
```bash
flutter test test/attendance_api_test.dart
```
**Result:**
- `ApiService.getAttendancePage calls GET /api/hr/attendance with token, pagination, and filters` — **PASSED**
- `ApiService.getAttendancePage throws Exception on HTTP 401 Unauthorized` — **PASSED**
- `ApiService.getAttendancePage throws Exception on HTTP 403 Forbidden` — **PASSED**
- `ApiService.getAttendancePage throws FormatException on malformed server response envelope` — **PASSED**
- `ApiService.getAttendanceByEmployee calls GET /api/hr/attendance/:employeeId with encoded id and query` — **PASSED**
- `ApiService.getAttendanceByEmployee throws Exception on 404 Employee Not Found` — **PASSED**
- `Attendance.fromJson Robust Parsing normalizes LEAVE, ABSENT, HALF_DAY, and PRESENT accurately` — **PASSED**
- `Attendance.fromJson Robust Parsing extracts workingHours and formats workedDuration accurately` — **PASSED**
- `HRProvider Attendance Integration loadAttendance updates api records, pagination, and live status` — **PASSED**
- `HRProvider Attendance Integration loadAttendance captures errors without breaking provider` — **PASSED**
- `HRProvider Attendance Integration filter setters map UI status to backend query parameters` — **PASSED**
- `AttendanceView UI States renders loading state when fetching attendance records` — **PASSED**
- `AttendanceView UI States renders error state with Retry button on API failure` — **PASSED**
- `AttendanceView UI States renders empty state when no records found` — **PASSED**
- `AttendanceView UI States renders table and pagination when live records exist` — **PASSED**
- **Summary:** 15 of 15 tests passed. Exit code 0.

### 4. Full Regression Test Suite
```bash
flutter test
```
**Result:** All 99 tests passed across `widget_test.dart`, `departments_api_test.dart`, `employee_details_salary_documents_test.dart`, `employee_directory_api_test.dart`, `api_test.dart`, and `attendance_api_test.dart`. Exit code 0.

---

## 6. Distinguishing Mocked Tests from Live Backend Verification

- **Mocked Verification:**
  - All automated test suites (`test/attendance_api_test.dart`, `test/widget_test.dart`, etc.) run in Flutter test environment using `MockClient` from `package:http/testing.dart`. They simulate HTTP 200, 401, 403, 404, 500, and 502 responses without touching the MongoDB database or modifying real attendance records.
- **Live Backend Verification:**
  - `HrsystemBackend` code was verified by direct code inspection in `HrsystemBackend/routes/hrRoutes.js`, `HrsystemBackend/controllers/hrController.js`, and `HrsystemBackend/services/hrService.js`.
  - When the Flutter app runs against `http://localhost:5000` (or `AppConfig.apiBaseUrl`), it sends requests using `ApiService.token` and displays the `"Live Server Attendance Active"` badge once live data is loaded.

---

## 7. Remaining Blockers

- None. Screen 6 is complete, verified, formatted, analyzed, and integrated into the application.
