---
name: feedback-work-in-features
description: Only work in lib/features/, never lib/screens/
metadata:
  type: feedback
---

Always work exclusively in `lib/features/`. Ignore `lib/screens/` completely — do not read, edit, or reference files there.

**Why:** The project uses a feature-based structure under `lib/features/`. The `lib/screens/` folder is old/unused code.

**How to apply:** Any time the user asks to edit screens, routes, or navigation — go to `lib/features/`, never `lib/screens/`.
