# LY SOFTWARE HR Dashboard — Screen 7: Leave Management Integration Report

**Date:** October 15, 2026  
**System:** LY SOFTWARE HR Dashboard (Flutter Client) & Express.js Backend (`HrsystemBackend`)  
**Feature:** Screen 7: Leave Management  
**API Contract:** `HrsystemBackend/docs/hr_backend_api_contract.md` (Section 7: Leave Operations)  
**Verification Level:** Focused Mocked Tests & Static Code Analysis (Exit Code 0)  

---

## 1. Executive Summary

Screen 7 (Leave Management) has been integrated with the documented HR backend leave APIs. The integration provides:
- Live paginated leave retrieval with query filtering (`page`, `limit`, `status`, `leaveType`, `startDate`, `endDate`, `employeeId`).
- Leave details retrieval (`GET /api/hr/leaves/:id`).
- Leave approval mutation (`PUT /api/hr/leaves/:id/approve`) with post-mutation server sync.
- Leave rejection mutation (`PUT /api/hr/leaves/:id/reject`) with mandatory rejection reason and post-mutation server sync.
- Server-authoritative state handling with explicit loading, empty, error, and retry states.
- Rejection of silent mock fallback when in API mode (error banner and retry state rendered without masking API failures).
- Zero UI redesign: preserved all existing theme tokens, responsive layouts, metric cards, proof preview components, and filter controls.

---

## 2. API Contract & Endpoint Mapping

### Documented & Supported Endpoints

| Endpoint | Method | Auth | Query / Body Parameters | Supported Response | Implementation Status |
| :--- | :---: | :---: | :--- | :--- | :--- |
| `/api/hr/leaves` | `GET` | HR (`Bearer <token>`) | `page`, `limit`, `status`, `leaveType`, `employeeId`, `startDate`, `endDate` | `{ success: true, message: "...", data: [...], pagination: { page, limit, total, totalPages } }` | **Fully Integrated** |
| `/api/hr/leaves/:id` | `GET` | HR (`Bearer <token>`) | Path: `:id` (24-char Mongo ObjectId) | `{ success: true, message: "...", data: { ... } }` | **Fully Integrated** |
| `/api/hr/leaves/:id/approve` | `PUT` | HR (`Bearer <token>`) | Path: `:id` | `{ success: true, message: "...", data: { ... } }` | **Fully Integrated** |
| `/api/hr/leaves/:id/reject` | `PUT` | HR (`Bearer <token>`) | Path: `:id`<br>Body: `{ "rejectionReason": "..." }` | `{ success: true, message: "...", data: { ... } }` | **Fully Integrated** |

### Unsupported or Undocumented Operations
- **Department Query Filter on Backend:** Backend `GET /api/hr/leaves` accepts `employeeId`, `status`, `leaveType`, `startDate`, and `endDate`, but does not support a `department` query filter. The client safely executes in-memory department filtering on the populated `employee.department` records returned by the server.
- **Bulk Approve/Reject:** Not documented in backend contract; leave review is performed per leave ID.
- **Leave Creation for Staff by HR:** HR endpoints only manage review/listing; leave application is handled under `/api/staff/leaves`.

---

## 3. Schema & Data Models

### Backend Population & Client Mapping

Backend returns populated `Leave` documents referencing `Employee` and `approvedBy`:
```json
{
  "_id": "60d5ecb8b5c9c82b88f11111",
  "employee": {
    "_id": "60d5ecb8b5c9c82b88f00001",
    "employeeId": "EMP1001",
    "firstName": "Anita",
    "lastName": "Rao",
    "department": "Tech",
    "designation": "Lead HR Manager",
    "email": "anita.rao@lysoftware.com"
  },
  "leaveType": "CASUAL",
  "startDate": "2026-10-20T00:00:00.000Z",
  "endDate": "2026-10-22T00:00:00.000Z",
  "reason": "Family emergency",
  "status": "PENDING",
  "hasMedicalProof": false,
  "medicalProofUrl": null,
  "approvedBy": null,
  "approvedAt": null,
  "rejectionReason": null
}
```

### Client Normalization
- **Identifier:** `staffId` maps to populated `employee.employeeId` (e.g. `EMP1001`) with fallback to `employee._id`.
- **Leave Type Mapping:**
  - `CASUAL` $\leftrightarrow$ `Casual`
  - `SICK` $\leftrightarrow$ `Medical` (UI proves medical certificates/proofs)
  - `ANNUAL` $\leftrightarrow$ `Earned`
  - `UNPAID` $\leftrightarrow$ `Unpaid`
  - `OTHER` $\leftrightarrow$ `Other`
- **Leave Status Mapping:**
  - `PENDING` $\leftrightarrow$ `Pending`
  - `APPROVED` $\leftrightarrow$ `Approved`
  - `REJECTED` $\leftrightarrow$ `Rejected`
  - `CANCELLED` $\leftrightarrow$ `Cancelled`
- **Duration Days:** Automatically calculates calendar days difference when `daysCount` is omitted by the backend.

---

## 4. Modified Files

1. **`lib/models/hr_models.dart`**
   - Updated `LeaveRequest.fromJson` to parse populated `employee.employeeId` (`EMP1001`), calculate duration days safely, normalize types (`CASUAL`, `SICK`, `ANNUAL`, `UNPAID`, `OTHER`), and normalize statuses (`PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`).
