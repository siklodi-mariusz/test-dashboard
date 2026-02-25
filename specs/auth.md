# Authentication Specification

## Tech Stack

- **Framework**: Rails 8.2
- **Frontend**: Hotwire (Turbo for navigation and form submissions, Stimulus where needed)
- **Styling**: Tailwind CSS v4 (see `specs/ui.md`)
- **Database**: SQLite
- **Authentication**: Devise gem

## User Model

### Schema

| Column                 | Type     | Constraints                          |
|------------------------|----------|--------------------------------------|
| `name`                 | string   | NOT NULL, length 1–100               |
| `email`                | string   | NOT NULL, unique, Devise validatable  |
| `encrypted_password`   | string   | NOT NULL, Devise managed             |
| `reset_password_token` | string   | Devise recoverable                   |
| `reset_password_sent_at` | datetime | Devise recoverable                 |
| `remember_created_at`  | datetime | Devise rememberable                  |
| `confirmation_token`   | string   | Devise confirmable                   |
| `confirmed_at`         | datetime | Devise confirmable                   |
| `confirmation_sent_at` | datetime | Devise confirmable                   |
| `unconfirmed_email`    | string   | Devise confirmable (email change)    |
| `created_at`           | datetime | NOT NULL                             |
| `updated_at`           | datetime | NOT NULL                             |

### Indexes

- Unique index on `email`
- Unique index on `reset_password_token`
- Unique index on `confirmation_token`

### Validations

- `name`: presence, length maximum 100
- `email`: presence, format, uniqueness (handled by Devise `validatable`)
- `password`: minimum 6 characters (handled by Devise `validatable`)

## Devise Configuration

### Modules

Enable the following Devise modules on the User model:

- **database_authenticatable** — hashes and stores password, authenticates via POST
- **registerable** — sign-up, edit, and delete account
- **recoverable** — password reset via email
- **rememberable** — "remember me" persistent session cookie
- **validatable** — built-in email/password validations
- **confirmable** — email confirmation before account activation

### Routes

Devise generates routes under `/users/`:

| Path                          | Purpose                  |
|-------------------------------|--------------------------|
| `GET /users/sign_up`         | Registration form        |
| `POST /users`                | Create account           |
| `GET /users/sign_in`         | Login form               |
| `POST /users/sign_in`        | Authenticate             |
| `DELETE /users/sign_out`     | Logout                   |
| `GET /users/password/new`    | Request password reset   |
| `POST /users/password`       | Send reset email         |
| `GET /users/password/edit`   | Reset password form      |
| `PUT /users/password`        | Update password          |
| `GET /users/confirmation/new`| Resend confirmation      |
| `POST /users/confirmation`   | Send confirmation email  |
| `GET /users/confirmation`    | Confirm account (via token) |
| `GET /users/edit`            | Edit account             |
| `PUT /users`                 | Update account           |
| `DELETE /users`              | Delete account           |

## Sign-Up Flow

### Form Fields

1. **Name** — text input, required
2. **Email** — email input, required
3. **Password** — password input, required, minimum 6 characters
4. **Password confirmation** — password input, required, must match password

### Behavior

1. User visits `/users/sign_up`.
2. Fills in name, email, password, and password confirmation.
3. Submits the form.
4. On success:
   - Account is created with `confirmed_at = nil`.
   - Confirmation email is sent with a tokenized link.
   - User sees a flash message: "A message with a confirmation link has been sent to your email address."
   - User is redirected to the sign-in page.
5. On failure:
   - Form re-renders with inline error messages (e.g., "Email has already been taken", "Password is too short").

### Custom Registration Controller

Override Devise's `RegistrationsController` to permit the `name` parameter via `sign_up_params` and `account_update_params`.

## Email Confirmation Flow

1. User receives an email with a confirmation link containing a token.
2. Clicking the link hits `GET /users/confirmation?confirmation_token=...`.
3. On valid token:
   - `confirmed_at` is set to the current timestamp.
   - User sees a flash: "Your email address has been successfully confirmed."
   - User is redirected to the sign-in page.
4. On invalid/expired token:
   - User sees an error message.
   - Link to resend confirmation is available at `/users/confirmation/new`.

## Sign-In Flow

### Form Fields

1. **Email** — email input, required
2. **Password** — password input, required
3. **Remember me** — checkbox

### Behavior

1. User visits `/users/sign_in`.
2. Fills in email and password. Optionally checks "Remember me."
3. Submits the form.
4. On success:
   - Session is created. If "Remember me" is checked, a persistent cookie is set.
   - User is redirected to `/dashboard`.
5. On failure:
   - Flash alert: "Invalid Email or password."
   - Form re-renders.
6. If the account is not yet confirmed:
   - Flash alert: "You have to confirm your email address before continuing."

## Password Reset Flow

1. User clicks "Forgot your password?" on the sign-in page.
2. Visits `/users/password/new`, enters their email, submits.
3. Reset email is sent with a tokenized link.
4. User clicks the link → `/users/password/edit?reset_password_token=...`.
5. Enters new password and confirmation, submits.
6. On success:
   - Password is updated.
   - User is signed in and redirected to `/dashboard`.
7. On failure:
   - Error messages are displayed (e.g., "Reset password token is invalid").

## Remember Me

- When checked at sign-in, Devise sets a persistent cookie.
- The user remains authenticated across browser sessions until the cookie expires or they explicitly log out.
- Default Devise cookie duration (2 weeks).

## Account Deletion

1. User navigates to `/users/edit`.
2. Clicks "Delete my account."
3. A confirmation dialog appears (browser-native `confirm()`).
4. On confirmation:
   - The user record is destroyed.
   - Session is cleared.
   - User is redirected to the root URL with flash: "Your account has been successfully deleted."
5. The user can no longer sign in with the deleted credentials.

## Session Management

- Authenticated session is stored server-side (Rails default cookie session store).
- On logout (`DELETE /users/sign_out`), the session is destroyed.
- After logout, user is redirected to the sign-in page.
