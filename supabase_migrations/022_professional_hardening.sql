-- ============================================================
-- Campus Online - Professional Hardening
-- ============================================================
-- Purpose:
-- 1) Move user notification mutations behind narrow RPC functions
-- 2) Make account deletion work for users who created events
-- 3) Keep the latest notification delivery indexes in the documented chain
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) Event author FK should not block account deletion.
-- ------------------------------------------------------------
ALTER TABLE public.events
  ALTER COLUMN created_by DROP NOT NULL;

ALTER TABLE public.events
  DROP CONSTRAINT IF EXISTS events_created_by_fkey;

ALTER TABLE public.events
  ADD CONSTRAINT events_created_by_fkey
  FOREIGN KEY (created_by)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

-- ------------------------------------------------------------
-- B) Narrow notification mutations to RPCs.
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "notifications_update_own_read" ON public.notifications;

REVOKE UPDATE ON public.notifications FROM authenticated;
REVOKE DELETE ON public.notifications FROM authenticated;
GRANT SELECT, INSERT ON public.notifications TO authenticated;

CREATE OR REPLACE FUNCTION public.mark_notification_read(
  p_notification_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  UPDATE public.notifications
  SET is_read = true,
      updated_at = now()
  WHERE id = p_notification_id
    AND user_id = v_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  UPDATE public.notifications
  SET is_read = true,
      updated_at = now()
  WHERE user_id = v_user_id
    AND is_read = false;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_notification(
  p_notification_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  DELETE FROM public.notifications
  WHERE id = p_notification_id
    AND user_id = v_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_notification_read(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_notification_read(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.mark_notification_read(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.mark_all_notifications_read() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_all_notifications_read() FROM anon;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read() TO authenticated;

REVOKE ALL ON FUNCTION public.delete_notification(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_notification(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_notification(uuid) TO authenticated;

-- ------------------------------------------------------------
-- C) Keep account deletion explicit and complete.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  DELETE FROM public.event_favorites WHERE user_id = v_user_id;
  DELETE FROM public.user_favorites WHERE user_id = v_user_id;
  DELETE FROM public.user_recent_views WHERE user_id = v_user_id;
  DELETE FROM public.user_recent_searches WHERE user_id = v_user_id;
  DELETE FROM public.user_push_tokens WHERE user_id = v_user_id;
  DELETE FROM public.notifications WHERE user_id = v_user_id;
  UPDATE public.notifications SET created_by = NULL WHERE created_by = v_user_id;
  UPDATE public.user_feedback SET user_id = NULL WHERE user_id = v_user_id;

  DELETE FROM public.users WHERE id = v_user_id;
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_user() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_user() FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;

-- ------------------------------------------------------------
-- D) Idempotently retain observability indexes.
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_notification_push_deliveries_push_token_id
  ON public.notification_push_deliveries (push_token_id)
  WHERE push_token_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_created_by
  ON public.notifications (created_by)
  WHERE created_by IS NOT NULL;

COMMIT;
