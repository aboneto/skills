# Solution

## Fix
Add a null check before accessing nested address fields:

```python
@router.post("/users")
async def create_user(user: UserCreate):
    user_data = {
        "name": user.name,
        "email": user.email,
        "street": user.address.street if user.address else None,
        "city": user.address.city if user.address else None,
    }
    return {"id": 1, **user_data}
```

## Alternative: Conditional block

```python
@router.post("/users")
async def create_user(user: UserCreate):
    user_data = {
        "name": user.name,
        "email": user.email,
    }
    if user.address:
        user_data["street"] = user.address.street
        user_data["city"] = user.address.city
    return {"id": 1, **user_data}
```

## Key change
- Line 23: `user.address.street` → `user.address.street if user.address else None`
- Line 24: `user.address.city` → `user.address.city if user.address else None`

Both approaches are valid. The inline ternary is more concise; the conditional block is more explicit and easier to extend if more address fields are added later.
