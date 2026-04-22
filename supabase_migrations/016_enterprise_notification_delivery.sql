-- ============================================================
-- Campus Online - Enterprise Notification Delivery Pipeline
-- ============================================================
-- Scope:
-- 1) Per-user broadcast notification fan-out RPC
-- 2) Push delivery audit table
-- 3) Internal secret helper functions for Edge Functions
-- 4) DB trigger -> Edge Function dispatch via pg_net
-- ============================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_net;

DO $$
DECLARE
  v_secret_id uuid;
BEGIN
  SELECT id
  INTO v_secret_id
  FROM vault.decrypted_secrets
  WHERE name = 'project_url'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_secret_id IS NULL THEN
    PERFORM vault.create_secret(
      'YOUR_SUPABASE_URL',
      'project_url',
      'Campus Online Supabase project URL'
    );
  ELSE
    PERFORM vault.update_secret(
      v_secret_id,
      'YOUR_SUPABASE_URL',
      'project_url',
      'Campus Online Supabase project URL'
    );
  END IF;
END;
$$;

DO $$
DECLARE
  v_secret_id uuid;
BEGIN
  SELECT id
  INTO v_secret_id
  FROM vault.decrypted_secrets
  WHERE name = 'edge_function_anon_key'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_secret_id IS NULL THEN
    PERFORM vault.create_secret(
      'YOUR_SUPABASE_ANON_KEY',
      'edge_function_anon_key',
      'Campus Online internal Edge Function invoke key'
    );
  ELSE
    PERFORM vault.update_secret(
      v_secret_id,
      'YOUR_SUPABASE_ANON_KEY',
      'edge_function_anon_key',
      'Campus Online internal Edge Function invoke key'
    );
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM vault.decrypted_secrets
    WHERE name = 'push_dispatch_secret'
  ) THEN
    PERFORM vault.create_secret(
      encode(gen_random_bytes(32), 'hex'),
      'push_dispatch_secret',
      'Campus Online internal push dispatch secret'
    );
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.notification_push_deliveries (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  notification_id uuid NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  push_token_id uuid REFERENCES public.user_push_tokens(id) ON DELETE SET NULL,
  platform text,
  provider text NOT NULL DEFAULT 'fcm',
  status text NOT NULL
    CHECK (status IN ('sent', 'failed', 'skipped')),
  provider_message_id text,
  response_status integer,
  response_body jsonb,
  error_message text,
  attempted_at timestamptz NOT NULL DEFAULT now(),
  delivered_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_notification_push_deliveries_notification_attempted
  ON public.notification_push_deliveries (notification_id, attempted_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_push_deliveries_user_attempted
  ON public.notification_push_deliveries (user_id, attempted_at DESC);

ALTER TABLE public.notification_push_deliveries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notification_push_deliveries_select_admin_only"
  ON public.notification_push_deliveries;
CREATE POLICY "notification_push_deliveries_select_admin_only"
  ON public.notification_push_deliveries
  FOR SELECT
  TO authenticated
  USING (public.is_admin((SELECT auth.uid() AS uid)));

GRANT SELECT ON public.notification_push_deliveries TO authenticated;
GRANT INSERT, UPDATE ON public.notification_push_deliveries TO service_role;

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
    u.id,
    v_title,
    v_body,
    'admin_broadcast',
    v_actor_id
  FROM public.users u;

  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;
  RETURN v_inserted_count;
END;
$$;

REVOKE ALL ON FUNCTION public.send_broadcast_notification(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.send_broadcast_notification(text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.send_broadcast_notification(text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_push_dispatch_secret()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT decrypted_secret
  FROM vault.decrypted_secrets
  WHERE name = 'push_dispatch_secret'
  ORDER BY created_at DESC
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_fcm_service_account_json()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT decrypted_secret
  FROM vault.decrypted_secrets
  WHERE name = 'firebase_service_account_json'
  ORDER BY created_at DESC
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_notification_push_job(
  p_notification_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payload jsonb;
BEGIN
  SELECT jsonb_build_object(
           'notification',
           to_jsonb(n),
           'tokens',
           COALESCE(
             (
               SELECT jsonb_agg(
                 jsonb_build_object(
                   'id', t.id,
                   'token', t.token,
                   'platform', t.platform,
                   'device_locale', t.device_locale,
                   'last_seen_at', t.last_seen_at
                 )
                 ORDER BY t.last_seen_at DESC
               )
               FROM public.user_push_tokens t
               WHERE t.user_id = n.user_id
                 AND t.is_active = true
             ),
             '[]'::jsonb
           )
         )
  INTO v_payload
  FROM public.notifications n
  WHERE n.id = p_notification_id;

  RETURN v_payload;
END;
$$;

REVOKE ALL ON FUNCTION public.get_push_dispatch_secret() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_push_dispatch_secret() FROM anon;
REVOKE ALL ON FUNCTION public.get_push_dispatch_secret() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.get_push_dispatch_secret() TO service_role;

REVOKE ALL ON FUNCTION public.get_fcm_service_account_json() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_fcm_service_account_json() FROM anon;
REVOKE ALL ON FUNCTION public.get_fcm_service_account_json() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.get_fcm_service_account_json() TO service_role;

REVOKE ALL ON FUNCTION public.get_notification_push_job(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_notification_push_job(uuid) FROM anon;
REVOKE ALL ON FUNCTION public.get_notification_push_job(uuid) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.get_notification_push_job(uuid) TO service_role;

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
  v_headers_raw text := current_setting('request.headers', true);
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

  IF v_headers_raw IS NOT NULL THEN
    v_auth_header := COALESCE(
      v_headers_raw::json ->> 'authorization',
      CASE
        WHEN (v_headers_raw::json ->> 'apikey') IS NOT NULL
          THEN 'Bearer ' || (v_headers_raw::json ->> 'apikey')
        ELSE NULL
      END
    );
  END IF;

  IF v_auth_header IS NULL AND v_edge_key IS NOT NULL THEN
    v_auth_header := 'Bearer ' || v_edge_key;
  END IF;

  IF v_project_url IS NULL OR v_auth_header IS NULL OR v_dispatch_secret IS NULL THEN
    RETURN NEW;
  END IF;

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

DROP TRIGGER IF EXISTS trg_enqueue_notification_push_dispatch ON public.notifications;
CREATE TRIGGER trg_enqueue_notification_push_dispatch
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.enqueue_notification_push_dispatch();

COMMIT;
