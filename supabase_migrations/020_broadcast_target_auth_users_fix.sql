-- ============================================================
-- Campus Online - Broadcast Targeting Reliability Fix
-- ============================================================
-- Scope:
-- 1) Ensure broadcast fan-out targets auth.users directly
-- 2) Keep one notification row per authenticated user
-- ============================================================

BEGIN;

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

COMMIT;
