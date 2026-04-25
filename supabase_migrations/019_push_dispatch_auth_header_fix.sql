-- ============================================================
-- Campus Online - Push Dispatch Authorization Header Fix
-- ============================================================
-- Scope:
-- 1) Always use server-managed anon JWT from Vault for DB->Edge calls
-- 2) Avoid request apikey/header leakage from client context
-- ============================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.enqueue_notification_push_dispatch()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_project_url text;
  v_edge_key text;
  v_dispatch_secret text;
  v_auth_header text;
BEGIN
  IF NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT decrypted_secret
  INTO v_project_url
  FROM vault.decrypted_secrets
  WHERE name = 'project_url'
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT decrypted_secret
  INTO v_edge_key
  FROM vault.decrypted_secrets
  WHERE name = 'edge_function_anon_key'
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT decrypted_secret
  INTO v_dispatch_secret
  FROM vault.decrypted_secrets
  WHERE name = 'push_dispatch_secret'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_project_url IS NULL OR v_edge_key IS NULL OR v_dispatch_secret IS NULL THEN
    RETURN NEW;
  END IF;

  v_auth_header := 'Bearer ' || v_edge_key;

  PERFORM net.http_post(
    url := v_project_url || '/functions/v1/dispatch-notification-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', v_auth_header,
      'X-Notification-Webhook-Secret', v_dispatch_secret
    ),
    body := jsonb_build_object(
      'notification_id', NEW.id
    ),
    timeout_milliseconds := 10000
  );

  RETURN NEW;
END;
$$;

COMMIT;
