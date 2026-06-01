-- ============================================================
-- Campus Online - Notification Read RPC + Explore Schedule Hardening
-- ============================================================
-- Purpose:
-- 1) Restore the notification read RPCs expected by the Flutter client.
-- 2) Keep notification updates/deletes behind narrow RPC functions.
-- 3) Remove direct API execute grants from trigger-only helper functions.
-- 4) Keep paid Explore contribution schedule columns indexed for active feed.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) Notification read mutations.
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "notifications_select_own_or_admin"
  ON public.notifications;
DROP POLICY IF EXISTS "notifications_select_own_or_broadcast"
  ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own_or_admin"
  ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_own_or_admin"
  ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own_read"
  ON public.notifications;

CREATE POLICY "notifications_select_own_or_broadcast"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid())
    OR public.is_admin((select auth.uid()))
    OR (
      user_id IS NULL
      AND type = 'admin_broadcast'
      AND NOT EXISTS (
        SELECT 1
        FROM public.notification_dismissals nd
        WHERE nd.notification_id = notifications.id
          AND nd.user_id = (select auth.uid())
      )
    )
  );

REVOKE UPDATE ON public.notifications FROM authenticated;
REVOKE DELETE ON public.notifications FROM authenticated;
GRANT SELECT, INSERT ON public.notifications TO authenticated;

CREATE OR REPLACE FUNCTION public.mark_notification_read(
  p_notification_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_updated integer := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  UPDATE public.notifications
  SET is_read = true,
      updated_at = now()
  WHERE id = p_notification_id
    AND user_id = v_user_id
    AND is_read = false;

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  IF v_updated > 0 THEN
    RETURN true;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.notifications n
    WHERE n.id = p_notification_id
      AND n.user_id = v_user_id
      AND n.is_read = true
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_updated integer := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  UPDATE public.notifications
  SET is_read = true,
      updated_at = now()
  WHERE user_id = v_user_id
    AND is_read = false;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_notification_read(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_notification_read(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.mark_notification_read(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.mark_all_notifications_read() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_all_notifications_read() FROM anon;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read() TO authenticated;

-- ------------------------------------------------------------
-- B) Trigger-only helper functions must not be callable via Data API.
-- ------------------------------------------------------------
REVOKE ALL ON FUNCTION public.enqueue_notification_push_dispatch() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enqueue_notification_push_dispatch() FROM anon;
REVOKE ALL ON FUNCTION public.enqueue_notification_push_dispatch()
  FROM authenticated;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM anon;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM authenticated;

REVOKE ALL ON FUNCTION public.handle_updated_at() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_updated_at() FROM anon;
REVOKE ALL ON FUNCTION public.handle_updated_at() FROM authenticated;

REVOKE ALL ON FUNCTION public.notify_admin_on_feedback() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.notify_admin_on_feedback() FROM anon;
REVOKE ALL ON FUNCTION public.notify_admin_on_feedback() FROM authenticated;

REVOKE ALL ON FUNCTION public.set_explore_updated_fields() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_explore_updated_fields() FROM anon;
REVOKE ALL ON FUNCTION public.set_explore_updated_fields() FROM authenticated;

-- ------------------------------------------------------------
-- C) Explore paid placement schedule support.
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_explore_contributions_active_schedule_order
  ON public.explore_contributions (
    display_order,
    starts_at,
    ends_at,
    created_at DESC
  )
  WHERE is_active = true;

COMMIT;
