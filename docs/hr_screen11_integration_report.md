# Integration Report — Screen 11: Department Chat & Messaging

**Date:** October 16, 2026  
**Screen:** Screen 11 (Department Chat & Messaging)  
**Frontend Path:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**Backend Path:** `C:\Users\Admin\Downloads\HrsystemBackend`  
**API Reference:** `C:\Users\Admin\Downloads\HrsystemBackend\docs\hr_backend_api_contract.md` (Section 10)  

---

## 1. Executive Summary

Screen 11 (**Department Chat & Messaging**, route `'dept-chat'`, implemented in `DepartmentChatView`) integrates the LY Software HR Management Flutter dashboard with the documented Express backend chat service.

### Screen Identification & Feature Audit
1. **Sidebar & Route Inspection:** The application navigation maps the following HR views:
   - Screen 1: Login (`LoginView`)
   - Screen 2: HR Dashboard (`HRDashboardView`)
   - Screen 3: Employee Directory (`EmployeesView`)
   - Screen 4: Staff Profile & Documents (`StaffProfileView`)
   - Screen 5: Departments (`DepartmentsView`)
   - Screen 6: Attendance Management (`AttendanceView`)
   - Screen 7: Leave Management (`LeaveManagementView`)
   - Screen 8: Payroll Processing (`PayrollView`)
   - Screen 9: Task Management (`TasksView`)
   - Screen 10: Announcements & Notifications (`AnnouncementsNotificationsView`)
   - **Screen 11: Department Chat & Messaging (`DepartmentChatView`)**
   - *Note on Reports & Analytics (`ReportsView`):* While `ReportsView` exists in the frontend sidebar, neither the backend contract (`hr_backend_api_contract.md`) nor `routes/hrRoutes.js` contains any analytics or reports endpoints. Department Chat is the active feature with a full backend specification in Section 10 of the contract.

2. **Previous Implementation Defects Resolved:**
   - Previous frontend methods in `api_service.dart` (lines 717–837) targeted obsolete URLs (`$baseUrl/hr/departments/...` missing the mandatory `/api/` prefix).
   - In-flight network exceptions were previously swallowed with empty `catch (_) {}` blocks, preventing the UI from detecting server errors.
   - `hr_provider.dart` lacked an async loader (`loadDepartmentMessages`) and relied purely on in-memory mock data.
   - `DepartmentChatView` initialized by only clearing its own loading indicator without invoking a remote fetch or presenting an error/retry banner when offline.

3. **Verification Constraints:**
   - **No mock data masquerading as live server data:** If the API fails or is unreachable, the UI renders a prominent error state with a **Retry Connection** action rather than silently showing mock messages.
   - **No fabricated endpoints:** 1-on-1 private direct messaging stubs (`/hr/chat/messages/:id`) were confirmed to have no backend route or contract support, and were not fabricated into live services.
   - **Targeted & Full Regression Testing:** 15 dedicated mocked tests were implemented and passed cleanly. All 170 Flutter project tests pass with exit code 0.
   - **Live API status:** Real HTTP integration is explicitly marked **BLOCKED** because the local backend Express server is offline.

---

## 2. API Contract & Supported Operations

All endpoints for Department Chat are specified in Section 10 of `hr_backend_api_contract.md`, mounted in `routes/hrRoutes.js` (lines 77–80), handled by `controllers/chatController.js`, and executed by `services/chatService.js` backed by the `DepartmentChatMessage` Mongoose model.

