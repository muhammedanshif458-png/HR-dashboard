# Verification Audit Report — Screen 7: Leave Management

**Audit Date:** October 16, 2026  
**Audited Subsystem:** Screen 7 (Leave Management)  
**Flutter Workspace:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**Backend Workspace:** `C:\Users\Admin\Downloads\HrsystemBackend`  
**API Reference:** `C:\Users\Admin\Downloads\HrsystemBackend\docs\hr_backend_api_contract.md`  
**Audit Type:** Verification-Only Audit (Code Comparison, Contract Audit, Mock Suite, Full Regression, Live Port Probe)

---

## 1. Audit Summary & Verification Table

| Item / Feature | Contract Requirement | Actual Backend Support | Flutter Implementation | Audit Verdict |
| :--- | :--- | :--- | :--- | :---: |
| **GET Leave Listing** | `GET /api/hr/leaves` with auth | Supported (`hrRoutes.js:55`, `hrService.js:440`) | `ApiService.getLeavesPage` (`api_service.dart:480`) | **PASS** |
| **GET Leave Details** | `GET /api/hr/leaves/:id` with auth | Supported (`hrRoutes.js:56`, `hrService.js:498`) | `ApiService.getLeaveDetails` (`api_service.dart:571`) | **PASS** |
| **Approve Leave** | `PUT /api/hr/leaves/:id/approve` | Supported (`hrRoutes.js:57`, `hrService.js:517`) | `ApiService.approveLeaveRequest` (`api_service.dart:589`) | **PASS** |
| **Reject Leave** | `PUT /api/hr/leaves/:id/reject` with reason | Supported (`hrRoutes.js:58`, `hrService.js:538`) | `ApiService.rejectLeaveRequest` (`api_service.dart:623`) | **PASS** |
| **Query Filters (Backend)** | `status`, `leaveType`, `employeeId`, `startDate`, `endDate`, `page`, `limit` | Implemented in `hrService.getLeaves` | Serialized in `ApiService.getLeavesPage` query map | **PASS** |
| **Department Filter** | Not in backend query parameters | Handled via in-memory employee department check | Client-side filter on populated `employee.department` | **PASS** |
| **Pagination Handling** | Envelope `{ page, limit, total, totalPages }` | Generated via `sendSuccess` and `Math.ceil(total / limit)` | `LeavePage` model unpacks envelope, footer renders range | **PASS** |
| **Model Deserialization** | Populated `employee`, `approvedBy`, timestamps | ObjectId refs populated with selected fields | `LeaveRequest.fromJson` with null-safe fallbacks | **PASS** |
| **Type & Status Normalization** | UPPERCASE enums in DB (`CASUAL`, `PENDING`...) | Normalized to UI title-case strings | Bidirectional mapping in `fromJson` and query params | **PASS** |
| **Duration Days Calculation** | DB has `startDate` and `endDate` | `daysCount` optional in DB; calculated if absent | `calculatedDays` calculates `endDate - startDate + 1` | **PASS** |
| **Filter Reset & Page 1 Reset** | Current page must reset to 1 on filter changes | N/A (Frontend behavior) | `leavesPage = 1` set on all filter mutations | **PASS** |
| **Stale / Mock Data Prevention** | Never show mock data on API failure | N/A (Frontend behavior) | `filteredLeaveRequests` returns `const []` on API error | **PASS** |
| **Mutation State Refresh** | Refresh from server after mutation | Returns updated leave document | Calls `await loadLeaves()` post-mutation | **PASS** |
| **Targeted Unit & Widget Tests** | Response parsing, filters, pagination, states | 16 targeted mocked tests | 16/16 passed (`test/leave_management_api_test.dart`) | **PASS** |
| **Static Code Analysis** | No fatal errors or warnings | Flutter analyzer check | 0 errors, 0 warnings (`exit code 0`) | **PASS** |
| **Full Regression Suite** | No regressions across app | 115 test cases total | 115/115 passed (`flutter test`, `exit code 0`) | **PASS** |
| **Live Backend Verification** | Real HTTP requests to running server | Backend server offline on localhost:3000 / 5000 | Port probe: No process listening on 3000 or 5000 | **BLOCKED** |

---

## 2. Backend Inspection & Contract Comparison

### 2.1 Route Definitions (`routes/hrRoutes.js`)
All HR routes are guarded by JWT authentication and role validation:
```javascript
// routes/hrRoutes.js lines 18-19, 54-58
router.use(authMiddleware, roleMiddleware('HR'));

// Leaves
router.get('/leaves', hrController.getLeaves);
router.get('/leaves/:id', mongoIdParamValidator, hrController.getLeaveById);
router.put('/leaves/:id/approve', mongoIdParamValidator, hrController.approveLeave);
router.put('/leaves/:id/reject', rejectLeaveValidator, hrController.rejectLeave);
```

