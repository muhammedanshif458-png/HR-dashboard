# HR API Integration Mismatch & Blockers Report

**Date:** 2026-10-09  
**Project:** LY-HR_dashboard_flutter

This document highlights critical discrepancies, missing contracts, and business logic warnings discovered during the Flutter UI migration that must be resolved prior to live API integration.

## 1. Schema & Envelope Unknowns
The Flutter codebase currently maps models (`Staff`, `Attendance`, `LeaveRequest`) based on presumed flat JSON structures (e.g., `{ id, name, department }`). 
* **Warning:** The actual backend may wrap responses in envelopes like `{ "success": true, "data": [...] }`. `ApiService` currently attempts to check for `['data']` as a fallback, but the exact envelope structure must be rigidly defined.
* **MongoDB IDs:** The Flutter UI uses `String id`. If the backend uses `_id` from MongoDB, the JSON mapping (`fromJson`) in the models will need to be updated to map `_id` to `id`.

## 2. Business Logic Discrepancies
### Deactivation vs. Resignation
* The UI refers to deactivating an employee as "Mark Resigned". The API contract specifies `DELETE /api/hr/employees/:id`. 
* **Mismatch:** A `DELETE` verb traditionally destroys a record entirely. If HR needs to retain the employee's history but flag them as "resigned", the backend should ideally use a `PUT /api/hr/employees/:id/status` endpoint. Using `DELETE` for soft-deletes or status updates is an anti-pattern. 

### Tasks & Daily Updates
* The Staff Profile view displays a "Tasks" list and "Daily Updates" list for an employee.
* **Mismatch:** The provided API contract **does not include endpoints for fetching Tasks or Daily Updates**. 
* **Resolution Required:** The backend team must deliver `GET /api/hr/tasks?employeeId=` and `GET /api/hr/updates?employeeId=` or equivalent routes, otherwise the UI will forever display empty states for these columns.

## 3. Blocked UI Features
### Reports and Charts
* Endpoints `GET /api/hr/reports/attendance` and `GET /api/hr/reports/leaves` exist in the contract.
* **Blocker:** The response schema (e.g., whether it returns time-series data, aggregated counts, or raw logs) is entirely undocumented. The Flutter UI for rendering these charts is deliberately halted to prevent building incompatible chart plotting logic.

## 4. Environment Configuration Safeties
* The Flutter environment utilizes `String.fromEnvironment('API_BASE_URL')`.
* There are no hardcoded secrets, tokens, or localhost strings buried in the services. 
* The UI defensively handles `UnimplementedError` and network exceptions by pushing standard `SnackBar` alerts instead of failing silently.
