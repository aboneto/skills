# Bug Analysis: TypeError in FastAPI /users endpoint

## Error
`TypeError: 'NoneType' object is not subscriptable` (HTTP 500)

## Root Cause
In `src/api/routes/users.py`, lines 23-24:

```python
"street": user.address.street,
"city": user.address.city,
```

The code directly accesses `user.address.street` and `user.address.city` without checking if `user.address` is `None`.

The `UserCreate` model (line 15) defines `address` as:
```python
address: Optional[Address] = None
```

This means `address` can legitimately be `None` when:
1. The payload omits the `address` field entirely
2. The payload sends `"address": null`

In either case, `user.address` evaluates to `None`, and attempting attribute access (`None.street`) raises `TypeError`.

## Why Pydantic didn't catch it
Pydantic validates that the incoming JSON matches the schema. Since `address` is `Optional` with a default of `None`, Pydantic correctly accepts payloads without an address. The error is not a validation issue — it's a **runtime logic error** in the handler body after validation succeeds.

## Why reinstalling dependencies didn't help
This is not a dependency or environment issue. It's a code logic bug.