### 2.1 Fetch Department Messages
- **Endpoint:** `GET /api/hr/departments/:deptKey/messages` (also available as `GET /api/staff/departments/:deptKey/messages`)
- **Authorization:** `Bearer <accessToken>` (HR or STAFF)
- **Parameters:** `deptKey` (`'tech'`, `'telecalling'`)
- **Query Parameters:** `page`, `limit` (default: 100)
- **Backend Controller:** `chatController.getDepartmentMessages`
- **Backend Service:** `chatService.getDepartmentMessages(deptKey, user, { limit, page })`
- **Behavior:** Queries messages where `departmentKey == deptKey`, `deletedForEveryone == false`, and `deletedByIds` does NOT contain the caller's ID. Messages are sorted chronologically (`timestamp: 1`).
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Department messages retrieved successfully",
    "data": [
      {
        "id": "670f5e12...",
        "_id": "670f5e12...",
        "departmentKey": "tech",
        "senderId": "670cb...",
        "senderName": "Arjun Desai",
        "text": "Staging build deployed successfully.",
        "timestamp": "2026-10-16T09:30:00.000Z",
        "isRead": true,
        "deletedForEveryone": false,
        "deletedByIds": []
      }
    ]
  }
  ```

### 2.2 Send Department Message
- **Endpoint:** `POST /api/hr/departments/:deptKey/messages` (also available as `POST /api/staff/departments/:deptKey/messages`)
- **Authorization:** `Bearer <accessToken>` (HR or STAFF)
- **Parameters:** `deptKey`
- **Request Body:**
  ```json
  {
    "text": "Please log today's sprint updates.",
    "senderName": "Anita Roy (HR Manager)"
  }
  ```
- **Backend Controller:** `chatController.sendDepartmentMessage`
- **Backend Service:** `chatService.sendDepartmentMessage(deptKey, text, user, customSenderName)`
- **Behavior:** Creates a `DepartmentChatMessage` document with verified caller ID, sender name, timestamp, and default deletion flags.
- **Success Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Message sent successfully",
    "data": {
      "id": "670f6120...",
      "_id": "670f6120...",
      "departmentKey": "tech",
      "senderId": "admin_1",
      "senderName": "Anita Roy (HR Manager)",
      "text": "Please log today's sprint updates.",
      "timestamp": "2026-10-16T11:00:00.000Z",
      "isRead": false,
      "deletedForEveryone": false,
      "deletedByIds": []
    }
  }
  ```

### 2.3 Delete Message for Me
- **Endpoint:** `PATCH /api/hr/departments/:deptKey/messages/:messageId/delete-for-me`
- **Authorization:** `Bearer <accessToken>` (HR or STAFF)
- **Parameters:** `deptKey`, `messageId`
- **Request Body:** `{ "userId": "<callerId>" }`
- **Backend Controller:** `chatController.deleteMessageForMe`
- **Backend Service:** `chatService.deleteMessageForMe(messageId, userId)`
- **Behavior:** Appends caller ID to `deletedByIds` array. The message becomes invisible to this caller while remaining visible to others.
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Message deleted for user successfully",
    "data": null
  }
  ```

### 2.4 Delete Message for Everyone
- **Endpoint:** `DELETE /api/hr/departments/:deptKey/messages/:messageId`
- **Authorization:** `Bearer <accessToken>` (HR or message sender)
- **Parameters:** `deptKey`, `messageId`
- **Backend Controller:** `chatController.deleteMessageForEveryone`
- **Backend Service:** `chatService.deleteMessageForEveryone(messageId, user)`
- **Behavior:** Validates that the caller is either an HR Manager or the original message sender. Sets `deletedForEveryone = true`, `deletedForEveryoneBy = user._id`, and `deletedForEveryoneAt = new Date()`. Non-HR staff attempting to delete peer messages receive `403 Forbidden`.
- **Success Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Message deleted for everyone successfully",
    "data": null
  }
  ```

---

## 3. Files Changed & Implementation Details

