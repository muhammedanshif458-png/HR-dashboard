# HR Screen & API Integration Audit

**Date:** 2026-10-09  
**Project:** LY-HR_dashboard_flutter  
**Status:** Audit Complete  

## Endpoint-by-Endpoint Integration Table

| API Method & Path | Frontend Service Method | UI Screen/Action | Request Contract Status | Response Parsing Status | Authentication Status | Mock Test Result | Live Verification Status | Required Fix & Priority |
|---|---|---|---|---|---|---|---|---|
| `GET /api/hr/dashboard` | `getDashboardMetrics()` | HR Dashboard / Metrics | Mapped in Service | Stubbed / Unknown Schema | Bearer Included | Passed (No rendering exceptions) | Blocked (No API) | Define chart schemas (High) |
| `GET /api/hr/employees` | `getEmployees()` | HR Dashboard / Directory Table | Mapped in Service | Assumes `{data: [...]}` or flat list | Bearer Included | Passed | Blocked (No API) | Verify MongoDB `_id` mapping (High) |
| `POST /api/hr/employees` | `addEmployee()` | AddStaffModal / Save | Mapped (JSON body) | Expects 201/200 Status | Bearer Included | Passed | Blocked (No API) | Define error response format (Medium) |
| `GET /api/hr/employees/:id` | *N/A (Derived locally)* | StaffProfileView / View Details | Unimplemented | N/A | N/A | Passed | Blocked (No API) | Connect if deep-linking needed (Low) |
| `PUT /api/hr/employees/:id` | `updateEmployee()` | EditStaffModal / Save | Mapped (JSON body) | Expects 200 Status | Bearer Included | Passed | Blocked (No API) | Define partial update rules (Medium) |
| `DELETE /api/hr/employees/:id` | `deleteEmployee()` | StaffProfileView / Mark Resigned | Mapped | Expects 200 Status | Bearer Included | Passed | Blocked (No API) | Clarify DELETE vs PUT for resignation (High) |
| `GET /api/hr/attendance` | `getAttendance()` | HR Dashboard / Presence calculation | Mapped | Stubbed | Bearer Included | Passed | Blocked (No API) | Define date filtering logic (High) |
| `GET /api/hr/attendance/:empId`| `getAttendanceForEmployee()`| StaffProfileView / Attendance Log | Mapped | Stubbed | Bearer Included | Passed | Blocked (No API) | Define date aggregation format (High) |
| `GET /api/hr/leaves` | `getLeaves()` | HR Dashboard / Pending Reviews | Mapped | Stubbed | Bearer Included | Passed | Blocked (No API) | Define leave status enums (Medium) |
| `GET /api/hr/leaves/:id` | `getLeaveDetails()` | *N/A (Future use)* | Mapped | Stubbed | Bearer Included | N/A | Blocked (No API) | Implement dedicated leave view (Low) |
| `PUT /api/hr/leaves/:id/approve`| `approveLeave()` | HR Dashboard / Approve Button | Mapped | Expects 200 Status | Bearer Included | Passed | Blocked (No API) | Verify idempotency (Medium) |
| `PUT /api/hr/leaves/:id/reject` | `rejectLeave()` | HR Dashboard / Reject Button | Mapped | Expects 200 Status | Bearer Included | Passed | Blocked (No API) | Add reject reason field to API (High) |
| `GET /api/hr/reports/attendance`| `getAttendanceReport()` | *Blocked (Missing UI)* | Mapped | Stubbed | Bearer Included | N/A | Blocked (No API) | Provide statistical data contract (High) |
| `GET /api/hr/reports/leaves` | `getLeavesReport()` | *Blocked (Missing UI)* | Mapped | Stubbed | Bearer Included | N/A | Blocked (No API) | Provide statistical data contract (High) |

## Overview
This document catalogs every HR Admin screen...
* **File:** `hr_dashboard_view.dart`
* **Features:** KPI Metric Cards, Pending Review Banners (Leaves/Resignations), Employee Search & Filter Directory.
* **Provider Method:** `fetchDashboardData()`
* **API Endpoints Required:** 
  - `GET /api/hr/dashboard` (Metrics)
  - `GET /api/hr/employees` (Directory list)
  - `GET /api/hr/leaves` (Pending reviews)
  - `GET /api/hr/attendance` (Present statuses)
* **Status:** 
  - **Request Contract:** Mapped in `ApiService`.
  - **UI State:** Functional using mock data.
  - **Authentication:** Mapped in `ApiService._headers()` using Bearer token.
  - **Live Verification:** Blocked (API not deployed).

### 2. Add Employee Action (Modal)
* **File:** `modals.dart` (`showAddStaffModal`)
* **Features:** Form to input Name, Email, Phone, Department.
* **Provider Method:** `addStaff(Map<String, dynamic>)`
* **API Endpoint Required:** `POST /api/hr/employees`
* **Status:** 
  - **Request Contract:** Mapped in `ApiService`. Expects JSON body.
  - **UI State:** Fully interactive. Local state mutates and re-renders successfully.
  - **Live Verification:** Blocked.

### 3. Edit Employee Action (Modal)
* **File:** `modals.dart` (`showEditStaffModal`)
* **Features:** Form pre-filled with selected employee details.
* **Provider Method:** `updateStaff(String id, Map<String, dynamic>)`
* **API Endpoint Required:** `PUT /api/hr/employees/:id`
* **Status:** 
  - **UI State:** Functional using mock target ID. 
  - **Live Verification:** Blocked.

### 4. Approve / Reject Leave (Action Banner)
* **File:** `hr_dashboard_view.dart`
* **Features:** Quick action buttons on pending leaves.
* **Provider Method:** `reviewLeave(String id, bool approved)`
* **API Endpoints Required:** 
  - `PUT /api/hr/leaves/:id/approve`
  - `PUT /api/hr/leaves/:id/reject`
* **Status:** 
  - **UI State:** Functional. Tapping removes/updates the local mock state.
  - **Live Verification:** Blocked.

### 5. Staff Profile View (Detail Screen)
* **File:** `staff_profile_view.dart`
* **Features:** Deep dive into specific employee attendance log, active tasks, daily updates, and "Mark Resigned" button.
* **Provider Method:** `viewStaffProfile(id)` / `deactivateStaff(id)`
* **API Endpoints Required:**
  - `GET /api/hr/attendance/:empId`
  - `GET /api/hr/employees/:id` (Optional, if deep-linked)
  - `DELETE /api/hr/employees/:id` (For deactivation)
* **Status:** 
  - **Request Contract:** Mapped.
  - **UI State:** Uses filtered local lists. The Deactivate action successfully warns via confirmation dialog before mutating local state.
  - **Live Verification:** Blocked.

### 6. Reports & Charts (Missing/Blocked)
* **Features:** Visual charting of attendance and leaves.
* **API Endpoints Required:**
  - `GET /api/hr/reports/attendance`
  - `GET /api/hr/reports/leaves`
* **Status:** 
  - **UI State:** **Missing**. No UI exists in Flutter for these because drawing accurate charts requires the exact aggregation schema from the backend, which is undocumented. Creating fake chart schemas was explicitly avoided.

## Test Summary
* **Widget Tests (`flutter test`):** 6/6 Passed. Evaluates local interactions and `HRProvider` successfully without requiring backend.
* **Analysis (`flutter analyze`):** Passed cleanly with standard deprecation infos.
* **Web Build:** Complete and ready for deployment.
