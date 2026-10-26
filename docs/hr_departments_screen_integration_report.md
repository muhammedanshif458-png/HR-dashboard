# LY SOFTWARE HR Dashboard — Screen 3: Departments API Integration Report

## 1. Overview & Scope
This report documents the backend API integration for **Screen 3: Departments & Headcount** (`lib/features/departments/departments_view.dart`) in the LY SOFTWARE HR Flutter management dashboard.

All changes adhere strictly to the scope of Screen 3:
- Preserved existing UI layout, styling, colors, and responsive design.
- Reused existing state management (`HRProvider`) and HTTP client (`ApiService`).
- Implemented robust error handling, loading states, empty list states, and cached offline fallback.
- Added comprehensive mocked HTTP unit and widget tests.

---

## 2. Files Modified & Created

| File | Status | Description |
|---|---|---|
| `lib/models/department.dart` | **Created** | Strongly-typed model for department records with resilient JSON parsing, integer fallbacks (handling int, double, string), unknown icon fallback to `Icons.business`, and invalid hex color fallback to slate-500 (`#64748B`). |
| `lib/services/api_service.dart` | **Modified** | Added `getDepartments()` and `getDepartmentDetail(String deptKey)` using the existing HTTP client and Bearer token headers via `_headers()`. Verified URL resolution to exact paths without duplicate `/api` prefixing. |
| `lib/providers/hr_provider.dart` | **Modified** | Added department state fields (`departments`, `isDepartmentsLoading`, `departmentsError`, `selectedDepartmentDetail`, `isDepartmentDetailLoading`, `departmentDetailError`), initialized fallback departments in `_initMockData()`, added async methods `fetchDepartments()` and `fetchDepartmentDetail(deptKey)`, and wired `navigateToDepartments()` to trigger `fetchDepartments()`. |
| `lib/features/departments/departments_view.dart` | **Modified** | Replaced static two-department row with dynamic API-driven grid powered by `hrProvider.departments`. Added full-screen loading spinner, full-screen error state with Retry button, empty-state UI with Refresh button, non-intrusive offline notice banner when cached data is used, and a Department Detail dialog triggered on card tap which fetches from `GET /api/hr/departments/:deptKey`. |
| `test/departments_api_test.dart` | **Created** | 20 comprehensive unit and widget tests covering all endpoint scenarios, Bearer auth, model fallbacks, URL encoding, provider state, and UI states. |

---

## 3. Endpoints Integrated

### 3.1 Fetch All Departments
- **Endpoint**: `GET /api/hr/departments`
- **Headers**:
  ```http
  Authorization: Bearer <accessToken>
  Content-Type: application/json
  ```
- **Response Format**:
  ```json
  {
    "success": true,
    "message": "Departments retrieved successfully",
    "data": [
      {
        "deptKey": "tech",
        "title": "Tech & Engineering",
        "subtitle": "Frontend, Backend, Infrastructure & QA",
        "staffCount": 24,
        "activeCount": 22,
        "leadName": "Anita Rao (Lead HR / Tech Ops)",
        "icon": "computer",
        "color": "#2563EB"
      },
      {
        "deptKey": "telecalling",
        "title": "Telecalling & Client Relations",
        "subtitle": "Candidate Outreach, Lead Calling & Customer Support",
        "staffCount": 18,
        "activeCount": 16,
        "leadName": "Neha Sharma (Operations Senior)",
        "icon": "headset_mic",
        "color": "#DB2777"
      }
    ]
  }
  ```

### 3.2 Fetch Department Details
- **Endpoint**: `GET /api/hr/departments/:deptKey`
- **Example**: `GET /api/hr/departments/tech`
- **Headers**:
  ```http
  Authorization: Bearer <accessToken>
  Content-Type: application/json
  ```
- **Identifier**: Uses `deptKey` (URL-encoded) as the identifier, avoiding reliance on displayed department titles.
- **Response Format**:
  ```json
  {
    "success": true,
    "message": "Department details fetched successfully",
    "data": {
      "deptKey": "tech",
      "title": "Tech & Engineering",
      "subtitle": "Frontend, Backend, Infrastructure & QA",
      "staffCount": 24,
      "activeCount": 22,
      "leadName": "Anita Rao (Lead HR / Tech Ops)",
      "icon": "computer",
      "color": "#2563EB"
    }
  }
  ```

---

## 4. Request / Response Mapping & Model Resilience

