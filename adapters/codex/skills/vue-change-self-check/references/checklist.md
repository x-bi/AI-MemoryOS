# Vue Change Self Check Checklist

## Common Checks

- Missing null / undefined handling.
- Field name changes without full consumer updates.
- Request parameter or response shape mismatch.
- Async branches that lost `await`, `return`, rejection handling, loading cleanup, or error handling.
- Missing loading / empty / error states after request changes.
- Shared component contract mismatches: props, emits, slots, model value, enum values.
- Page registration, route config, navigation target, permission, cache, or tab behavior regressions.
- Platform-specific branches that diverge after a shared change.
- Repeated submit, payment, or critical action without loading/debounce protection.

## Verification Paths

End with short checks tied to the diff, such as:

- open the changed page from its real entry path
- run one successful request and one error branch
- test query, reset, pagination, create/edit/close/reopen
- verify route/page registration and navigation
- verify platform-specific branches if conditional code changed
- verify repeated submit or critical action guard

## Blind Spots

State what was not verified, usually:

- runtime API response shape
- actual browser/device interaction
- unchanged dependency internals not opened
- backend-driven permission/menu data
- private overlay not available
