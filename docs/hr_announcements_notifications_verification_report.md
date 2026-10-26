# Screen 10: Announcements & Notifications — Verification & Audit Report

**Date:** October 16, 2026  
**Auditor:** Antigravity Verification Agent  
**Frontend Path:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**Backend Path:** `C:\Users\Admin\Downloads\HrsystemBackend`  
**API Contract:** `C:\Users\Admin\Downloads\HrsystemBackend\docs\hr_backend_api_contract.md`  
**Audit Scope:** Verification-only audit of Screen 10 (Announcements & Notifications). No application code modified during audit.

---

## 1. Executive Summary & Verification Matrix

| Verification Category | Status | Code Evidence & Audit Finding |
| :--- | :---: | :--- |
| **1. Backend Contract & Route Audit** | **UNSUPPORTED (Verified)** | `hr_backend_api_contract.md` (lines 288–308) designates Section 10 strictly for `Department Chat & Messaging`. No routes for announcements (`/api/hr/announcements`) or notifications (`/api/hr/notifications`) exist in `routes/hrRoutes.js`. |
| **2. Backend Models & Services Audit** | **UNSUPPORTED (Verified)** | `models/` contains only `Attendance`, `DepartmentChatMessage`, `Employee`, `HRDocument`, `Leave`, `Task`, `User`. No `Announcement.js` or `Notification.js` models exist. No controllers or services exist. |
| **3. API Service Transparency** | **PASS** | `ApiService.getAnnouncements`, `getNotifications`, and `createAnnouncement` include explicit documentation comments noting their staged status. If called, they isolate HTTP 404 cleanly and do not pretend to be connected to a live server. |
| **4. Persistence Verification** | **PASS (Documented)** | Announcements and notifications are **temporary in-memory state only** in `HRProvider` (`announcementsList`, `notificationsList`). They are **not persisted** to MongoDB, SQLite, SharedPreferences, or file storage. |
| **5. Read State Transitions** | **PASS (Documented)** | `markNotificationAsRead` and `markAllNotificationsAsRead` operate **strictly in local memory**. No backend endpoints exist for read receipts. |
| **6. Staged vs. Server Differentiation** | **PASS** | The screen displays a prominent **Backend Capability Status Banner** disclosing staged mode. `filteredAnnouncements` yields `[]` on API error to prevent masquerading mock records as live data. |
| **7. Badge Counters Consistency** | **PASS** | Unread counters on the Header notification bell and Sidebar `Announcements` item derive reactively from `unreadNotificationsCount`. |
| **8. Automated Tests** | **PASS** | Targeted test suite: **12 / 12 passed** (Exit Code 0). Full regression test suite: **155 / 155 passed** (Exit Code 0). Static analysis: **0 errors, 0 warnings** (Exit Code 0). |
| **9. Live Backend Probing** | **BLOCKED** | Probed `http://localhost:5000/api/health` and `http://localhost:3000/api/health`; both offline (connection refused). Endpoints do not exist on backend. |

---

## 2. In-Depth Backend Contract & Implementation Verification

### 2.1 Backend Contract Inspection (`docs/hr_backend_api_contract.md`)
Lines 288–308 of `hr_backend_api_contract.md`:
```markdown
## 10. Department Chat & Messaging

### `GET /api/hr/departments/:deptKey/messages` & `GET /api/staff/departments/:deptKey/messages`
### `POST /api/hr/departments/:deptKey/messages` & `POST /api/staff/departments/:deptKey/messages`
### `PATCH /api/hr/departments/:deptKey/messages/:messageId/delete-for-me`
### `DELETE /api/hr/departments/:deptKey/messages/:messageId`
```
- **Finding:** The backend contract defines **no** section for Announcements or Notifications. Section 10 is exclusively Department Chat & Messaging.

### 2.2 Backend Routes Inspection (`routes/hrRoutes.js`)
Lines 1–84 of `routes/hrRoutes.js`:
- Mounted endpoints:
  - Auth: `/auth/*`
  - HR Dashboard: `/api/hr/dashboard`, `/api/hr/birthdays`
  - Departments: `/api/hr/departments`, `/api/hr/departments/:deptKey`
  - Employees: `/api/hr/employees`, `/api/hr/employees/:id`, `/api/hr/employees/:id/status`, `/api/hr/employees/:id/salary`
  - Documents: `/api/hr/employees/:id/documents`, `/api/hr/documents/:docId`, etc.
  - Attendance: `/api/hr/attendance`, `/api/hr/attendance/:employeeId`
  - Leaves: `/api/hr/leaves`, `/api/hr/leaves/:id`, `/api/hr/leaves/:id/approve`, `/api/hr/leaves/:id/reject`
  - Payroll: `/api/hr/payroll/summary`, `/api/hr/payroll/employees`, `/api/hr/payroll/employees/:employeeId`
  - Tasks: `/api/hr/tasks`, `/api/hr/tasks/:id`
  - Chat: `/api/hr/departments/:deptKey/messages`