### 2.2 Controller Logic (`controllers/hrController.js`)
- `getLeaves`: Receives `req.query`, invokes `hrService.getLeaves(req.query)`, returns `sendSuccess(res, 'Leave requests fetched successfully', leaves, 200, pagination)`.
- `getLeaveById`: Validates Mongo ID, invokes `hrService.getLeaveById(req.params.id)`.
- `approveLeave`: Validates Mongo ID, passes `req.params.id` and `req.user._id` to `hrService.approveLeave`.
- `rejectLeave`: Validates Mongo ID and body, passes `req.params.id`, `req.user._id`, and `req.body.rejectionReason` to `hrService.rejectLeave`.

### 2.3 Service Implementation & Query Filter Logic (`services/hrService.js`)
```javascript
// services/hrService.js lines 440-485
async getLeaves({ page = 1, limit = 20, employeeId, status, leaveType, startDate, endDate }) {
  page = Math.max(1, parseInt(page, 10));
  limit = Math.max(1, Math.min(100, parseInt(limit, 10)));
  const skip = (page - 1) * limit;

  const filter = {};

  if (employeeId) {
    let emp;
    if (mongoose.Types.ObjectId.isValid(employeeId)) {
      emp = await Employee.findOne({ $or: [{ _id: employeeId }, { employeeId: employeeId.toUpperCase() }] });
    } else {
      emp = await Employee.findOne({ employeeId: employeeId.toUpperCase() });
    }
    if (emp) filter.employee = emp._id;
    else return { leaves: [], pagination: { page, limit, total: 0, totalPages: 0 } };
  }

  if (status) filter.status = status;
  if (leaveType) filter.leaveType = leaveType;

  if (startDate || endDate) {
    if (startDate && endDate) {
      filter.startDate = { $gte: new Date(startDate) };
      filter.endDate = { $lte: new Date(endDate) };
    } else if (startDate) {
      filter.startDate = { $gte: new Date(startDate) };
    } else if (endDate) {
      filter.endDate = { $lte: new Date(endDate) };
    }
  }

  const [leaves, total] = await Promise.all([
    Leave.find(filter)
      .populate('employee', 'employeeId firstName lastName department designation email')
      .populate('approvedBy', 'firstName lastName email role')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Leave.countDocuments(filter)
  ]);

  const totalPages = Math.ceil(total / limit) || 1;
  return { leaves, pagination: { page, limit, total, totalPages } };
}
```

### 2.4 Mutation Integrity & Constraints
1. **Approval Constraint:**
   ```javascript
   if (leave.status !== 'PENDING') {
     throw new AppError(`Cannot approve leave request with status: ${leave.status}`, 400);
   }
   ```
   - Sets `leave.status = 'APPROVED'`, `approvedBy = adminUserId`, `approvedAt = new Date()`, `rejectionReason = null`.
2. **Rejection Constraint:**
   ```javascript
   if (leave.status !== 'PENDING') {
     throw new AppError(`Cannot reject leave request with status: ${leave.status}`, 400);
   }
   ```
   - Sets `leave.status = 'REJECTED'`, `approvedBy = adminUserId`, `approvedAt = new Date()`, `rejectionReason = rejectionReason || 'Leave request was not approved by HR.'`.

---

## 3. Flutter Client Comparison & Mappings

### 3.1 Endpoint Comparison Table

| Aspect | Backend Expectation | Flutter `ApiService` Implementation | Audit Result |
| :--- | :--- | :--- | :---: |
| **Base URL** | `http://localhost:3000` (or `AppConfig.apiBaseUrl`) | `AppConfig.apiBaseUrl` | **Match** |
| **Leaves List Route** | `GET /api/hr/leaves` | `Uri.parse('$baseUrl/api/hr/leaves')` | **Match** |
| **Leaves Detail Route** | `GET /api/hr/leaves/:id` | `Uri.parse('$baseUrl/api/hr/leaves/$id')` | **Match** |
| **Approve Route** | `PUT /api/hr/leaves/:id/approve` | `Uri.parse('$baseUrl/api/hr/leaves/$id/approve')` | **Match** |
| **Reject Route** | `PUT /api/hr/leaves/:id/reject` | `Uri.parse('$baseUrl/api/hr/leaves/$id/reject')` | **Match** |
| **Reject Body** | JSON `{ "rejectionReason": "..." }` | `jsonEncode({'rejectionReason': rejectionReason})` | **Match** |
| **Authorization Header** | `Authorization: Bearer <token>` | `_headers()` attaches `'Authorization': 'Bearer $_token'` | **Match** |
| **Content-Type** | `application/json` | Attached in `_headers()` | **Match** |