2. **`lib/services/api_service.dart`**
   - Added `LeavePage` model with `leaves`, `page`, `limit`, `total`, `totalPages`.
   - Added `ApiService.getLeavesPage` with query parameters serialization, Bearer authorization, pagination envelope parsing, and typed error handling.
   - Added `ApiService.getLeaveDetails(id)`.
   - Added `ApiService.approveLeaveRequest(id)` hitting `PUT /api/hr/leaves/:id/approve`.
   - Added `ApiService.rejectLeaveRequest(id, reason)` hitting `PUT /api/hr/leaves/:id/reject` with JSON body.
   - Updated legacy `getLeaves` URI prefix to `$baseUrl/api/hr/leaves` and preserved backward-compatible methods.
3. **`lib/providers/hr_provider.dart`**
   - Added leave pagination and async state: `isLeavesLoading`, `leavesError`, `leavesPage`, `leavesLimit`, `leavesTotal`, `leavesTotalPages`, `hasLoadedApiLeaves`, `apiLeaveRecords`, and `_leavesRequestVersion`.
   - Implemented `loadLeaves({int? page})` converting active filters to backend query parameters and handling versioning to avoid race conditions.
   - Implemented `setLeavesPage(int page)`.
   - Integrated filter setters (`setLeaveSearchQuery`, `setLeaveStatusFilter`, `setLeaveTypeFilter`, `setLeaveDateRange`, `navigateToLeaveManagement`) to trigger live reloading when in API mode.
   - Updated `approveLeave` and `rejectLeave` to call API mutations, surface backend errors, reload live data, and confirm updated statuses from server.
   - Updated `filteredLeaveRequests`, `pendingLeavesCount`, `approvedLeavesCount`, and `rejectedLeavesCount` to reflect server data and return empty lists on API failure instead of displaying mock data.
4. **`lib/features/leaves/leave_management_view.dart`**
   - Added `initState` with `addPostFrameCallback` calling `loadLeaves()`.
   - Added `Live Server Leave Management Active` badge.
   - Added loading spinner state and disabled state on the refresh button during syncing.
   - Added dedicated initial error container with retry button and inline sync warning banner for background sync errors.
   - Added pagination footer displaying `Showing X to Y of Z records` and Previous/Next page controls.
   - Updated approve/reject action handlers in table rows, detail modal, and reject dialog to display server-provided error messages on failure.
5. **`test/leave_management_api_test.dart`**
   - Created comprehensive mock unit and widget tests covering API calls, parameter serialization, model parsing, error handling (401, 403, 500), pagination, loading/error states, and approve/reject mutations.

---

## 5. Verification & Test Results

### 1. Dart Formatting
```powershell
dart format lib/models/hr_models.dart lib/services/api_service.dart lib/providers/hr_provider.dart lib/features/leaves/leave_management_view.dart test/leave_management_api_test.dart
```
- **Exit Code:** `0`
- **Output:** Formatted 5 files in 0.24 seconds.

### 2. Targeted Leave Management Test Suite
```powershell
flutter test test/leave_management_api_test.dart
```
- **Exit Code:** `0`
- **Tests Passed:** 16 / 16
  - `ApiService.getLeavesPage calls GET /api/hr/leaves with auth token, pagination, and filters`
  - `ApiService.getLeavesPage throws typed Exception on 401 unauthorized`
  - `ApiService.getLeavesPage throws FormatException on malformed server payload`
  - `ApiService.getLeaveDetails fetches single leave details successfully`
  - `ApiService.getLeaveDetails returns null when leave is not found (404)`
  - `approveLeaveRequest sends PUT /api/hr/leaves/:id/approve and parses confirmed result`
  - `approveLeaveRequest throws on 400 when status is not PENDING`
  - `rejectLeaveRequest sends PUT /api/hr/leaves/:id/reject with reason body`
  - `LeaveRequest Model Parsing parses types and statuses with full normalization`
  - `HRProvider Leave Management Integration loadLeaves transitions loading, populates records, and enables live mode`
  - `HRProvider Leave Management Integration loadLeaves surfaces error and does NOT silently show mock data on failure`
  - `HRProvider Leave Management Integration approveLeave in live mode refreshes from server and confirms updated status`
  - `HRProvider Leave Management Integration approveLeave in live mode fails gracefully without mutating local state`
  - `HRProvider Leave Management Integration filters and pagination update correctly in live mode`
  - `LeaveManagementView Widget Tests renders live server active badge when live leaves loaded`
  - `LeaveManagementView Widget Tests renders error container and retry button on load failure`

### 3. Static Code Analysis
```powershell
flutter analyze --no-fatal-infos
```
- **Exit Code:** `0`
- **Result:** No errors or warnings in any modified files.

### 4. Full Regression Test Suite
```powershell
flutter test
```
- **Exit Code:** `0`
- **Tests Passed:** 115 / 115 across the entire test suite (`api_test.dart`, `attendance_api_test.dart`, `dashboard_api_test.dart`, `departments_api_test.dart`, `employee_details_salary_documents_test.dart`, `employee_directory_api_test.dart`, `leave_management_api_test.dart`, `widget_test.dart`).

---

## 6. Verification Status: Mocked vs. Live Backend

- **Mocked Verification:** **Verified & Passed (100%)**
  - All query parameter serializations, headers, JSON deserializations, pagination bounds, error mappings, loading states, and state transitions were verified using `MockClient` and Flutter widget tests.
- **Live Backend Verification:** **Not Conducted**
  - Live backend verification requires a running Express backend instance (`node server.js`) with an accessible MongoDB database containing seed leave requests.

---

## 7. Blockers & Next Steps

- **No Blockers:** All Screen 7 requirements are satisfied without regressions.
- **Next Phase:** Proceed with Screen 8 (Payroll Management) when requested.