### 3.1 `lib/models/hr_models.dart`
- **File:** [hr_models.dart](file:///C:/Users/Admin/Downloads/HR-dashboard/flutter_src/lib/models/hr_models.dart#L547-L567)
- **Changes:**
  - Updated `ChatMessage.fromJson` factory to fall back to `json['_id']` if `json['id']` is absent (standard Mongoose ObjectId serialization).
  - Added fallback parsing from `json['createdAt']` when `json['timestamp']` is null.
  - Preserved existing `deletedForEveryone` and `deletedByIds` model logic.

### 3.2 `lib/services/api_service.dart`
- **File:** [api_service.dart](file:///C:/Users/Admin/Downloads/HR-dashboard/flutter_src/lib/services/api_service.dart#L717-L865)
- **Changes:**
  - Replaced legacy `$baseUrl/hr/departments/...` URL paths with `$baseUrl/api/hr/departments/${Uri.encodeComponent(deptKey)}/...`.
  - Added URL parameter encoding for `deptKey` and `messageId`.
  - Removed silent `catch (_) {}` blocks; methods now throw descriptive exceptions on HTTP 4xx/5xx responses.
  - Configured `deleteDepartmentMessageForMe` and `deleteDepartmentMessageForEveryone` to parse error envelopes and rethrow `DeletionPermissionException` on HTTP 403.

### 3.3 `lib/providers/hr_provider.dart`
- **File:** [hr_provider.dart](file:///C:/Users/Admin/Downloads/HR-dashboard/flutter_src/lib/providers/hr_provider.dart#L158-L165) and [hr_provider.dart](file:///C:/Users/Admin/Downloads/HR-dashboard/flutter_src/lib/providers/hr_provider.dart#L2565-L2815)
- **Changes:**
  - Added state variables: `bool isDepartmentChatLoading`, `String? departmentChatError`, `bool hasLoadedApiDepartmentChat`, and request version counter `_departmentChatRequestVersion`.
  - Added `loadDepartmentMessages(String deptKey)`: sets loading state, executes `ApiService.getDepartmentMessages(deptKey)`, updates the thread in `departmentChatThreads`, sets `hasLoadedApiDepartmentChat = true`, and catches errors cleanly into `departmentChatError`.
  - Updated `getDepartmentThread(String deptKey)`: when `departmentChatError != null && !hasLoadedApiDepartmentChat`, returns thread with empty messages (`messages: const []`) to strictly prevent mock messages from being presented as live server data on failure.
  - Updated `sendDepartmentMessage`: optimistically inserts message into local thread, dispatches to `ApiService.sendDepartmentMessage`, and refreshes from the backend upon completion.
  - Updated `deleteDepartmentMessageForMe` and `deleteDepartmentMessageForEveryone` to synchronize with live endpoints when online.

### 3.4 `lib/features/chat/department_chat_view.dart`
- **File:** [department_chat_view.dart](file:///C:/Users/Admin/Downloads/HR-dashboard/flutter_src/lib/features/chat/department_chat_view.dart#L35-L65) and [department_chat_view.dart](file:///C:/Users/Admin/Downloads/HR-dashboard/flutter_src/lib/features/chat/department_chat_view.dart#L130-L270)
- **Changes:**
  - `_loadMessages`: triggers `hrProvider.loadDepartmentMessages(widget.departmentKey)` in a post-frame callback with mount protection.
  - Stream layout: switches dynamically between `CircularProgressIndicator` (initial load), `_buildErrorState` (when loading fails), and the active group chat stream.
  - Added header **Refresh Messages** button (`Icons.refresh`) with loading indicator.
  - Updated `_buildErrorState`: displays server error text and a **Retry Connection** button wired to `hrProvider.loadDepartmentMessages`.
  - Wrapped header titles and department member list titles in `Flexible` / `Expanded` with `TextOverflow.ellipsis` to prevent render flex overflow on compact viewports.

### 3.5 `test/department_chat_api_test.dart`
- **File:** [department_chat_api_test.dart](file:///C:/Users/Admin/Downloads/HR-dashboard/flutter_src/test/department_chat_api_test.dart)
- **Changes:**
  - Created 15 targeted tests covering ApiService parsing, error handling, permission exceptions, HRProvider state management, optimistic updates, stale mock isolation, and `DepartmentChatView` widget rendering / retry behavior.

---

## 4. Verification & Test Results

### 4.1 Formatting
```powershell
dart format lib/services/api_service.dart lib/models/hr_models.dart lib/providers/hr_provider.dart lib/features/chat/department_chat_view.dart test/department_chat_api_test.dart
```
**Result:** Exit code `0`. All files formatted cleanly.

### 4.2 Targeted Department Chat Tests
```powershell
flutter test test/department_chat_api_test.dart
```
**Result:** Exit code `0`.
```
00:06 +15: All tests passed!
```
**Breakdown of targeted tests:**
1. `getDepartmentMessages parses envelope and message fields correctly` (Passed)
2. `getDepartmentMessages throws descriptive exception when endpoint fails` (Passed)
3. `sendDepartmentMessage dispatches POST with text and senderName` (Passed)
4. `sendDepartmentMessage throws exception when server rejects request` (Passed)
5. `deleteDepartmentMessageForMe dispatches PATCH to correct endpoint` (Passed)
6. `deleteDepartmentMessageForMe throws DeletionPermissionException on 403` (Passed)
7. `deleteDepartmentMessageForEveryone dispatches DELETE to endpoint` (Passed)
8. `deleteDepartmentMessageForEveryone throws DeletionPermissionException on 403` (Passed)
9. `loadDepartmentMessages successfully populates thread and sets hasLoadedApiDepartmentChat` (Passed)
10. `loadDepartmentMessages failure sets departmentChatError and isolates from presenting mock data as live` (Passed)
11. `sendDepartmentMessage optimistically updates state and triggers sync` (Passed)
12. `deleteDepartmentMessageForMe marks message hidden for caller` (Passed)
13. `deleteDepartmentMessageForEveryone removes message from thread when authorized` (Passed)
14. `DepartmentChatView renders header, member info, and message input` (Passed)
15. `DepartmentChatView displays error state and retry button on load failure` (Passed)

### 4.3 Static Analysis
```powershell
flutter analyze --no-fatal-infos
```
**Result:** Exit code `0`. No errors or warnings in changed code. (28 pre-existing style info items in unrelated files).

### 4.4 Full Project Regression Suite
```powershell
flutter test
```
**Result:** Exit code `0`. All 170 project tests across 12 test suites passed:
```
00:58 +170: All tests passed!
```

---

## 5. Live Backend Verification Status

| Status | Details |
|---|---|
| **BLOCKED** | Probe checks to `http://localhost:5000/api/health` and `http://localhost:3000/api/health` confirmed the Node/Express backend process is not currently running. No live HTTP network traffic could be exchanged. |

*In accordance with project instructions, mocked test success is not claimed as live server verification.*

---

## 6. Gap Analysis & Unsupported Features

1. **Reports & Analytics Gap:**
   - Frontend includes `ReportsView` (`features/reports/reports_view.dart`) and a sidebar item.
   - The backend contract (`hr_backend_api_contract.md`) and routes (`routes/hrRoutes.js`) contain **no** analytics or reporting endpoints.
   - **Recommendation:** If a Reports screen is integrated in future phases, backend endpoints (e.g. `GET /api/hr/reports/headcount`, `GET /api/hr/reports/attrition`) must first be specified in the contract and implemented in `HrsystemBackend`.

2. **1-on-1 Direct Messaging Gap:**
   - `api_service.dart` had stub methods `getPrivateMessages` and `sendPrivateMessage` pointing to `/hr/chat/messages/:id`.
   - The backend contract Section 10 only specifies Department Group Messaging (`/api/hr/departments/:deptKey/messages`).
   - Direct 1-on-1 private messaging has no backing backend model or routes in the current contract.

3. **Remaining Blockers:**
   - Launching the Express server (`node server.js` in `HrsystemBackend`) with active MongoDB credentials is required for live network verification.
