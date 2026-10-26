# Employee Directory API Integration Report

## Scope and files

The Employee Directory and its existing profile detail route were integrated. No backend source or database records were changed.

- `flutter_src/lib/models/staff.dart` — made employee identifiers and optional API fields tolerant of nulls and mapped `_id`, `id`, or `employeeId`.
- `flutter_src/lib/services/api_service.dart` — added paginated employee listing, detail retrieval, create, update, status, salary, and deactivation calls through the authenticated client.
- `flutter_src/lib/providers/hr_provider.dart` — server-backed directory state, request versioning, debounced search, filters, page metadata, mutation handling, and refresh-after-success.
- `flutter_src/lib/features/employees/employees_view.dart` — initial fetch, server pagination, loading/error/empty states, status labels, and deactivation wording.
- `flutter_src/lib/features/dashboard/staff_profile_view.dart` — fetch employee details when opening the existing profile route and resolve directory-loaded records.
- `flutter_src/test/employee_directory_api_test.dart` — mocked API, provider, and empty-state widget tests.

## Endpoint and mapping behavior

All employee requests use `/api/hr/employees` and the shared Bearer-token headers. The API service adds `page` and `limit`, then optional `search`, `department`, and uppercase `status`. It parses the response `data` list and preserves `page`, `limit`, `total`, and `totalPages` from `pagination`.

The directory uses a 350 ms debounce for search, immediate requests for department/status changes, and request versioning to ignore late responses. Previous results are retained on a failed refresh with an explicit error banner; failed requests do not silently replace them with mock employees.

Employee detail uses the selected record identifier. Create maps the existing full-name form to `firstName`/`lastName` and sends its supported email, phone, department, designation, salary, currency, effective date, leave allowance, and optional birth date values. Edit sends editable supported profile fields; salary changes use the dedicated salary endpoint with `salary`, `salaryCurrency`, `salaryEffectiveDate`, and `reason`. Work mode remains a UI field but is not sent because it is absent from the documented employee contract. The existing form does not collect password or employee ID, so neither is fabricated.

Create, edit, salary, status, and deactivation only report success after an API success response and refresh the directory. The status endpoint and provider method support `ACTIVE`, `INACTIVE`, `ON_LEAVE`, and `TERMINATED`; the existing directory UI currently exposes the corresponding status filters, while the existing resign/deactivate action uses DELETE as specified. DELETE is described as account deactivation and preserves records.

## Tests and verification

Added mocked coverage for list parsing and query parameters, Bearer token attachment, detail retrieval, create/update/status/salary/deactivation routes, malformed list responses, validation errors, failed-refresh behavior, and the directory empty-state widget.

- `dart format` formatted the six changed Dart files. The Dart tool then exited with a telemetry write error because `C:\Users\Admin\AppData\Roaming\.dart-tool\dart-flutter-telemetry-session.json` is outside the workspace write scope.
- `flutter analyze` could not complete in this environment. Flutter startup produced no output and remained running; a direct Dart analyze attempt then failed to start its analysis server with Windows `Access is denied` and could not write its telemetry session under `C:\Users\Admin\AppData\Roaming\.dart-tool`.
- `flutter test test/employee_directory_api_test.dart` did not complete: Flutter startup remained silent for 45 seconds and was stopped. No tests are claimed as passing.
- Full `flutter test` was not run because the targeted test command could not start.
- Live backend verification was not completed. No real request to the configured backend succeeded in this task.

## Remaining contract notes

Salary editing was integrated because the existing directory and profile screens already expose salary editing. Salary data remains behind the authenticated HR application flow. The existing add form has no password field, and the documented contract does not state which create fields are mandatory, so no password or extra unsupported fields were added. Status updates are available at the API/provider layer; the existing UI has no explicit arbitrary status-edit control beyond its deactivation action.