### 3.2 Query Parameter Serialization
```dart
// api_service.dart lines 489-504
final query = <String, String>{
  'page': page.toString(),
  'limit': limit.toString(),
  if (employeeId != null && employeeId.trim().isNotEmpty)
    'employeeId': employeeId.trim(),
  if (status != null && status.trim().isNotEmpty && status != 'all')
    'status': status.trim(),
  if (leaveType != null && leaveType.trim().isNotEmpty && leaveType != 'all')
    'leaveType': leaveType.trim(),
  if (startDate != null && startDate.trim().isNotEmpty)
    'startDate': startDate.trim(),
  if (endDate != null && endDate.trim().isNotEmpty)
    'endDate': endDate.trim(),
};
```
- Query parameter names match backend `req.query` exactly.
- Omits empty strings or `'all'` values to prevent accidental filter constraints.

---

## 4. Model Parser Audit (`LeaveRequest.fromJson`)

The deserialization logic in `lib/models/hr_models.dart` (lines 238–342) was audited against the Mongoose schema:

1. **Populated Employee Object:**
   - Safely parses both map format `{'firstName': '...', 'employeeId': 'EMP1001'}` and legacy flattened fields.
   - Assigns `staffId` from `employee['employeeId']` (human-readable string e.g. `EMP1001`), falling back to `employee['_id']`.
2. **Leave Types Normalization:**
   - Backend DB: `['CASUAL', 'SICK', 'ANNUAL', 'UNPAID', 'OTHER']`
   - Flutter Model: `CASUAL` $\rightarrow$ `Casual`, `SICK` $\rightarrow$ `Medical`, `ANNUAL` $\rightarrow$ `Earned`, `UNPAID` $\rightarrow$ `Unpaid`, `OTHER` $\rightarrow$ `Other`.
3. **Leave Status Normalization:**
   - Backend DB: `['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED']`
   - Flutter Model: `PENDING` $\rightarrow$ `Pending`, `APPROVED` $\rightarrow$ `Approved`, `REJECTED` $\rightarrow$ `Rejected`, `CANCELLED` $\rightarrow$ `Cancelled`.
4. **Dates & Calculated Duration:**
   - Backend fields: `startDate`, `endDate` (ISO Date strings).
   - If `fromDate` / `toDate` are absent, extracts `startDate.split('T')[0]` and `endDate.split('T')[0]`.
   - Computes calendar span `DateTime.parse(endDate).difference(DateTime.parse(startDate)).inDays + 1` whenever `daysCount <= 0`.
5. **ApprovedBy Population:**
   - Handles populated user object `{'firstName': 'Admin', 'lastName': 'User', ...}` extracting formatted name string.
   - Falls back gracefully to string ID or null if unapproved.
6. **Error Responses & Malformed Data:**
   - Handles non-JSON responses with `FormatException`.
   - Handles `{ success: false, message: '...' }` envelopes by extracting error message strings.

---

## 5. UI & State Verification

1. **Automatic Initial Load:**
   - `leave_management_view.dart` `initState` schedules `hrProvider.loadLeaves()` via `addPostFrameCallback`.
2. **Page Reset on Filter Changes:**
   - `setLeaveSearchQuery`: resets `leavesPage = 1` and triggers `loadLeaves(page: 1)`.
   - `setLeaveStatusFilter`: resets `leavesPage = 1` and triggers `loadLeaves(page: 1)`.
   - `setLeaveTypeFilter`: resets `leavesPage = 1` and triggers `loadLeaves(page: 1)`.
   - `setLeaveDateRange`: resets `leavesPage = 1` and triggers `loadLeaves(page: 1)`.
   - "Reset Filters" action in UI resets controller, sets all filters to `'all'`, and resets page to 1.
3. **Pagination Bounds:**
   - Footer renders `Showing X to Y of Z records`.
   - Previous button disabled when `leavesPage <= 1`.
   - Next button disabled when `leavesPage >= leavesTotalPages`.
4. **Stale Mock-Data Prevention:**
   - In `hr_provider.dart`:
     ```dart
     List<LeaveRequest> get filteredLeaveRequests {
       if (leavesError != null && !hasLoadedApiLeaves) {
         return const [];
       }
       final sourceList = hasLoadedApiLeaves ? apiLeaveRecords : leaveRequests;
       ...
     }
     ```
   - When API fails on initial load, mock records are **never** displayed; the view renders the error container with a `Retry` button.
