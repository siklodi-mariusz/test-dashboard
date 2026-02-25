# Dashboard Specification

## Overview

The dashboard is the main authenticated view of the application. It displays a personalized greeting and provides a logout action.

## Route

| Method | Path         | Controller#Action      | Purpose           |
|--------|--------------|------------------------|--------------------|
| GET    | `/dashboard` | `dashboard#show`       | Show dashboard     |

## Root URL Behavior

- **Unauthenticated users**: `GET /` redirects to `/users/sign_in`.
- **Authenticated users**: `GET /` redirects to `/dashboard`.

Configure in `routes.rb`:

```ruby
authenticated :user do
  root "dashboard#show", as: :authenticated_root
end

root to: redirect("/users/sign_in")
```

Devise's `authenticate_user!` before action on `DashboardController` enforces authentication. Unauthenticated access to `/dashboard` redirects to `/users/sign_in` with a flash: "You need to sign in or sign up before continuing."

## Dashboard Controller

- `DashboardController` inherits from `ApplicationController`.
- `before_action :authenticate_user!` is set.
- Single action: `show` — no instance variables needed (current user is available via `current_user`).

## Page Content

### Greeting

Display the user's full name in a welcome message:

```
Welcome, {current_user.name}!
```

### Logout Button

A logout button/link that submits `DELETE /users/sign_out`:

```erb
<%= button_to "Log out", destroy_user_session_path, method: :delete %>
```

After logout, the user is redirected to the sign-in page.

## Layout

- Centered content on the page.
- The greeting is prominently displayed (large heading).
- The logout button is clearly visible below the greeting.
- See `specs/ui.md` for detailed styling.