| Field | Source JSON Keys | Type | Fallback / Handling |
|---|---|---|---|
| `deptKey` | `json['deptKey'] ?? json['id']` | `String` | Defaults to empty string `''` |
| `title` | `json['title'] ?? json['name']` | `String` | Defaults to empty string `''` |
| `subtitle` | `json['subtitle'] ?? json['description']` | `String` | Defaults to empty string `''` |
| `staffCount` | `json['staffCount'] ?? json['totalStaff'] ?? json['memberCount']` | `int` | Accepts int, double, or String; defaults to `0` |
| `activeCount` | `json['activeCount'] ?? json['activeStaff']` | `int` | Accepts int, double, or String; defaults to `0` |
| `leadName` | `json['leadName'] ?? json['lead']` | `String` | Defaults to `'Division Lead Unassigned'` |
| `icon` | `json['icon']` | `IconData` | Mapped via lookup table; unknown icons safely fall back to `Icons.business` |
| `color` | `json['color']` | `Color` | Parsed from 6/8-digit hex; invalid/missing hex safely falls back to `#64748B` (`Color(0xFF64748B)`) |

---

## 5. UI States & Behaviors

1. **Loading State**:
   - When `isDepartmentsLoading == true` and `departments.isEmpty`: Displays a centered `CircularProgressIndicator` with the label *"Loading organizational units..."*.
   - Refresh button in the header indicates loading with a miniature progress indicator while disabling repeated taps.
2. **Full Error State**:
   - When an API request fails and no cached departments exist: Displays an error icon, error message, and a prominent *"Retry"* button.
3. **Empty State**:
   - When the API returns an empty list (`data: []`) and no error occurred: Displays a domain-disabled icon, *"No departments found"*, and a *"Refresh"* button.
4. **Populated State**:
   - Renders responsive cards in a 2-column grid (`Wrap` on wide desktop view, stacked column on mobile/tablet).
   - If an error occurs during background sync while cached data is available, a non-intrusive warning banner is displayed at the top: *"Offline / Sync Notice: Displaying cached department list (...). [Retry]"*.
5. **Department Detail Dialog**:
   - Tapping any department card opens a detail modal dialog.
   - The dialog immediately requests `GET /api/hr/departments/:deptKey` to fetch updated unit details.
   - Displays unit key tag (`deptKey: <key>`), unit lead, statistics, and a list of assigned staff members filtered from the company directory.
   - Provides quick navigation: *"View in Staff Directory"* (filters employee list by department) and *"Department Chat"* (opens department discussion channel).

---

## 6. Verification & Test Results

### 6.1 `test/departments_api_test.dart` (20 Tests Passed)
- **ApiService.getDepartments**:
  - `returns parsed department list on 200 with Bearer token` [PASSED]
  - `returns empty department list gracefully when backend data is empty` [PASSED]
  - `throws Exception on 401 Unauthorized` [PASSED]
  - `throws Exception on 500 Internal Server Error` [PASSED]
  - `throws Exception on malformed JSON response` [PASSED]
  - `throws Exception on network exception` [PASSED]
- **ApiService.getDepartmentDetail**:
  - `fetches detail using deptKey URL path with Bearer token` [PASSED]
  - `properly encodes special characters in deptKey` [PASSED]
  - `throws Exception on 404 Department Not Found` [PASSED]
- **Department Model Parsing & Fallbacks**:
  - `handles missing fields safely with intelligent defaults` [PASSED]
  - `falls back gracefully on unknown icon string` [PASSED]
  - `falls back gracefully on invalid hex color strings` [PASSED]
  - `parses count fields when sent as double, string, or int` [PASSED]
- **HRProvider & DepartmentsView Integration**:
  - `HRProvider fetchDepartments updates departments list on API success` [PASSED]
  - `HRProvider fetchDepartments sets error and retains fallback on failure` [PASSED]
  - `HRProvider fetchDepartmentDetail fetches and sets selectedDepartmentDetail` [PASSED]
  - `DepartmentsView renders loading state when loading with empty list` [PASSED]
  - `DepartmentsView renders full error state with retry button` [PASSED]
  - `DepartmentsView renders empty state when no departments found` [PASSED]
  - `Tapping department card opens detail dialog and triggers detail fetch` [PASSED]

### 6.2 Full Test Suite (`flutter test`)
- Total tests executed: **68**
- Total tests passing: **68 (100%)**
- Zero failures or regressions.

### 6.3 Code Quality & Formatting
- Ran `dart format` on all modified and new files:
  - `lib/models/department.dart`
  - `lib/services/api_service.dart`
  - `lib/providers/hr_provider.dart`
  - `lib/features/departments/departments_view.dart`
  - `test/departments_api_test.dart`
- Ran `flutter analyze`: All new and modified code is clean with zero compilation errors.

---

## 7. Mock Data & Live Backend Status
- **Automated Verification**: Completed via `MockClient` testing covering all contract success and failure paths.
- **Live Backend Verification**: Not claimed as complete since no live backend server was actively running during testing; endpoints resolve directly to `${AppConfig.apiBaseUrl}/api/hr/departments` and `${AppConfig.apiBaseUrl}/api/hr/departments/:deptKey` and are ready for live connection once the backend server is reachable.
