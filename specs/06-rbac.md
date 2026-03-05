# Role-Based Access Control Specification

## Overview

Users have a `role` attribute with two possible values: `user` (default) and `admin`. Regular users see the existing dashboard. Admins get a full admin panel with a sidebar layout to manage all users in the system (view, edit, change roles, delete).

## User Model Changes

### Schema Addition

| Column | Type    | Constraints              |
|--------|---------|--------------------------|
| `role` | integer | NOT NULL, default: `0`   |

### Enum

```ruby
enum :role, { user: 0, admin: 1 }, default: :user
```

This provides `user.admin?`, `user.user?`, and `User.roles`.

### Validations

- The last remaining admin cannot be demoted to `user`. A model-level validation checks that at least one admin exists when `role` changes from `admin` to another value.
- The `role` parameter must NOT be added to Devise's `sign_up_params` or `account_update_params` — users cannot self-assign roles.

---

## Routes

### Admin Namespace

```ruby
namespace :admin do
  resources :users, only: [:index, :show, :edit, :update, :destroy]
  root "users#index"
end
```

No `new` or `create` actions — users self-register via Devise.

### Generated Routes

| Method     | Path                     | Controller#Action      | Purpose             |
|------------|--------------------------|------------------------|----------------------|
| GET        | `/admin`                 | `admin/users#index`    | Admin root (users)  |
| GET        | `/admin/users`           | `admin/users#index`    | List all users      |
| GET        | `/admin/users/:id`       | `admin/users#show`     | View user details   |
| GET        | `/admin/users/:id/edit`  | `admin/users#edit`     | Edit user form      |
| PATCH/PUT  | `/admin/users/:id`       | `admin/users#update`   | Update user         |
| DELETE     | `/admin/users/:id`       | `admin/users#destroy`  | Delete user         |

---

## Post-Sign-In Redirect

Override `after_sign_in_path_for` in `ApplicationController`:

- **Admin users** → redirected to `/admin` (admin root)
- **Regular users** → redirected to `/dashboard` (existing behavior)

This applies to all sign-in paths: normal login, password reset, confirmation, and remember-me.

---

## Authorization

### Admin::BaseController

All admin controllers inherit from `Admin::BaseController`:

- `before_action :authenticate_user!` — must be logged in
- `before_action :require_admin!` — must have `admin` role
- `layout "admin"` — uses the admin sidebar layout

Non-admin users accessing any `/admin/*` route are redirected to `/dashboard` with flash alert: "You are not authorized to access this page."

---

## Admin::UsersController

Inherits from `Admin::BaseController`.

### Actions

| Action    | Behavior                                                                 |
|-----------|--------------------------------------------------------------------------|
| `index`   | Lists all users ordered by `created_at DESC`                            |
| `show`    | Displays user details (name, email, role, confirmed status, join date)  |
| `edit`    | Form to edit name, email, and role                                      |
| `update`  | Updates permitted attributes (`name`, `email`, `role`). On failure, re-renders edit with 422. |
| `destroy` | Deletes the user. Admin cannot delete themselves — redirects with alert. |

### Permitted Parameters

```ruby
params.require(:user).permit(:name, :email, :role)
```

Password is not editable through the admin panel — users manage their own passwords via Devise.

### Edge Cases

1. **Admin cannot delete themselves**: `destroy` checks `@user == current_user` and redirects with alert: "You cannot delete your own account."
2. **Last admin cannot be demoted**: Model validation prevents changing the last admin's role. The `update` action re-renders the edit form with the error message.

---

## Admin Layout

A new layout file `app/views/layouts/admin.html.erb` with a sidebar + main content area.

### Structure

```
┌──────────────┬────────────────────────────────────────────┐
│  Sidebar     │  Main Content                              │
│  (w-64)      │  (flex-1)                                  │
│              │                                            │
│  Admin Panel │  Flash messages                            │
│  {user name} │  Page content (yield)                      │
│              │                                            │
│  ── Nav ──   │                                            │
│  Users       │                                            │
│              │                                            │
│              │                                            │
│  ── Bottom ──│                                            │
│  Dashboard   │                                            │
│  Log out     │                                            │
└──────────────┴────────────────────────────────────────────┘
```

### Sidebar Sections

1. **Header** (`p-6`, `border-b`): "Admin Panel" title + current user's name
2. **Navigation** (`p-4`): "Users" link — active state uses `bg-indigo-50 text-indigo-600`, inactive uses `text-gray-700 hover:bg-gray-50`
3. **Bottom** (`p-4`, `border-t`): "Back to Dashboard" link + "Log out" button

### Styling

- Sidebar: `w-64 bg-white border-r border-gray-200`
- Body: `flex min-h-screen`
- Main content: `flex-1 p-8`
- Same `<head>` as `application.html.erb` (shared CSS, JS, meta tags)

