# Integration Report — Screen 9: Task Management

**Date:** October 16, 2026  
**Screen:** Screen 9 (Task Management)  
**Frontend Path:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**Backend Path:** `C:\Users\Admin\Downloads\HrsystemBackend`  
**API Reference:** `C:\Users\Admin\Downloads\HrsystemBackend\docs\hr_backend_api_contract.md`  

---

## 1. Executive Summary

Screen 9 (Task Management) integrates the LY Software HR Management Flutter dashboard with the Express backend task subsystem. 

Prior to integration, Task Management relied strictly on local in-memory mock lists (`tasksList`) without API synchronization. Following integration, the screen:
- Connects directly to the documented backend Task endpoints for listing, creating, updating, and soft-deleting tasks.
- Supports server-side filtering by task status (`pending`, `in-progress`, `done`, `cancelled`), department (`Tech`, `Telecalling`), and employee ID.
- Supports server-side pagination with limit and page offsets.
- Implements optimistic UI updates with automatic authoritative server refresh post-mutation.
- Enforces strict isolation against stale mock records: if an API error occurs, `filteredTasksList` yields `[]` rather than masquerading fake mock tasks as live server data.
- Preserves the existing UI, colors, layout, and the Daily Updates log column without inventing non-existent backend APIs.

---

## 2. API Contract & Endpoint Specification

Task management routes are defined in `routes/hrRoutes.js` (lines 70–74), handled by `controllers/taskController.js`, and executed by `services/taskService.js`:

### 2.1 List Tasks
- **Endpoint:** `GET /api/hr/tasks`
- **Method:** `GET`
- **Authorization:** `Bearer <accessToken>` (HR Role required)
- **Query Parameters:**
  - `status`: string (optional, `'pending'`, `'in-progress'`, `'done'`, `'cancelled'`)
  - `department`: string (optional, `'Tech'`, `'Telecalling'`)
  - `employeeId`: string (optional, employee ObjectId or `EMP1001` format)
  - `page`: integer (default `1`)
  - `limit`: integer (default `20` / `50`, capped at `100`)
