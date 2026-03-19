# CP-3094 — Admin Can Invite Users

**Ticket:** [CP-3094](https://consultport.atlassian.net/browse/CP-3094)
**Date:** 2026-03-19
**Scope:** P0 only
**Prototype:** `public/prototypes/CP-3094/CP-3094.html`
**Design handoff:** `public/prototypes/CP-3094/CP-3094-design-handoff.html`

---

## Summary

Add an invitation system so admins can invite new users by email with a pre-assigned role. The invite form lives in a modal on the Admin > Users page, sends a transactional email with a 72-hour token, and the invitee completes registration on a dedicated page with a locked email field. Pending invitations are shown in a separate table below existing users (hidden when none exist). Admins can edit pending invites. Self-registration with a pending invite email marks the invite as completed and assigns the invite role.

---

## Requirements

1. New `Invitation` model with `email`, `role` (integer enum matching User), `token` (unique, `SecureRandom.urlsafe_base64(32)`), `invited_by_id` (FK to users), `accepted_at` (nullable datetime), `expires_at` (72h from creation).
2. Invite modal on Admin > Users page with email (required, unique among users + pending invites) and role selector (default: user).
3. Validation states in the modal: error for existing user (red box, disables submit), warning for pending invite (yellow box, disables submit), empty email validation.
4. Send invitation email on create with inviter's name, CTA link to `/invitations/:token`, expiry notice ("This link expires in 72 hours").
5. Registration page at `GET /invitations/:token` — locked email, name, password, confirm password fields.
6. On accept: create User with pre-assigned role, set `confirmed_at` (skip email confirmation), mark `accepted_at`, sign in, redirect to dashboard/admin per existing `after_sign_in_path_for` logic.
7. Expired token (`expires_at < now`) shows "Invitation Expired" page with email info box.
8. Invalid/used/missing token shows "Invalid Invitation" page.
9. Pending invitations table on Admin > Users page (hidden when empty), showing: email, role, invited by, sent date, expiry date.
10. Edit pending invite reuses same modal UI — both email and role are editable.
11. Self-registration hook: after a user self-registers, check for pending invite by email — if found, mark invite `accepted_at` and assign invite role. User still goes through normal Devise email confirmation.
12. Mailer from address: `"Test Dashboard <noreply@testdashboard.com>"`.

---

## Technical Approach

### 1. Migration — `CreateInvitations`

New table `invitations`:

| Column | Type | Constraints |
|---|---|---|
| `email` | string | null: false |
| `role` | integer | null: false, default: 0 |
| `token` | string | null: false |
| `invited_by_id` | bigint | FK to users, null: false |
| `accepted_at` | datetime | nullable |
| `expires_at` | datetime | null: false |

Indexes:
- Unique on `token`
- Unique on `email`

### 2. Model — `Invitation` (`app/models/invitation.rb`)

- `belongs_to :invited_by, class_name: "User"`
- `enum :role, { user: 0, admin: 1 }` (matches User enum)
- Validations:
  - `email`: presence, format, uniqueness among pending invitations (scope: `accepted_at: nil` + `expires_at > now`), not already a registered user
- Callbacks:
  - `before_create`: generate `token` via `SecureRandom.urlsafe_base64(32)`, set `expires_at` to `72.hours.from_now`
- Scopes:
  - `pending` — `where(accepted_at: nil).where("expires_at > ?", Time.current)`
  - `expired` — `where(accepted_at: nil).where("expires_at <= ?", Time.current)`
- Instance methods: `expired?`, `accepted?`, `pending?`

### 3. Routes (`config/routes.rb`)

```ruby
# Public route for invitation acceptance (outside admin namespace, no auth required)
resources :invitations, only: [:show, :update], param: :token

# Admin routes (inside existing admin namespace)
namespace :admin do
  resources :invitations, only: [:new, :create, :edit, :update]
end
```

### 4. Controller — `Admin::InvitationsController` (`app/controllers/admin/invitations_controller.rb`)

Inherits from `Admin::BaseController` (admin auth enforced).

| Action | Behaviour |
|---|---|
| `new` | Build `@invitation`, render modal form |
| `create` | Create invitation, send `InvitationMailer.invite`, redirect to `admin_users_path` with success flash |
| `edit` | Find invitation by id, render same modal form (pre-filled) |
| `update` | Update email/role on pending invite, redirect to `admin_users_path` |

Strong params: `email`, `role`.

### 5. Controller — `InvitationsController` (`app/controllers/invitations_controller.rb`)

Public controller — no authentication required.

| Action | Behaviour |
|---|---|
| `show` | Look up invitation by `token`. If not found or already accepted → render `invalid`. If expired → render `expired`. Otherwise → render account setup form. |
| `update` | Validate name + password + password_confirmation. Create `User` with `confirmed_at: Time.current`, role from invite. Set `accepted_at` on invitation. Sign in via `sign_in(user)`. Redirect using existing `after_sign_in_path_for` logic. On validation failure → re-render `show` with errors. |

Server-side enforcement: ignore any email param in the `update` — always use the invitation's email.

### 6. Mailer — `InvitationMailer` (`app/mailers/invitation_mailer.rb`)

Single method: `invite(invitation)`.

- From: `"Test Dashboard <noreply@testdashboard.com>"`
- To: `invitation.email`
- Subject: "You've been invited to Test Dashboard"
- Body: inviter name (`invitation.invited_by.name`), CTA button linking to `invitation_url(invitation.token)`, plain-text fallback URL, "This link expires in 72 hours" notice
- Uses existing mailer layout (`app/views/layouts/mailer.html.erb`)
- Both HTML and plain-text templates

### 7. Views

#### Admin side (uses admin layout)

**Modify existing:**
- `app/views/admin/users/index.html.erb` — Add "Invite User" button in page header (flex row with title). Render pending invitations table below users table, conditionally hidden when `@pending_invitations` is empty.

**New files:**
- `app/views/admin/invitations/_form.html.erb` — Modal partial. Email input + role select + error/warning containers + cancel/submit buttons. Shared between `new` and `edit`.
- `app/views/admin/invitations/new.html.erb` — Renders modal overlay + form partial (empty).
- `app/views/admin/invitations/edit.html.erb` — Renders modal overlay + form partial (pre-filled with existing invitation data).
- `app/views/admin/invitations/_invitation_row.html.erb` — Table row partial for a single pending invitation (email, role badge, invited by name, sent date, expiry date + "Expired" badge if expired, Edit link).

#### Invitee side (application layout, no sidebar)

- `app/views/invitations/show.html.erb` — Account setup page. App icon + label at top. Card with "You've been invited!" heading, locked email field (readonly + lock icon), name, password, confirm password. "Create My Account" submit. Footer note about 72h expiry.
- `app/views/invitations/expired.html.erb` — Yellow clock icon, "Invitation Expired" title, description, email info box, "Back to sign in" link.
- `app/views/invitations/invalid.html.erb` — Red X icon, "Invalid Invitation" title, description, red error box, "Back to sign in" link.

#### Email templates

- `app/views/invitation_mailer/invite.html.erb` — HTML email with CTA button.
- `app/views/invitation_mailer/invite.text.erb` — Plain text fallback with URL.

### 8. Stimulus Controller — `invite_modal_controller.js`

- Open modal (triggered by "Invite User" button or "Edit" link)
- Close modal on: X button, Cancel button, backdrop click, Escape key
- Focus email input on open
- Discard form state on close

### 9. Self-Registration Hook

In `Users::RegistrationsController`, after successful registration:
- Check for a pending `Invitation` where `email` matches the new user's email and `accepted_at` is nil
- If found: set `invitation.accepted_at = Time.current`, update `user.role` to `invitation.role`, save both
- User still goes through normal Devise email confirmation (do NOT set `confirmed_at`)

### 10. Update `ApplicationMailer`

Change default from address:
```ruby
default from: "Test Dashboard <noreply@testdashboard.com>"
```

### 11. Load Pending Invitations in `Admin::UsersController#index`

Add to the existing `index` action:
```ruby
@pending_invitations = Invitation.where(accepted_at: nil)
                                 .includes(:invited_by)
                                 .order(created_at: :desc)
```

This includes both active and expired invitations (expired ones are shown with an "Expired" badge per the design).

---

## UI Reference

### Prototype as source code

The HTML prototypes in `public/prototypes/CP-3094/` contain production-ready Tailwind markup that should be used directly as the starting point for Rails views. Rather than building UI from scratch, **copy the HTML structure and classes from the prototype** and adapt them into ERB partials.

| Prototype file | What to extract |
|---|---|
| `CP-3094.html` | Interactive prototype with all screens. Copy HTML for: users page header with "Invite User" button, pending invitations table, invite modal (all states), cancel confirmation modal, account setup page, expired page, invalid page. |
| `CP-3094-design-handoff.html` | Design spec with exact Tailwind classes for every component, including spacing, typography, colors, and states. Use as the authoritative reference when the prototype markup differs from the spec. |

Both files are viewable in the browser at `http://localhost:3000/prototypes/CP-3094/CP-3094.html` and `http://localhost:3000/prototypes/CP-3094/CP-3094-design-handoff.html`.

### Key screens

1. **Users page** — Users table + "Invite User" button + "Pending Invitations" section below (hidden when empty)
2. **Invite modal (default)** — Email input + role select + Cancel/Send Invitation buttons
3. **Invite modal (error)** — Red input border, red error box ("A user with this email already exists"), submit disabled
4. **Invite modal (warning)** — Yellow input border, yellow warning box ("An invitation is already pending for this email"), submit disabled
5. **Account setup page** — Centered card, app icon, locked email, name/password/confirm fields
6. **Expired page** — Yellow clock icon, expiry message, email info box, back link
7. **Invalid page** — Red X icon, invalid message, red error box, back link

---

## Out of Scope

- Resend invitation (P1)
- Cancel/revoke invitation (P1)
- Hotwire Turbo Stream inline updates for invite form and pending list (P1)
- Bulk invitations via CSV (P2)
- Invitation-only mode / disable self-registration (P2)
- Custom invitation messages (P2)
- Audit logging of invite events (P2)
- Configurable expiry duration (P2)

---

## Open Questions

None — all blocking questions resolved during planning.

---

## Key Decisions Log

| # | Question | Decision | Rationale |
|---|---|---|---|
| 1 | `devise_invitable` gem vs custom model? | Custom `Invitation` model | More transparent, full control, small scope |
| 2 | Skip email confirmation for invited users? | Yes — set `confirmed_at` on acceptance | Invite itself serves as email verification |
| 3 | Self-registration with pending invite? | Allow it, mark invite completed, assign invite role | User still confirms email normally |
| 4 | Edit role on pending invite? | Yes, reuse same modal | Standard CRUD, both email and role editable |
| 5 | Pending invitations location? | Same page as users, separate table below | Per prototype design |
| 6 | No pending invitations? | Hide the section entirely | Cleaner UI |
| 7 | Token format | `SecureRandom.urlsafe_base64(32)` | Cryptographically secure, URL-safe |
| 8 | Mailer from address | `"Test Dashboard <noreply@testdashboard.com>"` | Consistent branding |
