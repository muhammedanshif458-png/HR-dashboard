# Integration Report — Screen 10: Announcements & Notifications

**Date:** October 16, 2026  
**Screen:** Screen 10 (Announcements & Notifications)  
**Frontend Path:** `C:\Users\Admin\Downloads\HR-dashboard\flutter_src`  
**Backend Path:** `C:\Users\Admin\Downloads\HrsystemBackend`  
**API Reference:** `C:\Users\Admin\Downloads\HrsystemBackend\docs\hr_backend_api_contract.md`  

---

## 1. Executive Summary

Screen 10 represents **Announcements & Notifications** in the LY SOFTWARE HR Management dashboard.

A comprehensive pre-coding audit of the backend repository (`HrsystemBackend`), routes (`routes/hrRoutes.js`), controllers (`controllers/`), services (`services/`), models (`models/`), and the formal API contract (`docs/hr_backend_api_contract.md`) revealed that **dedicated endpoints for announcements and notifications do not exist in the backend system**. In the backend contract, Section 10 is dedicated to `Department Chat & Messaging` (`/api/hr/departments/:deptKey/messages`).

In strict compliance with the prompt guidelines:
- We **did not invent fake endpoints or fabricate unverified live backend capabilities**.
- The client-side architecture was integrated cleanly to support staged notices, filtering, read/unread states, and creation flows.
- A prominent **Backend Capability Status Banner** is displayed on the screen clearly informing users and auditors that backend endpoints (`GET/POST /api/hr/announcements`, `GET /api/hr/notifications`) are staged for an upcoming backend contract release.
- Staged mock records are **never silently presented as live server synchronized data**.
- All unit, widget, and integration tests passed cleanly (155/155 tests in the project regression suite).

---

## 2. Backend Inspection & Contract Audit

### 2.1 Backend Capability Breakdown

| Capability | Backend Route / Contract Status | Express Implementation | Frontend Handling |
| :--- | :--- | :--- | :--- |
| **List Announcements** | **UNSUPPORTED** in contract v1.0 | No route or model | Handled via staged local repository with department filtering (`all`, `Tech`, `Telecalling`, `Company-wide`). Service method prepared with descriptive error isolation. |
| **Create Announcement** | **UNSUPPORTED** in contract v1.0 | No route or model | Interactive modal allows HR to stage notices locally; warns that backend persistence requires contract release. |
| **Publish / Archive Announcements** | **UNSUPPORTED** in contract v1.0 | No route or model | Pinned status and timestamps handled locally; soft-archive endpoints not yet defined on backend. |
| **Notification Listing** | **UNSUPPORTED** in contract v1.0 | No route or model | Dynamic workflow alert stream categorizes leave, task, attendance, and system events. |
| **Notification Read / Unread Status** | **UNSUPPORTED** in contract v1.0 | No route or model | Stateful read toggles (`markNotificationAsRead`, `markAllNotificationsAsRead`) with unread badge counters. |
| **Department Targeting** | **UNSUPPORTED** in contract v1.0 | No route or model | Supported in client schema (`department: 'All' \| 'Tech' \| 'Telecalling'`). |
| **Pagination & Search** | **UNSUPPORTED** in contract v1.0 | No route or model | Client-side categorization and filtering by category and department. |

### 2.2 Proposed Backend Contract for Future Releases

To complete full server-side persistence for Screen 10 in future backend updates, the following endpoints are recommended for `HrsystemBackend`:

#### 1. `GET /api/hr/announcements`
- **Auth:** Bearer Token (HR or STAFF)
- **Query Params:** `department` (optional), `category` (optional), `page`, `limit`
- **Response (200):**
  ```json
  {
    "success": true,
    "message": "Announcements retrieved successfully",
    "data": [
      {
        "_id": "670f...",
        "title": "Q4 Sprint Planning & Architecture Review",
        "content": "Sprint review scheduled for Friday at 4 PM.",
        "category": "Sprint",
        "department": "Tech",
        "authorName": "Anita Rao",
        "publishedAt": "2026-10-15",
        "isPinned": true
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 1, "totalPages": 1 }
  }
  ```

#### 2. `POST /api/hr/announcements`
- **Auth:** Bearer Token (HR only)
- **Body:** `{ "title": "...", "content": "...", "category": "...", "department": "..." }`
- **Response (201):** Created announcement document.

#### 3. `GET /api/hr/notifications`
- **Auth:** Bearer Token (HR)
- **Query Params:** `category`, `unreadOnly=true|false`, `page`, `limit`
- **Response (200):** Paginated notification event stream.

#### 4. `PATCH /api/hr/notifications/:id/read`
- **Auth:** Bearer Token
- **Response (200):** Updated notification with `isRead: true`.

---

## 3. Frontend Architecture & Implementation

### 3.1 Domain Models (`lib/models/hr_models.dart`)
- **`CompanyAnnouncement`**: Defines `id`, `title`, `content`, `category`, `department`, `authorName`, `publishedAt`, `isPinned`, `fromJson`, `toJson`, and `copyWith`.
- **`AppNotification`**: Defines `id`, `title`, `message`, `category`, `timestamp`, `isRead`, `fromJson`, `toJson`, and `copyWith`.

