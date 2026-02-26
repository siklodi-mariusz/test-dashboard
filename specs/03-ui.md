# UI Specification

## Framework

Tailwind CSS v4, integrated via `tailwindcss-rails` gem. Uses the new CSS-first configuration (no `tailwind.config.js`).

## Design Principles

- Clean, minimal, modern aesthetic.
- Mobile-first responsive design.
- Card-based centered layouts for all forms and the dashboard.
- Consistent spacing and typography throughout.

## Color Palette

Use Tailwind's built-in **indigo** palette as the primary color:

| Use Case          | Class                    |
|-------------------|--------------------------|
| Primary buttons   | `bg-indigo-600 hover:bg-indigo-500 text-white` |
| Primary links     | `text-indigo-600 hover:text-indigo-500` |
| Focus rings       | `focus:ring-indigo-500`  |
| Error text        | `text-red-600`           |
| Error border      | `border-red-500`         |
| Alert flash       | `bg-red-50 text-red-800 border-red-200`   |
| Notice flash      | `bg-blue-50 text-blue-800 border-blue-200` |
| Page background   | `bg-gray-50`            |
| Card background   | `bg-white`              |

## Typography

- Headings: `text-2xl font-bold text-gray-900` (page titles), `text-lg font-semibold text-gray-900` (section titles).
- Body text: `text-sm text-gray-600`.
- Form labels: `text-sm font-medium text-gray-700`.

## Page Layout

All pages share a common structure:

```html
<!-- Full-height centered layout -->
<div class="min-h-screen bg-gray-50 flex items-center justify-center px-4 py-12">
  <div class="w-full max-w-md">
    <!-- Card -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-8">
      <!-- Content -->
    </div>
  </div>
</div>
```

- `max-w-md` (28rem) for auth forms.
- `max-w-lg` or wider for the dashboard if needed.
- Card has rounded corners, subtle shadow, and border.

## Form Styling

### Labels

```html
<label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
```

### Text Inputs

```html
<input type="text" class="block w-full rounded-lg border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500 focus:outline-none sm:text-sm" />
```

- Full width within the card.
- Rounded corners, gray border.
- Indigo focus ring and border.
- Spacing between fields: `space-y-5` on the form container.

### Checkboxes

```html
<label class="flex items-center gap-2">
  <input type="checkbox" class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" />
  <span class="text-sm text-gray-600">Remember me</span>
</label>
```

### Buttons (Primary)

```html
<button class="w-full rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors">
  Sign in
</button>
```

- Full width within forms.
- Indigo background with hover state.
- Focus ring with offset.

### Buttons (Danger)

For destructive actions like "Delete my account":

```html
<button class="rounded-lg bg-red-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors">
  Delete my account
</button>
```

### Links

```html
<a href="#" class="text-sm text-indigo-600 hover:text-indigo-500">Forgot your password?</a>
```

## Flash Messages

Displayed at the top of the card content, before the form or main content:

```html
<!-- Notice (info/success) -->
<div class="mb-6 rounded-lg border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-800">
  Message here
</div>

<!-- Alert (error/warning) -->
<div class="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
  Message here
</div>
```

## Inline Validation Errors

Displayed below the relevant input field:

```html
<p class="mt-1 text-sm text-red-600">can't be blank</p>
```

When a field has errors, its input border changes to `border-red-500`.

## Page-Specific Layouts

### Sign-Up / Sign-In / Password Reset / Confirmation Pages

- Centered card layout (`max-w-md`).
- App name or heading at the top of the card (e.g., "Create your account", "Sign in to your account", "Resend confirmation instructions").
- Form fields stacked vertically with `space-y-5`.
- Submit button at the bottom.
- Links below the card (e.g., "Already have an account? Sign in", "Forgot your password?").
- The resend confirmation page (`/users/confirmation/new`) follows the same layout: a single email input and a submit button.

### Dashboard Page

- Centered card layout.
- Large greeting text: `text-2xl font-bold text-gray-900`.
- Logout button below the greeting with some top margin (`mt-8`).
- The logout button uses the primary button style.

### Account Edit Page

- Same card layout as auth forms.
- Current password required for email/password changes.
- "Delete my account" section at the bottom, visually separated (e.g., `border-t border-gray-200 pt-6 mt-6`).
- Delete button uses the danger button style.

## Responsive Behavior

- On mobile (< 640px): Card takes full width with `px-4` page padding. Content stacks naturally.
- On tablet/desktop (>= 640px): Card is centered with `max-w-md` constraint.
- No complex responsive breakpoints needed — the centered card layout works at all sizes.
