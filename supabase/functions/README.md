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

## dispatch-notification-push

This function delivers notification rows to Firebase Cloud Messaging and writes
delivery attempts to `notification_push_deliveries`.

### Why this exists

The database remains the source of truth for notifications. After a row is
inserted, the trigger pipeline calls this Edge Function so users can receive a
device-level push without opening the app first.

### Deploy

```bash
supabase functions deploy dispatch-notification-push --no-verify-jwt
```

The same setting is pinned in `supabase/config.toml` with
`verify_jwt = false`. Do not remove the function's
`X-Notification-Webhook-Secret` validation; it is the real guard for the
database trigger path.

### Required secrets

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- Vault secret: `push_dispatch_secret`
- Vault secret: `firebase_service_account_json`

### Important note

If `firebase_service_account_json` is missing, notifications will still be
created in the app database but no external device push can be delivered.
