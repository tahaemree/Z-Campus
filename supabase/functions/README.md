# Supabase Edge Functions

## create-staff-account

This function securely provisions staff accounts using the service role key.

### Why this exists

Client-side account creation with anon credentials is not safe for admin workflows.
This function verifies that the caller is an admin and then creates the target user,
profile row, role records, and venue permissions atomically.

### Deploy

```bash
supabase functions deploy create-staff-account
```

### Required secrets

- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY

### Request payload

```json
{
  "email": "staff@example.com",
  "password": "temp-password",
  "display_name": "Staff User",
  "roles": ["sks"],
  "editable_venue_ids": ["<venue-uuid>"]
}
```

### Success response

```json
{
  "user_id": "<auth-user-uuid>"
}
```
