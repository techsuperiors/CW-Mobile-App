# AGENTS.md

## Project intent
This is a Flutter production app. All changes must preserve the existing architecture, design system, state management approach, and error handling conventions already present in the codebase.

The goal is not to introduce a new style on every task. The goal is to extend the app consistently, safely, and maintainably.

---

## Core non-negotiable rules
1. Follow the existing clean architecture used in this project.
2. Do not introduce a different architecture or pattern inside a feature that already has an established flow.
3. Do not call APIs directly from UI widgets.
4. Do not place business logic in UI.
5. Do not use magic numbers for spacing, radius, font sizes, or dimensions.
6. Always use shared design tokens and theme utilities already defined in the project.
7. Make the smallest correct change needed for the task.
8. Do not refactor unrelated code unless it is necessary to complete the task safely.
9. If behavior is ambiguous, ask before implementing.
10. Prefer consistency with the existing codebase over inventing a new pattern.

---

## Required workflow for every task
1. First inspect nearby files and identify the existing local pattern.
2. Summarize the pattern found in the relevant files before implementing.
3. Implement the smallest correct change.
4. Reuse existing architecture, design tokens, and shared utilities.
5. Run `flutter analyze` on all changed files.
6. Verify the actual user flow affected by the change.
7. In the final response, mention:
   - what pattern was followed
   - what files were changed
   - how the implementation follows architecture, design system, error handling, responsiveness, and performance expectations

---

## Styling and design system
- Use `AppSpacing` for spacing, padding, margins, gaps, and sizes wherever applicable.
- Use `AppTextStyles` / `AppTextThemes` for all text styling.
- Reuse shared colors, radii, dimensions, assets, and common widgets from `core`.
- Avoid hardcoded values such as:
  - `SizedBox(height: 12)`
  - `EdgeInsets.all(16)`
  - direct `TextStyle(...)`
  - ad hoc color values
- If a shared design token is missing and the value is likely to be reused, add it to the appropriate core file instead of hardcoding it repeatedly.
- Do not create feature-specific UI patterns when an equivalent shared pattern already exists in the project.
- Keep UI visually consistent with nearby screens in the same feature unless the user explicitly asks for a new design direction.

---

## Architecture and layering
- Follow the project’s existing clean architecture boundaries.
- Keep responsibilities separated properly:
  - UI: rendering and interaction only
  - Bloc/Cubit/ViewModel: state orchestration only
  - Use cases / repositories / data sources: domain and data logic only
- Reuse the same folder structure and naming pattern already used in nearby features.
- Do not create new abstractions unless:
  - the surrounding feature already follows that abstraction pattern, or
  - the separation is clearly necessary for maintainability

---

## Dependency and infrastructure rules
- Do not instantiate `Dio`, `ApiClient`, repositories, or use cases inside widgets.
- Do not create new feature-local networking stacks when one already exists.
- Reuse existing injected/shared dependencies for the feature.
- If a feature temporarily composes dependencies locally, do not create a second parallel instance elsewhere in that same feature.
- Do not introduce an alternative API path for a feature that already uses an established repository/data source flow.

---

## Networking and session rules
- Use the project’s existing network layer and request flow for the feature.
- Do not add direct token reads/writes inside feature UI or feature business logic.
- Do not navigate to login directly from feature UI, repositories, or data sources.
- Keep session expiry (`401`) handling centralized in the app’s existing auth/session flow.
- Do not add screen-level logout or token-expiry handling when the project already has a centralized mechanism.

---

## State ownership and mutation rules
- Every mutation must update the real owning feature state, not only temporary local widget/sheet/dialog state.
- If a child flow modifies data shown in a parent list/detail screen, sync the updated data back to the parent source of truth.
- Do not rely on closing and reopening a bottom sheet/dialog to refresh stale state.
- Prefer local immutable state patching over full refetches when the changed entity is already known.
- Use per-item loading states for item-level mutations where possible.
- Avoid full-screen loading states for small actions like like, bookmark, reaction, or similar item-level changes.
- If mutation state needs to be tracked, make it explicit in bloc/cubit state rather than hiding it in widget-local logic.

