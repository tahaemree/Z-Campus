-- ============================================================
-- Campus Online - Notification Pipeline Reliability Repair
-- ============================================================
-- Scope:
-- 1) Re-assert DB -> Edge dispatch auth header strategy
-- 2) Re-assert broadcast fan-out target as auth.users
-- 3) Add optional supporting indexes for delivery observability
-- ============================================================

BEGIN;

CREATE INDEX IF NOT EXISTS idx_notification_push_deliveries_push_token_id
  ON public.notification_push_deliveries (push_token_id)
  WHERE push_token_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_created_by
  ON public.notifications (created_by)
  WHERE created_by IS NOT NULL;

CREATE OR REPLACE FUNCTION public.send_broadcast_notification(
  p_title text,
  p_body text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_id uuid := auth.uid();
  v_title text := btrim(coalesce(p_title, ''));
  v_body text := btrim(coalesce(p_body, ''));
  v_inserted_count integer := 0;
BEGIN
  IF v_actor_id IS NULL OR NOT public.is_admin(v_actor_id) THEN
    RAISE EXCEPTION 'Admin privileges required'
      USING ERRCODE = '42501';
  END IF;

  IF char_length(v_title) < 2 OR char_length(v_title) > 200 THEN
    RAISE EXCEPTION 'Notification title must be between 2 and 200 characters'
      USING ERRCODE = '22023';
  END IF;

  IF char_length(v_body) < 5 OR char_length(v_body) > 2000 THEN
    RAISE EXCEPTION 'Notification body must be between 5 and 2000 characters'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.notifications (
    user_id,
    title,
    body,
    type,
    created_by
  )
  SELECT
    au.id,
    v_title,
    v_body,
    'admin_broadcast',
    v_actor_id
  FROM auth.users au;

  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;
  RETURN v_inserted_count;
END;
$$;

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

  PERFORM net.http_post(
    url := v_project_url || '/functions/v1/dispatch-notification-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_edge_key,
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
