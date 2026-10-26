# Department-Based Late Arrivals Integration

Flutter uses the authenticated HR endpoints documented by the backend:

- `GET /api/hr/dashboard`: `data.lateArrivals` is the authoritative current-day summary count.
- `GET /api/hr/attendance`: paginated records include `late`, `scheduledCheckIn`, `scheduleTimeZone`, and populated `employee.department`. `status=LATE` filters late records; `department`, date, employee ID, and pagination are sent as query parameters.

The Flutter model uses only the backend `late` boolean for late classification. It does not infer lateness from timestamps or treat `HALF_DAY` as Late. The dashboard summary is refreshed when Attendance Management opens and when Sync Attendance is used. A failed or malformed summary request shows an unavailable value and an error with retry.

The backend schedule comparison was inspected in source, but this local Flutter verification did not run the backend or inspect live attendance records. Automated tests use mocked backend responses.
