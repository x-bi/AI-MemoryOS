# Vue Change Self Check Checklist

## Common Checks

- Missing null or undefined handling.
- Field name changes without full consumer updates.
- Request parameter or response shape mismatch.
- Async branches that lost `await`, `return`, rejection handling, loading cleanup, or error handling.
- Missing loading, empty, or error states after request changes.
- Shared component contract mismatches: props, emits, slots, model value, enum values.
- Page registration, route config, navigation target, permission, cache, or tab behavior regressions.
- Platform-specific branches that diverge after a shared change.
- Repeated submit, payment, or critical action without loading or debounce protection.

## Verification Paths

End with short checks tied to the diff, such as:

- Open the changed page from its real entry path.
- Run one successful request and one error branch.
- Test query, reset, pagination, create/edit/close/reopen.
- Verify route/page registration and navigation.
- Verify platform-specific branches if conditional code changed.
- Verify repeated submit or critical action guard.

## Blind Spots

State what was not verified, usually:

- Runtime API response shape.
- Actual browser/device interaction.
- Unchanged dependency internals not opened.
- Backend-driven permission/menu data.
- Private overlay not available.