- **Finding:** No routes match `/api/hr/announcements` or `/api/hr/notifications`.

### 2.3 Backend Models Inspection (`models/`)
Listing files in `C:\Users\Admin\Downloads\HrsystemBackend\models`:
```
Attendance.js
DepartmentChatMessage.js
Employee.js
HRDocument.js
Leave.js
Task.js
User.js
```
- **Finding:** There is no `Announcement.js` or `Notification.js` schema in the backend Mongoose models.

---

## 3. Frontend Implementation & Service Audit

### 3.1 Service Layer Methods (`lib/services/api_service.dart`)
- **`ApiService.getAnnouncements()`**:
  - Target URI: `GET $baseUrl/api/hr/announcements`.
  - Header: Authorization Bearer token.
  - Behavior: If server returns 404 (actual backend behavior), throws `Exception('Failed to fetch announcements (HTTP 404)')`.
  - Staged comments:
    `/// Note: This capability is staged and not yet implemented in the current backend contract.`
- **`ApiService.getNotifications()`**:
  - Target URI: `GET $baseUrl/api/hr/notifications`.
  - Staged comments:
    `/// Note: This capability is staged and not yet implemented in the current backend contract.`
- **`ApiService.createAnnouncement()`**:
  - Target URI: `POST $baseUrl/api/hr/announcements`.
  - Staged comments:
    `/// Note: Staged method for upcoming backend releases.`
- **Audit Verdict:** **PASS** — Methods are documented as staged and do not falsely claim active server integration.

### 3.2 Data Persistence Audit
- **Question:** Are announcements and notifications persisted anywhere?
- **Code Inspection:**
  - `HRProvider.announcementsList`: Initialized in `_initMockData()` as an in-memory Dart list.
  - `HRProvider.notificationsList`: Initialized in `_initMockData()` as an in-memory Dart list.
  - `HRProvider.createAnnouncement()`: Executes `announcementsList.insert(0, newAnn)` in local memory.
  - No Hive, SQLite, SharedPreferences, or local filesystem calls are executed.
- **Audit Finding:** **Announcements and notifications are TEMPORARY IN-MEMORY ONLY.** Closing the browser tab or restarting the app resets them to their initial mock state. No database persistence exists.

### 3.3 Read State Transitions Audit
- **`markNotificationAsRead(String id)`** (`lib/providers/hr_provider.dart`):
  ```dart
  void markNotificationAsRead(String id) {
    final idx = notificationsList.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notificationsList[idx] = notificationsList[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }
  ```
- **`markAllNotificationsAsRead()`** (`lib/providers/hr_provider.dart`):
  ```dart
  void markAllNotificationsAsRead() {
    for (int i = 0; i < notificationsList.length; i++) {
      notificationsList[i] = notificationsList[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
  ```
- **Audit Finding:** **LOCAL-ONLY**. Neither method invokes an HTTP request because no backend endpoint for notification read-receipts exists. State changes are isolated to the active Flutter session.

### 3.4 Staged vs. Server Differentiation Audit
- **UI Status Banner:** Rendered in `lib/features/announcements/announcements_notifications_view.dart`:
  > **Backend Capability Status: Staged (Contract v1.0 Limitation)**  
  > Dedicated endpoints for announcements (`GET/POST /api/hr/announcements`) and notification feed (`GET /api/hr/notifications`) are not yet implemented in `HrsystemBackend`. Staged local notices and simulated alert streams are displayed cleanly for UI verification without fabricating unverified live API calls.
- **Modal Notice:**
  > **Staged Mode:** This announcement is staged locally. Backend API synchronization will become available in the next release.
- **Stale Data Isolation:** In `HRProvider.filteredAnnouncements`:
  ```dart
  if (announcementsError != null && !hasLoadedApiAnnouncements) {
    return const [];
  }
  ```
  If an API call fails and live data has not been retrieved, the list returns empty and displays an error banner with a Retry button, rather than silently falling back to mock notices as if they were live data.
