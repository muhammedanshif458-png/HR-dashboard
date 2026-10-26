# Integration Report — Screen 8: Payroll Processing

**Date:** October 16, 2026  
**Screen:** Screen 8 (Payroll Processing)  
**Frontend Path:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**Backend Path:** `C:\Users\Admin\Downloads\HrsystemBackend`  
**API Reference:** `C:\Users\Admin\Downloads\HrsystemBackend\docs\hr_backend_api_contract.md`  

---

## 1. Executive Summary

Screen 8 (Payroll Processing) integrates the LY Software HR Management Flutter dashboard with the documented Express backend payroll engine. 

Prior to integration, the Payroll UI computed all salary figures, deductions, and payout numbers using in-widget calculations based on local mock data. Following integration, the screen retrieves authoritative payroll metrics and itemized employee calculations directly from the backend service endpoints, parses pagination envelopes, manages period/month/year/department filters, handles error/retry states, and prevents stale mock data from appearing as live data.

In strict alignment with the verification rules:
- **No invented endpoints or capabilities:** Operations unsupported by the backend contract (such as batch finalization mutations or payslip PDF downloading) were not fabricated or simulated with artificial endpoints.
- **No financial mutations against real records:** No mutations or payments were executed against live records.
- **Clear separation between mocked test suite and live backend:** The full regression suite and targeted test suite run against mock fixtures with 100% pass rates. Live backend verification remains marked as **BLOCKED** while the backend Node server process is offline.

---

## 2. API Contract & Endpoint Specification

The backend provides three dedicated HR-authorized payroll endpoints defined in `routes/hrRoutes.js` (lines 64–67), handled by `controllers/payrollController.js`, and computed by `services/payrollService.js`:

### 2.1 Get Payroll Summary
- **Endpoint:** `GET /api/hr/payroll/summary`
- **Authorization:** `Bearer <accessToken>` (HR Role required)
- **Query Parameters:**
  - `month`: integer (1–12, defaults to current month)
  - `year`: integer (e.g., 2026, defaults to current year)
  - `department`: string (optional, e.g. `'Tech'`, `'Telecalling'`, or `'all'`)
- **Backend Controller:** `payrollController.getSummary`
- **Backend Service:** `payrollService.getPayrollSummary(year, month, department)`
- **Response Envelope:**
  ```json
  {
    "success": true,
    "message": "Payroll summary retrieved successfully",
    "data": {
      "year": 2026,
      "month": 10,
      "department": "all",
      "totalEmployees": 24,
      "totalPayrollExpenditure": 1560000.0,
      "totalDeductions": 42500.0,
      "totalNetPayout": 1517500.0
    }
  }
  ```

### 2.2 Get Itemized Employees Payroll List
- **Endpoint:** `GET /api/hr/payroll/employees`
- **Authorization:** `Bearer <accessToken>` (HR Role required)
- **Query Parameters:**
  - `month`: integer (1–12)
  - `year`: integer (YYYY)
  - `department`: string (`'all'`, `'Tech'`, `'Telecalling'`)
  - `search`: string (matches `firstName`, `lastName`, `email`, `employeeId`, `designation`)
  - `page`: integer (default `1`)
  - `limit`: integer (default `50`, capped at `100`)
- **Backend Controller:** `payrollController.getEmployeesPayroll`
- **Backend Service:** `payrollService.getEmployeesPayroll(year, month, { department, search, page, limit })`
- **Response Envelope:**
  ```json
  {
    "success": true,
    "message": "Employee payroll records retrieved successfully",
    "data": [
      {
        "employee": {
          "id": "670cb...",
          "employeeId": "EMP1001",
          "firstName": "Anita",
          "lastName": "Rao",
          "name": "Anita Rao",
          "department": "Tech",
          "designation": "Lead HR Manager",
          "status": "ACTIVE",
          "salary": 85000,
          "salaryCurrency": "INR"
        },
        "year": 2026,
        "month": 10,
        "standardWorkingDays": 22,
        "presentDays": 21,
        "approvedLeaves": 1,
        "paidLeaveDays": 1,
        "unpaidLeaveDays": 0,
        "payableDays": 22,
        "grossSalary": 85000,
        "dailyRate": 3863.64,
        "deductions": 0,
        "netPay": 85000
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 24,
      "totalPages": 1
    }
  }
  ```

