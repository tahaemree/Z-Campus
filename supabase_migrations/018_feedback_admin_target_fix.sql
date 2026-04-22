-- ============================================================
-- Campus Online - Feedback Admin Target Fix
-- ============================================================
-- Scope:
-- 1) Ensure feedback notifications target all effective admins
--    from app_metadata and user_roles
-- ============================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.notify_admin_on_feedback()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_category_label text;
  v_admin_row record;
BEGIN
  CASE NEW.category
    WHEN 'general' THEN v_category_label := 'Genel Geri Bildirim';
    WHEN 'suggestion' THEN v_category_label := 'Öneri';
    WHEN 'recommendation' THEN v_category_label := 'Tavsiye';
    WHEN 'bug_report' THEN v_category_label := 'Hata Bildirimi';
    ELSE v_category_label := 'Geri Bildirim';
  END CASE;

  FOR v_admin_row IN
    SELECT DISTINCT admin_users.user_id
    FROM (
      SELECT au.id AS user_id
      FROM auth.users au
      WHERE au.raw_app_meta_data ->> 'role' = 'admin'

      UNION

      SELECT ur.user_id
      FROM public.user_roles ur
      WHERE ur.role = 'admin'
    ) AS admin_users
  LOOP
    INSERT INTO public.notifications (
      user_id,
      title,
      body,
      type,
      target_id,
      created_by
    ) VALUES (
      v_admin_row.user_id,
      v_category_label || ': ' || left(NEW.subject, 80),
      left(NEW.message, 200),
      'feedback',
      NEW.id::text,
      NEW.user_id
    );
  END LOOP;

  RETURN NEW;
END;
$$;

COMMIT;
