# Unit & Integration Test Specification

## Framework

**Minitest** with **fixtures** (Rails defaults). No RSpec, no FactoryBot.

## Test Pyramid Rationale

Unit and integration tests cover **validations, edge cases, and boundary conditions** — everything that doesn't need a full browser. E2E tests (see `specs/e2e_tests.md`) cover the full user flows.

---

## Fixtures

### `test/fixtures/users.yml`

```yaml
confirmed_user:
  name: "Jane Doe"
  email: "jane@example.com"
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password123') %>
  confirmed_at: <%= Time.current %>

unconfirmed_user:
  name: "John Smith"
  email: "john@example.com"
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password123') %>
  confirmed_at: null
```

---

## Model Tests

### File: `test/models/user_test.rb`

#### Name Validations

| Test Case                          | Input                  | Expected Result          |
|------------------------------------|------------------------|--------------------------|
| Valid user passes validation       | name: "Jane Doe"      | Valid                    |
| Name cannot be blank               | name: ""               | Invalid, error on name   |
| Name cannot be nil                 | name: nil              | Invalid, error on name   |
| Name cannot exceed 100 characters  | name: "a" * 101        | Invalid, error on name   |
| Name with exactly 100 characters   | name: "a" * 100        | Valid                    |
| Name with leading/trailing spaces  | name: "  Jane  "       | Valid (no auto-strip required) |

#### Email Validations

| Test Case                           | Input                      | Expected Result            |
|-------------------------------------|----------------------------|----------------------------|
| Valid email                         | email: "user@example.com"  | Valid                      |
| Email cannot be blank               | email: ""                  | Invalid, error on email    |
| Email must be unique                | email: (duplicate fixture) | Invalid, error on email    |
| Email uniqueness is case-insensitive| email: "JANE@EXAMPLE.COM"  | Invalid (conflicts with fixture) |
| Invalid email format                | email: "not-an-email"      | Invalid, error on email    |
| Email without domain                | email: "user@"             | Invalid, error on email    |

#### Password Validations

| Test Case                           | Input                     | Expected Result            |
|-------------------------------------|---------------------------|----------------------------|
| Password minimum 6 characters       | password: "12345"         | Invalid, error on password |
| Password with exactly 6 characters  | password: "123456"        | Valid                      |
| Password cannot be blank             | password: ""              | Invalid, error on password |

---

## Controller / Request Tests

### File: `test/controllers/dashboard_controller_test.rb`

| Test Case                                         | Setup                 | Action              | Expected Result                                       |
|---------------------------------------------------|-----------------------|----------------------|-------------------------------------------------------|
| Authenticated user can access dashboard           | Sign in as user       | GET `/dashboard`    | 200 OK, response contains "Welcome"                  |
| Unauthenticated user is redirected to sign-in     | No sign-in            | GET `/dashboard`    | 302 redirect to `/users/sign_in`                     |
| Dashboard displays the user's name                | Sign in as "Jane Doe" | GET `/dashboard`    | Response body contains "Welcome, Jane Doe!"          |

### File: `test/controllers/registrations_controller_test.rb`

| Test Case                                         | Setup              | Action                                        | Expected Result                                       |
|---------------------------------------------------|--------------------|------------------------------------------------|-------------------------------------------------------|
| Sign-up accepts name parameter                    | None               | POST `/users` with name, email, password      | User created with correct name                       |
| Sign-up without name fails                        | None               | POST `/users` without name                    | 422, error about name                                |
| Account update accepts name parameter             | Sign in as user    | PUT `/users` with name and current_password   | User name is updated                                 |
| Non-whitelisted params are ignored on sign-up     | None               | POST `/users` with extra param (e.g., admin)  | User created, extra param ignored                    |

### File: `test/controllers/sessions_controller_test.rb`

| Test Case                                         | Setup                       | Action                                        | Expected Result                                       |
|---------------------------------------------------|-----------------------------|------------------------------------------------|-------------------------------------------------------|
| Unconfirmed user cannot sign in                   | Unconfirmed user fixture    | POST `/users/sign_in` with valid credentials  | 401, flash about confirming email                    |

### File: `test/integration/routing_test.rb`

| Test Case                                         | Setup              | Action       | Expected Result                           |
|---------------------------------------------------|--------------------|--------------|-------------------------------------------|
| Root redirects to sign-in when unauthenticated    | No sign-in         | GET `/`      | 302 redirect to `/users/sign_in`         |
| Root redirects to dashboard when authenticated    | Sign in as user    | GET `/`      | 302 redirect to `/dashboard`             |

---

## Helper / View Tests

### File: `test/views/dashboard/show_test.rb`

Test the dashboard view rendering in isolation (or as part of controller tests):

| Test Case                          | Input                 | Expected Result                        |
|------------------------------------|-----------------------|----------------------------------------|
| Greeting shows full name           | user.name = "Jane Doe"| Rendered HTML contains "Welcome, Jane Doe!" |
| Logout button is present           | Any authenticated user| Rendered HTML contains logout form/button  |

### File: `test/views/shared/flash_test.rb`

| Test Case                              | Input                  | Expected Result                         |
|----------------------------------------|------------------------|-----------------------------------------|
| Notice flash renders with correct style| flash[:notice] = "OK"  | HTML contains notice message in styled div |
| Alert flash renders with correct style | flash[:alert] = "Err"  | HTML contains alert message in styled div  |
| No flash renders nothing               | flash is empty         | No flash message divs rendered             |

---

## Test Helpers

### Devise Integration

Include Devise test helpers in integration and controller tests:

```ruby
# test/test_helper.rb
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
```

This provides `sign_in(user)` and `sign_out(user)` for setting up authenticated state in non-E2E tests.

### Shared Setup

For controller tests that require authentication:

```ruby
setup do
  @user = users(:confirmed_user)
  sign_in @user
end
```