### 2.3 Get Single Employee Payroll Computation Details
- **Endpoint:** `GET /api/hr/payroll/employees/:employeeId`
- **Authorization:** `Bearer <accessToken>` (HR Role required)
- **Query Parameters:**
  - `month`: integer (1–12)
  - `year`: integer (YYYY)
- **Backend Controller:** `payrollController.getEmployeePayrollById`
- **Backend Service:** `payrollService.getSingleEmployeePayroll(empIdentifier, year, month)`
- **Response Envelope:** Returns the individual computation object in `data`.

---

## 3. Frontend Implementation & Architecture

### 3.1 Domain Models (`lib/models/hr_models.dart`)
Added three type-safe models that match the backend calculation output:
1. `PayrollSummary`: Decodes aggregated figures (`year`, `month`, `department`, `totalEmployees`, `totalPayrollExpenditure`, `totalDeductions`, `totalNetPayout`).
2. `EmployeePayrollRecord`: Decodes populated employee metadata and itemized payroll fields (`standardWorkingDays`, `presentDays`, `approvedLeaves`, `paidLeaveDays`, `unpaidLeaveDays`, `payableDays`, `grossSalary`, `dailyRate`, `deductions`, `netPay`).
3. `EmployeePayrollPage`: Encompasses list of records and pagination metadata (`page`, `limit`, `total`, `totalPages`).

### 3.2 Service Layer (`lib/services/api_service.dart`)
Implemented client methods calling the backend routes:
- `ApiService.getPayrollSummary({int? month, int? year, String? department})`
- `ApiService.getEmployeesPayroll({int? month, int? year, String? department, String? search, int page = 1, int limit = 50})`
- `ApiService.getEmployeePayrollById(String employeeId, {int? month, int? year})`

All methods enforce:
- Inclusion of `Authorization: Bearer <token>` headers.
- Safe JSON validation and format exception guarding.
- Error message extraction from backend error envelope (`message`).

### 3.3 State Management (`lib/providers/hr_provider.dart`)
Integrated state fields, async loaders, and getters into `HRProvider`:
- **State variables:** `payrollYear`, `payrollMonth`, `payrollDepartment`, `payrollSearchQuery`, `payrollPage`, `payrollLimit`, `payrollTotal`, `payrollTotalPages`, `isPayrollLoading`, `payrollError`, `hasLoadedApiPayroll`, `apiPayrollRecords`, `apiPayrollSummary`.
- **Concurrent Loader (`loadPayroll`):** Uses `Future.wait` to concurrently fetch `getPayrollSummary` and `getEmployeesPayroll`.
- **Request Race-Condition Guarding:** Increments `_payrollRequestVersion` so stale responses from previous queries do not overwrite fresher data.
- **Stale Mock Data Prevention:** If `payrollError != null && !hasLoadedApiPayroll`, `filteredPayrollRecords` returns `const []`, ensuring fake mock data never masquerades as live records upon an error.
- **Filter-Driven Page Reset:** Modifying month, year, department, or search query resets `payrollPage = 1` and triggers `loadPayroll()`.
- **Offline Mock Fallback:** When `!hasLoadedApiPayroll && payrollError == null`, it preserves the mock calculation so offline widget tests (`widget_test.dart`) continue to render smoothly.

### 3.4 User Interface (`lib/features/payroll/payroll_view.dart`)
- **Metric Cards:** Display Gross Salary Pool, Unpaid Leave Deductions, and Net Payout Amount driven directly by `hrProvider.effectivePayrollSummary`.
- **Filters:** Month, Year, Department, and Search bar connected to `HRProvider`.
- **Loading & Error Feedback:**
  - `LinearProgressIndicator` rendered while `isPayrollLoading` is active.
  - Red error alert banner with a **Retry** button rendered when `payrollError` is present.
  - Clean empty state banner displayed when no records match filter criteria.
  - Refresh button in the top bar to reload live data on demand.
- **Pagination Footer:** Displays `Showing X to Y of Z records` with Previous and Next page controls whenever `payrollTotalPages > 1`.
- **Payslip Dialog:** Detailed itemized modal displaying standard working days, present days, approved leaves, paid/unpaid days, gross salary, deductions, and net payout.
- **Batch Finalization Button:** Avoids calling non-existent endpoints. Displays an informative notification informing the user that batch finalization mutation is pending backend endpoint implementation.

