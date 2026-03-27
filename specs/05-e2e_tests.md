# E2E Test Specification

## Framework

Rails system tests using **Capybara** with **Playwright** (`capybara-playwright-driver` gem, headless Chromium).

## Test Pyramid Rationale

E2E tests cover **happy paths** and **key error paths** only — full user flows through the browser. Edge cases, validations, and boundary conditions are covered by unit and integration tests (see `specs/unit_tests.md`).

---

## Happy Path Tests

### Test: Full sign-up, confirmation, and login flow

**Description**: A new user registers, confirms their email, signs in, sees the dashboard, and logs out.

**Preconditions**: No existing user.

**Steps**:
1. Visit the root URL `/`.
2. Assert redirect to `/users/sign_in`.
3. Click "Sign up" link.
4. Fill in Name: "Jane Doe", Email: "jane@example.com", Password: "password123", Password confirmation: "password123".
5. Click "Sign up" button.
6. Assert flash notice about confirmation email sent.
7. Open the confirmation email (use `ActionMailer::Base.deliveries.last`).
8. Extract confirmation link and visit it.
9. Assert flash notice about successful confirmation.
10. Fill in Email: "jane@example.com", Password: "password123".
11. Click "Sign in" button.
12. Assert current path is `/dashboard`.
13. Assert page displays "Welcome, Jane Doe!".
14. Click "Log out" button.
15. Assert redirect to sign-in page.
16. Visit `/dashboard`.
17. Assert redirect to `/users/sign_in`.

**Expected Result**: User completes full lifecycle — register, confirm, login, view dashboard, logout.

---

### Test: Password reset flow

**Description**: An existing user resets their password and signs in with the new one.

**Preconditions**: Confirmed user exists (email: "jane@example.com", password: "password123").

**Steps**:
1. Visit `/users/sign_in`.
2. Click "Forgot your password?" link.
3. Fill in Email: "jane@example.com".
4. Click "Send me reset password instructions" button.
5. Open the reset email (`ActionMailer::Base.deliveries.last`).
6. Extract reset link and visit it.
7. Fill in New password: "newpassword456", Confirm new password: "newpassword456".
8. Click "Change my password" button.
9. Assert user is signed in and on `/dashboard`.
10. Assert page displays "Welcome, Jane Doe!".

**Expected Result**: Password is changed, user is authenticated with the new password.

---

### Test: Remember me keeps user authenticated

**Description**: User checks "Remember me" and remains authenticated after closing and reopening the browser.

**Preconditions**: Confirmed user exists.

**Steps**:
1. Visit `/users/sign_in`.
2. Fill in email and password.
3. Check "Remember me" checkbox.
4. Click "Sign in".
5. Assert on `/dashboard`.
6. Expire the session cookie (clear session, keep remember-me cookie via `Capybara.reset_sessions!` workaround or use a new browser session while preserving cookies).
7. Visit `/dashboard`.
8. Assert still on `/dashboard` (not redirected to sign-in).

**Expected Result**: Persistent cookie keeps user authenticated across sessions.

---

### Test: Account deletion

**Description**: User deletes their account and can no longer sign in.

**Preconditions**: Confirmed user exists (email: "jane@example.com", password: "password123").

**Steps**:
1. Sign in as the user.
2. Visit `/users/edit`.
3. Click "Delete my account" button.
4. Accept the browser confirmation dialog.
5. Assert flash notice about successful account deletion.
6. Assert redirect to root/sign-in page.
7. Attempt to sign in with the old credentials.
8. Assert flash alert "Invalid Email or password."

**Expected Result**: Account is destroyed, credentials are no longer valid.

---

### Test: Authenticated root redirects to dashboard

**Description**: An authenticated user visiting the root URL is redirected to the dashboard.

**Preconditions**: Confirmed user exists and is signed in.

**Steps**:
1. Sign in as the user via the UI.
2. Visit `/`.
3. Assert redirect to `/dashboard`.
4. Assert page displays the welcome greeting.

**Expected Result**: Authenticated root routes to the dashboard.

---

## Error Path Tests

### Test: Sign-in with unconfirmed account

**Description**: A user who has not confirmed their email cannot sign in.

**Preconditions**: Unconfirmed user exists (email: "john@example.com", password: "password123", `confirmed_at` is nil).

**Steps**:
1. Visit `/users/sign_in`.
2. Fill in Email: "john@example.com", Password: "password123".
3. Click "Sign in".
4. Assert flash alert: "You have to confirm your email address before continuing."
5. Assert still on the sign-in page.

**Expected Result**: Unconfirmed user is blocked from signing in with an informative message.

---

### Test: Sign-up with invalid data

**Description**: User attempts to sign up with blank fields and mismatched passwords, sees appropriate error messages.

**Preconditions**: None.

**Steps**:
1. Visit `/users/sign_up`.
2. Click "Sign up" without filling any fields.
3. Assert error messages: "Name can't be blank", "Email can't be blank", "Password can't be blank".
4. Fill in Name: "Jane", Email: "jane@example.com", Password: "pass123", Password confirmation: "different".
5. Click "Sign up".
6. Assert error message: "Password confirmation doesn't match Password".

**Expected Result**: Validation errors are displayed inline.

---

### Test: Sign-in with wrong credentials

**Description**: User attempts to sign in with an incorrect password.

**Preconditions**: Confirmed user exists (email: "jane@example.com").

**Steps**:
1. Visit `/users/sign_in`.
2. Fill in Email: "jane@example.com", Password: "wrongpassword".
3. Click "Sign in".
4. Assert flash alert: "Invalid Email or password."
5. Assert still on sign-in page.

**Expected Result**: Authentication fails with a generic error message (no credential enumeration).

---

### Test: Access dashboard without authentication

**Description**: Unauthenticated user tries to access the dashboard and is redirected.

**Preconditions**: No user is signed in.

**Steps**:
1. Visit `/dashboard`.
2. Assert redirect to `/users/sign_in`.
3. Assert flash alert: "You need to sign in or sign up before continuing."

**Expected Result**: Protected route redirects to sign-in with an informative message.

---

## Test Helpers

- Use `ActionMailer::Base.deliveries` to inspect sent emails in test environment.
- Extract URLs from email bodies using a regex or Nokogiri HTML parsing.
- Create confirmed users via fixtures or setup helpers for tests that need a pre-existing account.
- Use `sign_in` Devise test helper only in setup — E2E tests should go through the UI for sign-in.