- **Backend Service:** `taskService.getTasks({ status, department, employeeId, page, limit })`
- **Success Response (200):**
  ```json
  {
    "success": true,
    "message": "Tasks retrieved successfully",
    "data": [
      {
        "id": "670c...",
        "_id": "670c...",
        "staffId": "emp_101",
        "employeeId": "EMP1001",
        "employeeName": "Anita Rao",
        "department": "Tech",
        "title": "API Performance Tuning",
        "description": "Optimize DB queries and cache leave balances",
        "status": "in-progress",
        "date": "2026-10-15",
        "dueDate": "2026-10-22",
        "createdAt": "2026-10-15T09:00:00.000Z"
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

### 2.2 Create & Assign Task
- **Endpoint:** `POST /api/hr/tasks`
- **Method:** `POST`
- **Authorization:** `Bearer <accessToken>` (HR Role required)
- **Request Body:**
  ```json
  {
    "staffId": "EMP1001",
    "department": "Tech",
    "description": "Prepare system architecture documentation",
    "dueDate": "2026-10-30",
    "title": "Architecture Docs"
  }
  ```
- **Backend Service:** `taskService.createTask({ staffId, employeeId, description, department, dueDate, title, user })`
- **Success Response (201):**
  Returns created task document populated with employee details (`employeeId`, `firstName`, `lastName`, `department`, `designation`).

### 2.3 Get Task Details
- **Endpoint:** `GET /api/hr/tasks/:id`
- **Method:** `GET`
- **Authorization:** `Bearer <accessToken>` (HR Role required)
- **Success Response (200):** Task details object.

### 2.4 Update Task
- **Endpoint:** `PUT /api/hr/tasks/:id`
- **Method:** `PUT`
- **Authorization:** `Bearer <accessToken>` (HR Role required)
- **Request Body:**
  ```json
  {
    "title": "Optional new title",
    "description": "Optional updated description",
    "dueDate": "YYYY-MM-DD",
    "status": "pending | in-progress | done | cancelled",
    "department": "Tech",
    "staffId": "EMP1001"
  }
  ```
- **Backend Service:** `taskService.updateTask(taskId, updateData)`
- **Success Response (200):** Updated task document.

### 2.5 Delete Task
- **Endpoint:** `DELETE /api/hr/tasks/:id`
- **Method:** `DELETE`
- **Authorization:** `Bearer <accessToken>` (HR Role required)
- **Backend Service:** `taskService.deleteTask(taskId)` (marks `isDeleted = true`)
- **Success Response (200):** `{ "success": true, "message": "Task deleted successfully", "data": null }`

---

## 3. Frontend Implementation & Architecture

### 3.1 Domain Model Updates (`lib/models/hr_models.dart`)
- **Extended `Task`:** Added `title`, `employeeId`, `employeeName`, `createdAt`, `Task.fromJson`, `toJson`, and `copyWith`.
  - Safely extracts employee references whether populated as a nested object (`employee.firstName`, `employee.lastName`, `employee.employeeId`) or string reference.
- **Added `TaskPage`:** Packaging `List<Task>`, `page`, `limit`, `total`, and `totalPages`.

### 3.2 Service Layer (`lib/services/api_service.dart`)
- Added `ApiService.getTasksPage({int page, int limit, String? status, String? department, String? employeeId})`.
- Added `ApiService.getTaskDetails(String id)`.
- Added `ApiService.createTask({required String staffId, required String description, required String dueDate, String? department, String? title})`.
- Added `ApiService.updateTask(String id, {String? title, String? description, String? dueDate, String? status, String? department, String? staffId})`.
- Added `ApiService.deleteTask(String id)`.
- Added `ApiService.hasToken` helper getter.

### 3.3 State Management (`lib/providers/hr_provider.dart`)
- **State Fields:** `taskStatusFilter`, `taskDeptFilter`, `taskSearchQuery`, `isTasksLoading`, `tasksError`, `tasksPage`, `tasksLimit`, `tasksTotal`, `tasksTotalPages`, `hasLoadedApiTasks`, `apiTasksList`.
- **Async Loader (`loadTasks`):** Fetches paginated tasks from backend, updates metadata, guards against request version races with `_tasksRequestVersion`.
- **Stale Mock Data Prevention:** If `tasksError != null && !hasLoadedApiTasks`, `filteredTasksList` returns `const []`.
- **Filter-Triggered Page Resets:** Setting status filter, department filter, or search query resets `tasksPage = 1` and triggers `loadTasks()`.
- **Mutations & Server Refresh:**
  - `assignTask`: creates task via `ApiService.createTask` and reloads from server.
  - `updateTaskStatus`: updates status via `ApiService.updateTask` and reloads from server.
  - `deleteTask`: soft-deletes task via `ApiService.deleteTask` and reloads from server.
  - In offline / mock mode (prior to API connection), updates local state to maintain test coverage and UX continuity.

### 3.4 User Interface (`lib/features/tasks/tasks_view.dart`)
- **Header:** Added title, subtitle, refresh button with spinner feedback, and "Assign New Task" button connected to `Modals.showAssignTaskModal(context)`.
- **Error Banner:** Displays red alert container with a **Retry** button when `tasksError` occurs.
- **Filters:**
  - Status filter chips: All Tasks, Pending, In Progress, Done, Cancelled.
  - Department filter dropdown: All Departments, Tech, Telecalling.
  - Search input: searches title, description, and employee name/ID.
- **Task Cards:** Render title, description, status badge, assigned staff name, department, due date, done checkbox toggle, and delete action button with confirmation dialog.
- **Pagination Footer:** Displays `Showing X to Y of Z tasks` with Previous and Next page controls when `tasksTotalPages > 1`.
- **Daily Updates Stream:** Maintained side column displaying daily work logs without fabricating non-existent backend APIs.

---

## 4. Unsupported Features & Remaining Blockers

| Feature | Backend Status | Client Handling | Recommended Next Step |
| :--- | :--- | :--- | :--- |
| **Daily Work Updates API** (`GET /api/hr/daily-updates` or `POST /api/staff/daily-updates`) | **Unsupported** in backend contract & routes | Stream displays local staff work logs | If daily logs should be persisted to MongoDB, add a `DailyUpdate` schema, controller, and routes to Express backend. |
| **Task Priority Field** (`priority: LOW / MEDIUM / HIGH`) | **Not modeled in `models/Task.js`** | Status badges and dates prioritize tasks; no priority field is sent to server | Add `priority` enum to `models/Task.js` if priority sorting is needed. |

---

## 5. Verification & Test Evidence

### 5.1 Changed Files
1. `lib/models/hr_models.dart`: Added `Task.fromJson`, `toJson`, `copyWith`, and `TaskPage`.
2. `lib/services/api_service.dart`: Added `getTasksPage`, `getTaskDetails`, `createTask`, `updateTask`, `deleteTask`, and `hasToken`.
3. `lib/providers/hr_provider.dart`: Added task state variables, filters, pagination, `loadTasks`, `assignTask`, `updateTaskStatus`, `deleteTask`, and `filteredTasksList`.
4. `lib/features/tasks/tasks_view.dart`: Integrated with provider, added error banner, refresh button, department filter, search bar, and delete action.
5. `test/task_management_api_test.dart`: Created new targeted test suite (14 test cases).

### 5.2 Formatting (`dart format`)
```text
Formatted lib/models/hr_models.dart
Formatted test/task_management_api_test.dart
Formatted 5 files (0 changed) in 0.46 seconds.
Exit Code: 0
```

### 5.3 Targeted Test Suite (`flutter test test/task_management_api_test.dart`)
```text
00:00 +0: ApiService.getTasksPage calls GET /api/hr/tasks with auth token, pagination, and filters
00:00 +1: ApiService.getTasksPage handles empty task list and server error response safely
00:00 +2: ApiService.getTasksPage throws exception on 401 unauthorized or 500 server error
00:00 +3: ApiService Task Mutations createTask sends POST /api/hr/tasks and returns populated task
00:00 +4: ApiService Task Mutations updateTask sends PUT /api/hr/tasks/:id and returns updated record
00:00 +5: ApiService Task Mutations deleteTask sends DELETE /api/hr/tasks/:id and returns true on success
00:00 +6: HRProvider Task State Integration loadTasks fetches paginated tasks and updates provider state
00:00 +7: HRProvider Task State Integration prevents stale mock data and sets error on API failure
00:00 +8: HRProvider Task State Integration filter changes reset current page to 1 and reload data
00:00 +9: HRProvider Task State Integration assignTask, updateTaskStatus, and deleteTask call APIs and refresh state
00:01 +10: TasksView Widget Tests renders loaded tasks, status chips, and daily update panel
00:07 +11: TasksView Widget Tests renders error banner with Retry button when tasksError is set
00:08 +12: TasksView Widget Tests status filter chip selects filter and updates state
00:10 +13: TasksView Widget Tests delete task shows confirmation dialog and executes deletion
00:11 +14: All tests passed!

Exit Code: 0
```

### 5.4 Static Analysis (`flutter analyze --no-fatal-infos`)
```text
Analyzing flutter_src...
26 issues found. (all pre-existing info lints in unrelated files; 0 errors, 0 warnings)
Exit Code: 0
```

### 5.5 Full Regression Suite (`flutter test`)
```text
All 143 tests passed across all test files in flutter_src!
Exit Code: 0
```

### 5.6 Live Backend Verification Status
- **Status:** **BLOCKED**
- **Reason:** The Node.js Express backend (`server.js`) is offline on localhost ports 3000 and 5000. All test results reported above reflect mocked unit/widget tests. No claims of live backend execution are made without live server availability.

---

## 6. Next Steps
1. Report Screen 9 completion and verification results to the user.
2. Await user confirmation before proceeding to Screen 10 (Department Chat & Messaging integration).
