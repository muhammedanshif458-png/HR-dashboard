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
      res.on('data', (chunk) => { responseBody += chunk; });
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, headers: res.headers, body: JSON.parse(responseBody) });
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

async function verifyJourney() {
  console.log('================================================================');
  console.log('REAL-TIME STAFF CREDENTIAL & STAFF PORTAL LIVE JOURNEY AUDIT');
  console.log('================================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, message, details = '') {
    if (condition) {
      console.log(`[PASS] ${message} ${details ? '(' + details + ')' : ''}`);
      passed++;
    } else {
      console.error(`[FAIL] ${message} ${details ? '(' + details + ')' : ''}`);
      failed++;
    }
  }

  try {
    // 1. Super Admin logs in
    console.log('Step 1: Super Admin Authentication');
    const saLogin = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: 'lysoftware@gmail.com',
      password: 'hrAdmin'
    });
    assert(saLogin.status === 200, 'Super Admin login successful', `HTTP ${saLogin.status}`);
    const saToken = saLogin.body?.data?.accessToken;
    assert(!!saToken, 'Super Admin JWT access token acquired');

    // 2. Provision dedicated test staff
    console.log('\nStep 2: Provision Dedicated Test Staff Account');
    const timestamp = Date.now();
    const staffEmail = `test.staff.${timestamp}@company.com`;
    const initialPassword = 'InitialSecurePassword@123';
    const createStaff = await request({
      method: 'POST',
      path: '/api/hr/employees',
      headers: { Authorization: `Bearer ${saToken}` }
    }, {
      firstName: 'Audit',
      lastName: `Staff${timestamp.toString().slice(-4)}`,
      email: staffEmail,
      phone: `98${timestamp.toString().slice(-8)}`,
      department: 'Tech',
      designation: 'Frontend Engineer',
      salary: 65000,
      salaryCurrency: 'INR',
      salaryEffectiveDate: '2026-10-01',
      paidLeaveAllowance: 1,
      password: initialPassword
    });
    assert(createStaff.status === 201, 'Dedicated staff created', `HTTP ${createStaff.status}`);
    const employeeId = createStaff.body?.data?._id;
    const userId = createStaff.body?.data?.user?._id;
    assert(!!employeeId && !!userId, 'Employee profile and linked User account created and linked');
    assert(!createStaff.body?.data?.user?.password, 'Password hash is NOT leaked in create response');

    // 3. Super Admin inspects staff profile (verifies password is not retrieved)
    console.log('\nStep 3: Staff Profile Inspection');
    const profileRes = await request({
      method: 'GET',
      path: `/api/hr/employees/${employeeId}`,
      headers: { Authorization: `Bearer ${saToken}` }
    });
    assert(profileRes.status === 200, 'Staff profile fetched successfully', `HTTP ${profileRes.status}`);
    assert(profileRes.body?.data?.password === undefined, 'Password field is completely absent from employee profile');
    assert(profileRes.body?.data?.user?.password === undefined, 'Password field is completely absent from user object');

    // 4. Super Admin updates staff credentials with new password
    console.log('\nStep 4: Super Admin Sets New Password via Edit Staff');
    const newPassword = 'NewUpdatedPassword@2026';
    const updateRes = await request({
      method: 'PUT',
      path: `/api/hr/employees/${employeeId}`,
      headers: { Authorization: `Bearer ${saToken}` }
    }, {
      password: newPassword,
      designation: 'Senior Frontend Engineer'
    });
    assert(updateRes.status === 200, 'Edit Staff update with new password succeeds', `HTTP ${updateRes.status}`);
    assert(!updateRes.body?.data?.password, 'Password is NOT leaked in update response');

    // 5. Old password rejected at staff login
    console.log('\nStep 5: Verify Old Password Invalidation');
    const oldLogin = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: staffEmail,
      password: initialPassword
    });
    assert(oldLogin.status === 401, 'Old password correctly rejected', `HTTP ${oldLogin.status}`);

    // 6. Real Staff Portal login with new password
    console.log('\nStep 6: Staff Portal Real Login with New Password');
    const staffLogin = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: staffEmail,
      password: newPassword
    });
    assert(staffLogin.status === 200, 'Staff Portal login succeeds with new password', `HTTP ${staffLogin.status}`);
    assert(staffLogin.body?.data?.user?.role === 'STAFF', 'Staff user role confirmed as STAFF');
    const staffToken = staffLogin.body?.data?.accessToken;
    assert(!!staffToken, 'Staff receives valid JWT token for Staff Portal');

    // 7. Staff accesses Staff Portal resources
    console.log('\nStep 7: Access Staff Portal Resources with Staff Token');
    const staffResource = await request({
      method: 'GET',
      path: '/api/staff/profile',
      headers: { Authorization: `Bearer ${staffToken}` }
    });
    assert(staffResource.status === 200, 'Staff profile accessed on /api/staff/profile', `HTTP ${staffResource.status}`);
    assert(staffResource.body?.data?.email === staffEmail, 'Staff Portal profile belongs to authenticated staff member');

    // 8. Super Admin saves other staff details with password field blank
    console.log('\nStep 8: Edit Staff Details with Password Field Blank (Preserves Existing Password)');
    const updateDetailsOnly = await request({
      method: 'PUT',
      path: `/api/hr/employees/${employeeId}`,
      headers: { Authorization: `Bearer ${saToken}` }
    }, {
      phone: `99${timestamp.toString().slice(-8)}`,
      designation: 'Staff Tech Lead'
      // password omitted
    });
    assert(updateDetailsOnly.status === 200, 'Update details without password succeeds', `HTTP ${updateDetailsOnly.status}`);

    // 9. Staff can still sign in with previously set password
    console.log('\nStep 9: Confirm Previously Set Password Remains Valid');
    const staffLoginAgain = await request({ method: 'POST', path: '/api/auth/login' }, {
      email: staffEmail,
      password: newPassword
    });
    assert(staffLoginAgain.status === 200, 'Staff still logs in successfully with previously set password', `HTTP ${staffLoginAgain.status}`);

    // 10. Verify backend failure does not report false success
    console.log('\nStep 10: Backend Failures & Authorization Safeguards');
    const unauthorizedUpdate = await request({
      method: 'PUT',
      path: `/api/hr/employees/${employeeId}`,
      headers: { Authorization: `Bearer ${staffToken}` } // staff token cannot update credentials
    }, {
      password: 'HackedPassword@999'
    });
    assert(unauthorizedUpdate.status === 403, 'Unauthorized password update rejected with 403 Forbidden', `HTTP ${unauthorizedUpdate.status}`);

    const invalidShortPwd = await request({
      method: 'PUT',
      path: `/api/hr/employees/${employeeId}`,
      headers: { Authorization: `Bearer ${saToken}` }
    }, {
      password: '123' // short password
    });
    assert(invalidShortPwd.status === 400 || invalidShortPwd.status === 422, 'Short password (< 6 chars) rejected with 400 or 422 Unprocessable Entity', `HTTP ${invalidShortPwd.status}`);

  } catch (err) {
    console.error('Test execution error:', err);
    failed++;
  }

  console.log('\n================================================================');
  console.log(`JOURNEY AUDIT RESULT: ${passed} PASSED, ${failed} FAILED`);
  console.log('================================================================\n');

  if (failed > 0) process.exit(1);
}

verifyJourney();