---

## API contract resilience
- Do not trust backend field types blindly.
- Assume that API responses may contain malformed, nullable, inconsistent, or type-shifted values.
- Never cast unstable backend fields directly using raw `as` casts unless the response contract is proven stable.
- All parsing and normalization must happen in data models/mappers only.
- Keep API-specific parsing out of UI and domain entities.
- Parse defensively for:
  - `int`
  - `double`
  - `String`
  - `bool`
  - `null`
  - `List`
  - `Map`
- If a backend field may come as multiple types, normalize it in the model layer before it reaches domain/UI.
- If backend data is malformed, fail gracefully using the project’s existing failure/error handling pattern.
- Do not leak malformed backend values directly into widgets.

---

## Error handling
- Always use the existing error handling utilities, failure models, exception mapping, and core error files already present in `core`.
- Do not swallow exceptions.
- Do not expose raw backend errors directly to the UI.
- Map errors into the project’s standard failure/result pattern.
- Keep user-facing error messages consistent with the rest of the app.
- If a backend response is invalid, handle it in the data layer and surface a safe failure state upward.

---

## Responsiveness and layout quality
- All UI changes must be responsive across common phone sizes.
- Avoid fixed widths/heights unless clearly required.
- Prefer flexible/adaptive layout patterns already used in the project.
- Check overflow risks, text wrapping, bottom sheet height behavior, and keyboard inset behavior.
- All modal, sheet, and composer flows must be checked with the keyboard open.
- Ensure action rows, reaction rows, and text blocks degrade gracefully on narrow screens.

---

## Performance and widget quality
- Prefer less expensive widgets where reasonable.
- Avoid unnecessary rebuilds.
- Extract reusable widgets when it improves readability or reduces rebuild scope.
- Use `const` constructors wherever possible.
- Avoid deeply nested widget trees when a cleaner alternative exists.
- Do not introduce heavy widgets or expensive layouts unnecessarily.
- Do not refresh a whole list or screen after every mutation if the affected item can be updated locally.
- Prefer item-level state transitions over whole-page refresh behavior for small interactions.

---

## File creation and refactoring rules
- Make minimal, focused changes.
- Do not create a new file unless:
  - it improves separation of responsibility, and
  - it matches an existing nearby project pattern or is clearly justified
- Do not move files or rename structures unless necessary for the task.
- Do not refactor unrelated areas while working on a feature task.
- If the local code is imperfect but consistent, prefer a safe consistent change over a partial architectural rewrite.

---

## Verification checklist
Before considering any task complete:
1. `flutter analyze` must pass for all changed files.
2. The actual affected user flow must be mentally traced and, where possible, verified.
3. UI changes must be checked for:
   - overflow
   - keyboard interaction
   - narrow screen behavior
   - bottom sheet/dialog layout behavior
4. Mutation flows must be checked for:
   - immediate visual update
   - correct loading/error state
   - persistence after close/reopen when applicable
5. No new inconsistent pattern should be introduced into the feature.

---

## Avoid
- Magic numbers
- Inline text styles
- Direct API calls from UI
- Business logic in widgets
- Direct token management in feature code
- New architecture inside an existing module
- Full refreshes for small local mutations when avoidable
- Raw backend type assumptions
- Unnecessary file creation
- Unnecessary refactors
- Inconsistent error handling
- Child-only local mutation state that never syncs to parent feature state

---

## Decision priority
When making implementation decisions, follow this order:
1. correctness
2. consistency with existing project patterns
3. maintainability
4. responsiveness and UX smoothness
5. performance
6. minimal code surface area

---

## Output expectations
For every task:
1. Summarize the existing pattern found in the relevant files.
2. Implement the smallest correct change.
3. Mention which files were changed.
4. Explain how the implementation follows:
   - `AppSpacing` / `AppTextStyles`
   - core error handling
   - existing clean architecture
   - responsiveness and performance expectations
5. Mention if any assumption was made due to unclear backend or product behavior.