5. **Mutation Confirmation:**
   - `approveLeave` and `rejectLeave` await the backend mutation.
   - Upon HTTP 200, `await loadLeaves()` refreshes data from the server.
   - The UI shows a green confirmation SnackBar.
   - If mutation fails (e.g. HTTP 400 "Cannot approve leave request with status: APPROVED"), state is preserved without silent local mutation, and a red error SnackBar is displayed.

---

## 6. Live Backend Verification Status

- **Status:** **BLOCKED**
- **Technical Justification:**
  - Active TCP socket probe via `Get-NetTCPConnection` and `netstat -ano` shows that no process is currently listening on port 3000 (`http://localhost:3000`) or port 5000 (`http://localhost:5000`).
  - While MongoDB is running on `127.0.0.1:27017`, the Node.js/Express server is offline.
  - Per instructions, mocked tests are **not** claimed as live backend verification. Live verification remains blocked until an authorized backend instance is started and test credentials/leave IDs are provided.

---

## 7. Test Results & Execution Evidence

### 7.1 Targeted Leave Tests (`test/leave_management_api_test.dart`)
- **Command:** `flutter test test/leave_management_api_test.dart`
- **Exit Code:** `0`
- **Output:**
  ```text
  00:00 +0: loading C:/Users/Admin/Downloads/HR-dashboard/flutter_src/test/leave_management_api_test.dart
  00:00 +0: ApiService.getLeavesPage calls GET /api/hr/leaves with auth token, pagination, and filters
  00:00 +1: ApiService.getLeavesPage throws typed Exception on 401 unauthorized
  00:00 +2: ApiService.getLeavesPage throws FormatException on malformed server payload
  00:00 +3: ApiService.getLeaveDetails fetches single leave details successfully
  00:00 +4: ApiService.getLeaveDetails returns null when leave is not found (404)
  00:00 +5: ApiService Mutations (approve & reject) approveLeaveRequest sends PUT /api/hr/leaves/:id/approve and parses confirmed result
  00:00 +6: ApiService Mutations (approve & reject) approveLeaveRequest throws on 400 when status is not PENDING
  00:00 +7: ApiService Mutations (approve & reject) rejectLeaveRequest sends PUT /api/hr/leaves/:id/reject with reason body
  00:00 +8: LeaveRequest Model Parsing parses types and statuses with full normalization
  00:00 +9: HRProvider Leave Management Integration loadLeaves transitions loading, populates records, and enables live mode
  00:00 +10: HRProvider Leave Management Integration loadLeaves surfaces error and does NOT silently show mock data on failure
  00:00 +11: HRProvider Leave Management Integration approveLeave in live mode refreshes from server and confirms updated status
  00:00 +12: HRProvider Leave Management Integration approveLeave in live mode fails gracefully without mutating local state
  00:00 +13: HRProvider Leave Management Integration filters and pagination update correctly in live mode
  00:00 +14: LeaveManagementView Widget Tests renders live server active badge when live leaves loaded
  00:05 +15: LeaveManagementView Widget Tests renders error container and retry button on load failure
  00:06 +16: All tests passed!
  ```

### 7.2 Static Code Analysis (`flutter analyze --no-fatal-infos`)
- **Command:** `flutter analyze --no-fatal-infos`
- **Exit Code:** `0`
- **Result:** No errors or warnings found in any Screen 7 files.

### 7.3 Full Regression Suite (`flutter test`)
- **Command:** `flutter test`
- **Exit Code:** `0`
- **Result:** 115 / 115 tests passed across all test files:
  - `test/api_test.dart` (10 passed)
  - `test/attendance_api_test.dart` (16 passed)
  - `test/dashboard_api_test.dart` (9 passed)
  - `test/departments_api_test.dart` (18 passed)
  - `test/employee_details_salary_documents_test.dart` (7 passed)
  - `test/employee_directory_api_test.dart` (12 passed)
  - `test/leave_management_api_test.dart` (16 passed)
  - `test/widget_test.dart` (27 passed)

---

## 8. Defect Report & Proposed Fixes

No code defects were found in the Screen 7 implementation:
- Endpoint contracts, URL structures, HTTP methods, headers, and payloads match backend routes and controllers.
- Safe fallbacks, status/type normalizations, and duration calculations prevent UI crashes on edge-case data.
- State handling guarantees that failures surface transparently without showing stale mock records.
- All 115 tests in the workspace pass without regressions.

**Recommendation:**
The implementation for Screen 7: Leave Management is verified and complete. Ready to proceed to Screen 8 (Payroll Processing) when authorized.
