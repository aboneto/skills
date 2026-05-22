# Summary & Decision

## Bug Found
- **Location:** `src/api/routes/users.py:23-24`
- **Root cause:** `user.address` is `Optional[Address] = None`, but lines 23-24 access `user.address.street` and `user.address.city` without checking if `address` is `None` first. When the client sends `"address": null`, `user.address` becomes `None`, and `None.street` raises `TypeError: 'NoneType' object is not subscriptable`.

## Claude's Response
Confirmed the bug at line 23 (`user.address.street`). Proposed two approaches:
1. **Guard with conditional:** Use `user.address.street if user.address else None` for each field.
2. **Make address required:** Remove `Optional` from the schema so Pydantic returns 422 instead of 500.

## Decision
Both approaches are valid. The choice depends on business logic:
- If `address` is truly optional → use guard conditionals (approach 1).
- If `address` should always be provided → remove `Optional` from the model (approach 2), which is cleaner and gives proper 422 validation errors.

**Recommendation:** Approach 2 (make `address` required) unless there's a legitimate use case for users without addresses. This prevents silent `None` values downstream and gives clients clear validation feedback.

## Skill Assessment
The consult-claude skill worked well for this scenario. The bug was straightforward but the user was stuck for 2 hours — likely due to tunnel vision on Pydantic validation rather than the runtime code. A fresh perspective immediately identified the issue.