---

## Admin Views

### Users Index (`admin/users/index.html.erb`)

A table inside a card (`bg-white rounded-xl shadow-sm border border-gray-200`):

| Column   | Content                                                       |
|----------|---------------------------------------------------------------|
| Name     | Link to user show page (`text-indigo-600`)                   |
| Email    | Plain text                                                    |
| Role     | Badge — admin: `bg-indigo-100 text-indigo-800`, user: `bg-gray-100 text-gray-800` |
| Joined   | Formatted date (`%b %d, %Y`)                                |
| Actions  | "Edit" link + "Delete" button (not shown for current user)   |

Delete uses `turbo_confirm` for a browser confirmation dialog.

### User Show (`admin/users/show.html.erb`)

A detail card displaying:
- Name (heading)
- Email, Role (badge), Confirmed status, Join date (definition list)
- "Edit" button (primary style) + "Delete" button (danger style, hidden for self)
- "Back to users" link above the card

### User Edit (`admin/users/edit.html.erb`)

A form matching existing Tailwind form styling:
- Name text input
- Email input
- Role select dropdown (`User.roles.keys`)
- "Update user" submit button (primary style)
- Inline validation errors below fields
- "Back to user" link above the card

---

## Seeds

### First Admin User

```ruby
User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Admin"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :admin
  user.confirmed_at = Time.current
end
```

Idempotent — safe to run multiple times. Admin is pre-confirmed so they can sign in immediately.

---

## Live Admin Notifications

When a new user signs up, all admins viewing any admin page receive real-time notifications via Turbo Streams over Action Cable.

### How It Works

A single Action Cable stream `"admin_notifications"` is subscribed in the admin layout. The `User` model broadcasts two Turbo Stream actions on `after_create_commit`:

1. **Toast notification** — `append` to `#admin_toast_container` (visible on every admin page)
2. **Table row** — `prepend` to `#admin_users_table_body` (only rendered on the users index; silently skipped on other pages since Turbo Streams ignore missing targets)

### Toast Behavior

- Slides in from the right with a CSS transition (Stimulus `toast` controller)
- Shows "New user signed up" with the user's name and email
- Auto-dismisses after 5 seconds
- Can be manually closed via an × button

### Subscription Persistence

The `turbo_stream_from` tag is wrapped in a `data-turbo-permanent` div to prevent duplicate WebSocket subscriptions when navigating between admin pages via Turbo Drive. Without this, Turbo's page cache creates additional `<turbo-cable-stream-source>` elements on each navigation, causing duplicate toasts.

### Users Index Table

The `<tbody>` has `id="admin_users_table_body"` for stream targeting. Each `<tr>` is rendered via the `admin/users/_user_row` partial, reused by both the normal index render and the broadcast. The partial uses `local_assigns[:current_user]` to conditionally show the Delete button — in broadcast context `current_user` is `nil`, so the Delete button shows (correct since a newly registered user is never the viewing admin).

### Files

| File | Purpose |
|------|---------|
| `app/javascript/controllers/toast_controller.js` | Stimulus controller for toast animation and auto-dismiss |
| `app/views/admin/shared/_new_user_toast.html.erb` | Toast card partial |
| `app/views/admin/users/_user_row.html.erb` | Extracted table row partial |

---

## Regular Users

No changes to the existing user experience:
- Sign up, sign in, dashboard, account management all remain the same
- New users default to `role: :user`
- Regular users cannot access `/admin/*` routes

---

## Files to Create or Modify

| File                                          | Action |
|-----------------------------------------------|--------|
| `db/migrate/..._add_role_to_users.rb`         | Create |
| `app/models/user.rb`                          | Modify |
| `config/routes.rb`                            | Modify |
| `app/controllers/application_controller.rb`   | Modify |
| `app/controllers/admin/base_controller.rb`    | Create |
| `app/controllers/admin/users_controller.rb`   | Create |
| `app/views/layouts/admin.html.erb`            | Create |
| `app/views/admin/users/index.html.erb`        | Create |
| `app/views/admin/users/show.html.erb`         | Create |
| `app/views/admin/users/edit.html.erb`         | Create |
| `db/seeds.rb`                                 | Modify |
| `test/fixtures/users.yml`                     | Modify |
| `test/models/user_test.rb`                    | Modify |
| `test/controllers/admin/users_controller_test.rb` | Create |
| `test/integration/routing_test.rb`            | Modify |
| `test/controllers/dashboard_controller_test.rb` | Modify |
| `test/system/admin_test.rb`                   | Create |
| `app/javascript/controllers/toast_controller.js` | Create |
| `app/views/admin/shared/_new_user_toast.html.erb` | Create |
| `app/views/admin/users/_user_row.html.erb`    | Create |
