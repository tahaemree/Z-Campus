-- ============================================================
-- Campus Online - Push Dispatch Secret-Only Invocation
-- ============================================================
-- Scope:
-- 1) Remove client API key/JWT dependency from DB -> Edge dispatch
-- 2) Keep dispatch protected by the Vault-backed webhook secret
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
  v_dispatch_secret text;
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
  INTO v_dispatch_secret
  FROM vault.decrypted_secrets
  WHERE name = 'push_dispatch_secret'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_project_url IS NULL OR v_dispatch_secret IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := v_project_url || '/functions/v1/dispatch-notification-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
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

REVOKE ALL ON FUNCTION public.enqueue_notification_push_dispatch() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enqueue_notification_push_dispatch() FROM anon;
REVOKE ALL ON FUNCTION public.enqueue_notification_push_dispatch() FROM authenticated;

COMMIT;