- **Audit Verdict:** **PASS**

### 3.5 Header & Sidebar Badges Consistency
- **Header:**
  ```dart
  Badge.count(
    count: hrProvider.unreadNotificationsCount,
    isLabelVisible: hrProvider.unreadNotificationsCount > 0,
    child: const Icon(Icons.notifications_none_outlined, ...),
  )
  ```
- **Sidebar:**
  ```dart
  _buildSidebarItem(
    title: 'Announcements',
    icon: Icons.campaign_outlined,
    activeIcon: Icons.campaign,
    isActive: currentScreen == 'announcements',
    badgeCount: hrProvider.unreadNotificationsCount,
    onTap: () => hrProvider.setScreen('announcements'),
  )
  ```
- Both badges bind reactively to `hrProvider.unreadNotificationsCount`. Marking a notification as read decrements the count and updates both widgets simultaneously.
- **Audit Verdict:** **PASS**

---

## 4. Test & Verification Evidence

### 4.1 Targeted Test Suite
```text
Command: flutter test test/announcements_notifications_api_test.dart
Exit Code: 0

00:00 +0: ApiService Announcements & Notifications Endpoints getAnnouncements parses response envelope and fields correctly
00:00 +1: ApiService Announcements & Notifications Endpoints getAnnouncements throws exception when server returns 404 or error
00:00 +2: ApiService Announcements & Notifications Endpoints getNotifications parses notification feed envelope correctly
00:00 +3: ApiService Announcements & Notifications Endpoints createAnnouncement sends POST /api/hr/announcements and returns result
00:00 +4: HRProvider Announcements & Notifications Integration loadAnnouncements updates state on API success
00:00 +5: HRProvider Announcements & Notifications Integration loadAnnouncements isolates error when endpoint is missing / fails
00:01 +6: HRProvider Announcements & Notifications Integration department filter filters announcements accurately
00:01 +7: HRProvider Announcements & Notifications Integration notification read states and unread counter update accurately
00:01 +8: AnnouncementsNotificationsView Widget Tests renders header, staged status banner, notices, and notifications
00:03 +9: AnnouncementsNotificationsView Widget Tests department filter chip filters displayed announcements
00:03 +10: AnnouncementsNotificationsView Widget Tests renders error banner with Retry button when announcementsError is set
00:04 +11: AnnouncementsNotificationsView Widget Tests Create Announcement modal opens and validates inputs
00:05 +12: All tests passed!
```

### 4.2 Static Analysis
```text
Command: flutter analyze --no-fatal-infos
Exit Code: 0
Issues: 26 (all pre-existing curly_braces_in_flow_control_structures in unrelated files: modals.dart, api_service.dart lines 303-357). 0 errors, 0 warnings.
```

### 4.3 Full Regression Suite
```text
Command: flutter test
Exit Code: 0
Result: All 155 tests passed across all suites in flutter_src!
```

### 4.4 Live Backend Probe
```text
Probe 1: http://localhost:5000/api/health -> offline (connection refused)
Probe 2: http://localhost:3000/api/health -> offline (connection refused)
Live API Status: BLOCKED
```

---

## 5. Required Backend Capabilities for Future Implementation

To transition Screen 10 from staged mode to live server persistence, the following backend components must be added to `HrsystemBackend`:

1. **Mongoose Models:**
   - `models/Announcement.js`: `{ title, content, category, department, author, isPinned, isDeleted }`
   - `models/Notification.js`: `{ user, title, message, category, isRead, createdAt }`
2. **Controller & Service:**
   - `controllers/announcementController.js` and `services/announcementService.js`
   - `controllers/notificationController.js` and `services/notificationService.js`
3. **Express Routes (`routes/hrRoutes.js`):**
   - `GET /api/hr/announcements`
   - `POST /api/hr/announcements`
   - `DELETE /api/hr/announcements/:id`
   - `GET /api/hr/notifications`
   - `PATCH /api/hr/notifications/:id/read`
   - `PATCH /api/hr/notifications/read-all`

---

## 6. Audit Conclusion

- **Overall Result:** **PASS (with Unsupported Backend Capabilities Documented)**
- **Critical Defects:** 0
- **Live Integration:** Marked **BLOCKED** due to missing backend endpoints and offline Express server.
- **Client Integrity:** Staged features, temporary in-memory persistence, and local read states are clearly disclosed to users and verified through automated tests.