---

## 4. Unsupported Features & Remaining Blockers

| Feature / Capability | Status in Backend | Frontend Handling | Recommended Next Step |
| :--- | :--- | :--- | :--- |
| **Batch Finalization Mutation** (`POST /api/hr/payroll/finalize` or similar) | **Unsupported** (no backend route or controller exists) | Button shows safe informative SnackBar; no financial mutations executed | Implement batch ledger / audit freeze endpoint in backend if historical locking is required. |
| **Salary Payment Mutation** (`POST /api/hr/payroll/payout`) | **Unsupported** | Not implemented in client | Integrate banking/payment gateway APIs when live disbursal is required. |
| **Payslip PDF Export** (`GET /api/hr/payroll/employees/:id/payslip.pdf`) | **Unsupported** (backend only returns JSON calculation) | View Payslip dialog displays breakdown from JSON; PDF download is not faked | Implement PDF generation middleware (e.g. `pdfkit`) in backend. |

---

## 5. Verification & Test Evidence

### 5.1 Changed Files
1. `lib/models/hr_models.dart`: Added `PayrollSummary`, `EmployeePayrollRecord`, and `EmployeePayrollPage`.
2. `lib/services/api_service.dart`: Added `getPayrollSummary`, `getEmployeesPayroll`, and `getEmployeePayrollById`.
3. `lib/providers/hr_provider.dart`: Added payroll state variables, setters, `loadPayroll`, and getters.
4. `lib/features/payroll/payroll_view.dart`: Integrated with provider, added error banner, refresh button, pagination footer, and safe mutation handling.
5. `test/payroll_management_api_test.dart`: Created new targeted test suite (14 test cases).

### 5.2 Formatting (`dart format`)
```text
Formatted 5 files (0 changed) in 0.19 seconds.
Exit Code: 0
```

### 5.3 Targeted Test Suite (`flutter test test/payroll_management_api_test.dart`)
```text
00:00 +0: ApiService.getPayrollSummary calls GET /api/hr/payroll/summary with auth, month, year, department
00:00 +1: ApiService.getPayrollSummary handles 401 unauthorized error
00:00 +2: ApiService.getPayrollSummary handles malformed JSON error
00:00 +3: ApiService.getEmployeesPayroll calls GET /api/hr/payroll/employees with pagination and search query
00:00 +4: ApiService.getEmployeesPayroll handles empty results and server error response safely
00:00 +5: ApiService.getEmployeePayrollById calls GET /api/hr/payroll/employees/:id and parses single computation
00:00 +6: ApiService.getEmployeePayrollById handles 404 employee not found
00:00 +7: HRProvider Payroll Integration loadPayroll populates summary, records, and pagination metadata
00:00 +8: HRProvider Payroll Integration prevents stale mock data and sets error state on API failure
00:00 +9: HRProvider Payroll Integration filter changes reset current page to 1 and reload data
00:00 +10: PayrollView Widget Tests renders loaded payroll records, metrics, and data table
00:03 +11: PayrollView Widget Tests renders error banner with Retry button when payrollError is set
00:03 +12: PayrollView Widget Tests opens payslip dialog when View Payslip Details is tapped
00:04 +13: PayrollView Widget Tests Process & Finalize Batch shows safe notification without mutating records
00:05 +14: All tests passed!

Exit Code: 0
```

### 5.4 Static Analysis (`flutter analyze --no-fatal-infos`)
```text
Analyzing flutter_src...
26 issues found. (all pre-existing info messages in modals/api_service; 0 errors, 0 warnings)
Exit Code: 0
```

### 5.5 Full Regression Suite (`flutter test`)
```text
All 129 tests passed across all test files in flutter_src!
Exit Code: 0
```

### 5.6 Live Backend Verification Status
- **Status:** **BLOCKED**
- **Reason:** The Node.js Express backend (`server.js`) is offline on ports 3000 and 5000. Real HTTP requests cannot be executed until the server process is started.
- **Safety Guarantee:** Mocked test passes are strictly reported as mocked unit/widget tests. No claims of live server integration are made without live HTTP execution evidence.

---

## 6. Next Steps
1. Report Screen 8 completion and verification evidence to the user.
2. Await user confirmation before proceeding to Screen 9 (Task Management integration).