### 3.2 Service Layer (`lib/services/api_service.dart`)
- Added `ApiService.getAnnouncements()`: Formatted to parse backend envelopes safely; throws descriptive error if backend responds with 404 or missing route.
- Added `ApiService.getNotifications()`: Parses notification lists.
- Added `ApiService.createAnnouncement()`: Sends POST request for announcement creation.

### 3.3 State Management (`lib/providers/hr_provider.dart`)
- **State variables:** `announcementDeptFilter`, `notificationCategoryFilter`, `isAnnouncementsLoading`, `announcementsError`, `hasLoadedApiAnnouncements`, `announcementsList`, `notificationsList`.
- **Badge Counter:** `unreadNotificationsCount` returns count of unread notifications.
- **Filters:**
  - `filteredAnnouncements`: filters by department (`Tech`, `Telecalling`, `Company-wide`, `all`).
  - `filteredNotifications`: filters by category (`unread`, `leave`, `task`, `attendance`, `system`, `all`).
- **Actions:**
  - `markNotificationAsRead(id)`: marks specific notification as read and updates badge.
  - `markAllNotificationsAsRead()`: marks all items read.
  - `createAnnouncement(title, content, category, department)`: stages notice locally and triggers server call if API is active.
  - `loadAnnouncements()`: executes loader, isolates errors cleanly, and avoids corrupting state.

### 3.4 User Interface (`lib/features/announcements/announcements_notifications_view.dart`)
- **Page Header:** Eyebrow `LY SOFTWARE • COMMUNICATIONS & BROADCASTS`, Title, Subtitle, refresh button, and "Create Announcement" action button.
- **Backend Capability Notice:** Clear information banner explaining that the feature is in staged mode pending backend contract release.
- **Two-Column Layout:**
  - Left column: Company bulletins with department chips, pinned indicators, and category tags.
  - Right column: Notification feed with category chips, unread count badge, category icons, and read toggles.
- **Create Announcement Modal:** Dialog with input validation, department and category selectors, and staged-mode disclosure.

### 3.5 App Navigation Integration
- **`lib/app.dart`:** Added `case 'announcements': content = const AnnouncementsNotificationsView(); break;`.
- **`lib/widgets/sidebar.dart`:** Added `Announcements` item under MAIN MENU with dynamic unread count badge.
- **`lib/widgets/header.dart`:** Added Announcement campaign button and Notification bell icon button with dynamic badge counter.

---

## 4. Verification & Test Evidence

### 4.1 Changed Files
1. `lib/models/hr_models.dart`: Added `CompanyAnnouncement` and `AppNotification` models.
2. `lib/services/api_service.dart`: Added `getAnnouncements`, `getNotifications`, and `createAnnouncement`.
3. `lib/providers/hr_provider.dart`: Added announcement & notification state, filters, actions, and loader.
4. `lib/features/announcements/announcements_notifications_view.dart`: Created Screen 10 view.
5. `lib/app.dart`: Added announcements route.
6. `lib/widgets/sidebar.dart`: Added sidebar item.
7. `lib/widgets/header.dart`: Added header action buttons with badge count.
8. `test/announcements_notifications_api_test.dart`: Targeted test suite with 12 test cases.

### 4.2 Formatting (`dart format`)
```text
Formatted lib/models/hr_models.dart
Formatted lib/services/api_service.dart
Formatted lib/providers/hr_provider.dart
Formatted lib/widgets/sidebar.dart
Formatted lib/widgets/header.dart
Formatted lib/features/announcements/announcements_notifications_view.dart
Formatted test/announcements_notifications_api_test.dart
Formatted 8 files (7 changed) in 0.31 seconds.
Exit Code: 0
```

### 4.3 Targeted Tests (`flutter test test/announcements_notifications_api_test.dart`)
```text
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
00:04 +10: AnnouncementsNotificationsView Widget Tests renders error banner with Retry button when announcementsError is set
00:04 +11: AnnouncementsNotificationsView Widget Tests Create Announcement modal opens and validates inputs
00:05 +12: All tests passed!

Exit Code: 0
```

### 4.4 Static Analysis (`flutter analyze --no-fatal-infos`)
```text
Analyzing flutter_src...
26 issues found. (all pre-existing curly_braces_in_flow_control_structures in unrelated files; 0 errors, 0 warnings)
Exit Code: 0
```

### 4.5 Full Regression Suite (`flutter test`)
```text
01:04 +155: All tests passed!
Exit Code: 0
```

### 4.6 Live Backend Probe
- `http://localhost:5000/api/health`: offline (connection refused).
- `http://localhost:3000/api/health`: offline (connection refused).
- **Status:** **BLOCKED** (server is not running; all test evidence is from mocked unit and widget tests).

---

## 5. Remaining Blockers & Next Steps

1. **Backend Implementation Required:**
   To graduate Screen 10 from staged mode to live server persistence, the Node.js Express backend needs:
   - `models/Announcement.js` Mongoose schema.
   - `models/Notification.js` Mongoose schema.
   - `controllers/announcementController.js` and `services/announcementService.js`.
   - Routes mounted in `routes/hrRoutes.js` (`/api/hr/announcements`).
2. **Current Screen 10 Status:**
   Client-side architecture, models, service contracts, provider state, and UI are complete, fully tested, and cleanly integrated.
