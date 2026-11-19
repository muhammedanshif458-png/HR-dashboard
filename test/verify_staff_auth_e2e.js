const http = require('http');

const BASE_URL = 'http://127.0.0.1:5000';

function request(options, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(options.path, BASE_URL);
    const reqOptions = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: options.method || 'GET',
      headers: options.headers || {}
    };

    if (body) {
      const data = typeof body === 'string' ? body : JSON.stringify(body);
      reqOptions.headers['Content-Type'] = 'application/json';
      reqOptions.headers['Content-Length'] = Buffer.byteLength(data);
    }

    const req = http.request(reqOptions, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => {
        responseBody += chunk;
      });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseBody);
          resolve({ status: res.statusCode, headers: res.headers, body: parsed });
        } catch {
          resolve({ status: res.statusCode, headers: res.headers, raw: responseBody });
        }
      });
    });

    req.on('error', (err) => reject(err));
    if (body) {
      req.write(typeof body === 'string' ? body : JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('====================================================');
  console.log('HR PORTAL: STAFF ACCOUNT CREATION & AUTH E2E TEST');
  console.log('====================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`[PASS] ${message}`);
      passed++;
    } else {
      console.error(`[FAIL] ${message}`);
      failed++;
    }
  }

  try {
    // 1. Super Admin login
    console.log('--- 1. Authenticating Super Admin ---');
    const saLogin = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: 'lysoftware@gmail.com',
      password: 'hrAdmin'
    });
    assert(saLogin.status === 200, 'Super Admin login succeeds with 200');
    assert(saLogin.body?.data?.user?.role === 'SUPER_ADMIN', 'Super Admin role is SUPER_ADMIN');
    const saToken = saLogin.body?.data?.accessToken;
    assert(!!saToken, 'Super Admin receives valid JWT access token');

    // 2. HR Admin login check
    console.log('\n--- 2. Existing HR Admin Login Check ---');
    const hrLogin = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: 'admin@hrmanagement.com',
      password: 'Admin@12345'
    });
    assert(hrLogin.status === 200, 'HR Admin login succeeds with 200');
    assert(hrLogin.body?.data?.user?.role === 'HR', 'HR Admin role is HR');

    // 3. Super Admin creates a staff account with email & password
    console.log('\n--- 3. Super Admin Provisions Staff Account with Credentials ---');
    const testTimestamp = Date.now();
    const staffEmail = `staff.test.${testTimestamp}@example.com`;
    const initialPassword = 'InitialSecurePassword@123';

    const createRes = await request({
      method: 'POST',
      path: '/api/hr/employees',
      headers: { Authorization: `Bearer ${saToken}` }
    }, {
      firstName: 'Test',
      lastName: `Staff_${testTimestamp.toString().slice(-4)}`,
      email: staffEmail,
      phone: `98${testTimestamp.toString().slice(-8)}`,
      department: 'Tech',
      designation: 'Backend Developer',
      workMode: 'Office',
      salary: 75000,
      salaryCurrency: 'INR',
      salaryEffectiveDate: '2026-10-01',
      paidLeaveAllowance: 1,
      password: initialPassword
    });

    assert(createRes.status === 201, `Staff creation returns 201 Created (got ${createRes.status})`);
    const createdEmployee = createRes.body?.data;
    assert(!!createdEmployee && createdEmployee.email === staffEmail, 'Employee profile created with correct email');
    const linkedUser = createdEmployee?.user;
    assert(!!linkedUser, 'Employee has linked user profile');
    assert(linkedUser?.role === 'STAFF', 'User account assigned role STAFF');
    assert(!linkedUser?.password, 'Password hash is NOT exposed in response');
    const employeeId = createdEmployee?._id;
    const userId = linkedUser?._id;

    // 4. Confirm account and employee are correctly linked
    console.log('\n--- 4. Verify Database Relationship Linking ---');
    assert(!!employeeId && !!userId, `Employee ID (${employeeId}) and User ID (${userId}) exist and are linked`);

    // 5. Staff signs in with correct credentials
    console.log('\n--- 5. Staff Signs in with Created Credentials ---');
    const staffLogin = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: staffEmail,
      password: initialPassword
    });
    assert(staffLogin.status === 200, `Staff login succeeds with 200 (got ${staffLogin.status})`);
    assert(staffLogin.body?.data?.user?.role === 'STAFF', 'Staff login user role is STAFF');
    const staffToken = staffLogin.body?.data?.accessToken;
    assert(!!staffToken, 'Staff receives valid JWT access token');
    assert(staffLogin.body?.data?.user?.employee?._id === employeeId, 'Staff response contains linked employee profile');

    // 6. Incorrect passwords rejected
    console.log('\n--- 6. Reject Incorrect Password ---');
    const badLogin = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: staffEmail,
      password: 'WrongPassword@999'
    });
    assert(badLogin.status === 401, `Incorrect password returns 401 Unauthorized (got ${badLogin.status})`);

    // 7. Duplicate email rejected safely
    console.log('\n--- 7. Reject Duplicate Email Registration ---');
    const dupRes = await request({
      method: 'POST',
      path: '/api/hr/employees',
      headers: { Authorization: `Bearer ${saToken}` }
    }, {
      firstName: 'Duplicate',
      lastName: 'User',
      email: staffEmail, // duplicate
      phone: '9812345678',
      department: 'Tech',
      designation: 'Developer',
      salary: 50000,
      salaryCurrency: 'INR',
      salaryEffectiveDate: '2026-10-01',
      paidLeaveAllowance: 1,
      password: 'SomePassword@123'
    });
    assert(dupRes.status === 409 || dupRes.status === 400, `Duplicate email rejected with conflict status (got ${dupRes.status})`);

    // 8. Edit staff details WITHOUT entering a password preserves existing password
    console.log('\n--- 8. Edit Staff Without Password Preserves Existing Password ---');
    const updateNoPwdRes = await request({
      method: 'PUT',
      path: `/api/hr/employees/${employeeId}`,
      headers: { Authorization: `Bearer ${saToken}` }
    }, {
      designation: 'Senior Backend Developer',
      phone: `97${testTimestamp.toString().slice(-8)}`
      // password omitted
    });
    assert(updateNoPwdRes.status === 200, `Update without password returns 200 OK (got ${updateNoPwdRes.status})`);

    // Verify staff can still sign in with initial password
    const staffLoginAfterEdit = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: staffEmail,
      password: initialPassword
    });
    assert(staffLoginAfterEdit.status === 200, 'Staff can still sign in with initial password after profile update');

    // 9. Setting a new password changes credential securely
    console.log('\n--- 9. Super Admin Updates Staff Password ---');
    const newPassword = 'NewUpdatedPassword@456';
    const updatePwdRes = await request({
      method: 'PUT',
      path: `/api/hr/employees/${employeeId}`,
      headers: { Authorization: `Bearer ${saToken}` }
    }, {
      password: newPassword
    });
    assert(updatePwdRes.status === 200, `Updating staff with new password returns 200 OK (got ${updatePwdRes.status})`);

    // Verify old password is now rejected
    const oldPwdLogin = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: staffEmail,
      password: initialPassword
    });
    assert(oldPwdLogin.status === 401, 'Old password is now rejected with 401 Unauthorized');

    // Verify new password succeeds
    const newPwdLogin = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: staffEmail,
      password: newPassword
    });
    assert(newPwdLogin.status === 200, 'New password login succeeds with 200 OK');
    const updatedStaffToken = newPwdLogin.body?.data?.accessToken;

    // 10. Staff cannot access Super Admin / HR routes (403 Forbidden)
    console.log('\n--- 10. RBAC Authorization Enforcement: Staff Blocked from HR/Admin Routes ---');
    const hrEmployeesRes = await request({
      method: 'GET',
      path: '/api/hr/employees',
      headers: { Authorization: `Bearer ${updatedStaffToken}` }
    });
    assert(hrEmployeesRes.status === 403, `Staff cannot GET /api/hr/employees (got 403 Forbidden: ${hrEmployeesRes.status})`);

    const hrDashboardRes = await request({
      method: 'GET',
      path: '/api/hr/dashboard',
      headers: { Authorization: `Bearer ${updatedStaffToken}` }
    });
    assert(hrDashboardRes.status === 403, `Staff cannot GET /api/hr/dashboard (got 403 Forbidden: ${hrDashboardRes.status})`);

    const otherEmployeeRes = await request({
      method: 'GET',
      path: `/api/hr/employees/${employeeId}`,
      headers: { Authorization: `Bearer ${updatedStaffToken}` }
    });
    assert(otherEmployeeRes.status === 403, `Staff cannot GET /api/hr/employees/:id (got 403 Forbidden: ${otherEmployeeRes.status})`);

    // 11. Staff CAN access their own staff profile and staff routes
    console.log('\n--- 11. Staff Access to Own Resources ---');
    const staffProfileRes = await request({
      method: 'GET',
      path: '/api/staff/profile',
      headers: { Authorization: `Bearer ${updatedStaffToken}` }
    });
    assert(staffProfileRes.status === 200, `Staff can GET own profile /api/staff/profile (got 200 OK)`);
    assert(staffProfileRes.body?.data?.email === staffEmail, 'Profile email matches authenticated staff');

    // 12. Non-Super Admin cannot update passwords
    console.log('\n--- 12. Non-Super Admin Forbidden from Updating Credentials ---');
    const hrToken = hrLogin.body?.data?.accessToken;
    const hrChangePwdRes = await request({
      method: 'PUT',
      path: `/api/hr/employees/${employeeId}`,
      headers: { Authorization: `Bearer ${hrToken}` }
    }, {
      password: 'HackerPassword@123'
    });
    assert(hrChangePwdRes.status === 403, `HR role cannot change staff password (got 403 Forbidden: ${hrChangePwdRes.status})`);

  } catch (err) {
    console.error('Unexpected test execution error:', err);
    failed++;
  }

  console.log('\n====================================================');
  console.log(`TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log('====================================================');

  if (failed > 0) {
    process.exit(1);
  }
}

runTests();
