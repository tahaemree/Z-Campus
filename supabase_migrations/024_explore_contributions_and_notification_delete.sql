-- ============================================================
-- Campus Online - Explore Contributions + Notification Delete Repair
-- ============================================================
-- Purpose:
-- 1) Make user notification deletion deterministic and verifiable.
-- 2) Support per-user dismissal for legacy/global broadcast rows.
-- 3) Add admin-managed Explore contributions for venues and events.
-- 4) Add admin-managed Explore section settings.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) Per-user notification dismissals for legacy/global broadcasts.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notification_dismissals (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  notification_id uuid NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dismissed_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, notification_id)
);

CREATE INDEX IF NOT EXISTS idx_notification_dismissals_notification_id
  ON public.notification_dismissals (notification_id);

CREATE INDEX IF NOT EXISTS idx_notification_dismissals_user_dismissed
  ON public.notification_dismissals (user_id, dismissed_at DESC);

ALTER TABLE public.notification_dismissals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notification_dismissals_select_own"
  ON public.notification_dismissals;
CREATE POLICY "notification_dismissals_select_own"
  ON public.notification_dismissals
  FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "notification_dismissals_insert_own"
  ON public.notification_dismissals;
CREATE POLICY "notification_dismissals_insert_own"
  ON public.notification_dismissals
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "notification_dismissals_delete_own"
  ON public.notification_dismissals;
CREATE POLICY "notification_dismissals_delete_own"
  ON public.notification_dismissals
  FOR DELETE
  TO authenticated
  USING (user_id = (select auth.uid()));

GRANT SELECT, INSERT, DELETE ON public.notification_dismissals TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_dismissals TO service_role;

DROP POLICY IF EXISTS "notifications_select_own_or_broadcast"
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

CREATE OR REPLACE FUNCTION public.delete_notification(
  p_notification_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_deleted integer;
  v_is_global_broadcast boolean := false;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  DELETE FROM public.notifications
  WHERE id = p_notification_id
    AND user_id = v_user_id
  RETURNING 1 INTO v_deleted;

  IF v_deleted = 1 THEN
    RETURN true;
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.notifications n
    WHERE n.id = p_notification_id
      AND n.user_id IS NULL
      AND n.type = 'admin_broadcast'
  )
  INTO v_is_global_broadcast;

  IF v_is_global_broadcast THEN
    INSERT INTO public.notification_dismissals (
      notification_id,
      user_id,
      dismissed_at
    ) VALUES (
      p_notification_id,
      v_user_id,
      now()
    )
    ON CONFLICT (user_id, notification_id)
    DO UPDATE SET dismissed_at = EXCLUDED.dismissed_at;

    RETURN true;
  END IF;

  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_notification(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_notification(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_notification(uuid) TO authenticated;

-- ------------------------------------------------------------
-- B) Explore section settings.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.explore_settings (
  id boolean PRIMARY KEY DEFAULT true CHECK (id),
  show_contributions boolean NOT NULL DEFAULT true,
  show_recent_views boolean NOT NULL DEFAULT true,
  contributions_title text NOT NULL DEFAULT 'Katkıda Bulunanlar'
    CHECK (char_length(btrim(contributions_title)) BETWEEN 1 AND 80),
  recent_views_title text NOT NULL DEFAULT 'Son Göz Atılan Yerler'
    CHECK (char_length(btrim(recent_views_title)) BETWEEN 1 AND 80),
  contributions_limit integer NOT NULL DEFAULT 10
    CHECK (contributions_limit BETWEEN 1 AND 50),
  recent_views_limit integer NOT NULL DEFAULT 10
    CHECK (recent_views_limit BETWEEN 1 AND 50),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.explore_settings (id)
VALUES (true)
ON CONFLICT (id) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_explore_settings_updated_by
  ON public.explore_settings (updated_by)
  WHERE updated_by IS NOT NULL;

ALTER TABLE public.explore_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "explore_settings_select_all" ON public.explore_settings;
CREATE POLICY "explore_settings_select_all"
  ON public.explore_settings
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "explore_settings_admin_insert"
  ON public.explore_settings;
CREATE POLICY "explore_settings_admin_insert"
  ON public.explore_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (id = true AND public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "explore_settings_admin_update"
  ON public.explore_settings;
CREATE POLICY "explore_settings_admin_update"
  ON public.explore_settings
  FOR UPDATE
  TO authenticated
  USING (public.is_admin((select auth.uid())))
  WITH CHECK (id = true AND public.is_admin((select auth.uid())));

GRANT SELECT ON public.explore_settings TO anon, authenticated;
GRANT INSERT, UPDATE ON public.explore_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.explore_settings TO service_role;

-- ------------------------------------------------------------
-- C) Admin-managed Explore contributions.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.explore_contributions (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  item_type text NOT NULL CHECK (item_type IN ('venue', 'event')),
  venue_id uuid REFERENCES public.venues(id) ON DELETE CASCADE,
  event_id uuid REFERENCES public.events(id) ON DELETE CASCADE,
  label text,
  display_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by uuid DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (
    (
      item_type = 'venue'
      AND venue_id IS NOT NULL
      AND event_id IS NULL
    )
    OR (
      item_type = 'event'
      AND event_id IS NOT NULL
      AND venue_id IS NULL
    )
  ),
  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at >= starts_at),
  CHECK (label IS NULL OR char_length(btrim(label)) BETWEEN 1 AND 80)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_explore_contributions_venue
  ON public.explore_contributions (venue_id)
  WHERE venue_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_explore_contributions_event
  ON public.explore_contributions (event_id)
  WHERE event_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_explore_contributions_active_order
  ON public.explore_contributions (display_order, created_at DESC)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_explore_contributions_event_id
  ON public.explore_contributions (event_id)
  WHERE event_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_explore_contributions_created_by
  ON public.explore_contributions (created_by)
  WHERE created_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_explore_contributions_updated_by
  ON public.explore_contributions (updated_by)
  WHERE updated_by IS NOT NULL;

ALTER TABLE public.explore_contributions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "explore_contributions_select_visible_or_admin"
  ON public.explore_contributions;
CREATE POLICY "explore_contributions_select_visible_or_admin"
  ON public.explore_contributions
  FOR SELECT
  TO anon, authenticated
  USING (
    public.is_admin((select auth.uid()))
    OR (
      is_active = true
      AND (starts_at IS NULL OR starts_at <= now())
      AND (ends_at IS NULL OR ends_at >= now())
    )
  );

DROP POLICY IF EXISTS "explore_contributions_admin_insert"
  ON public.explore_contributions;
CREATE POLICY "explore_contributions_admin_insert"
  ON public.explore_contributions
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "explore_contributions_admin_update"
  ON public.explore_contributions;
CREATE POLICY "explore_contributions_admin_update"
  ON public.explore_contributions
  FOR UPDATE
  TO authenticated
  USING (public.is_admin((select auth.uid())))
  WITH CHECK (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "explore_contributions_admin_delete"
  ON public.explore_contributions;
CREATE POLICY "explore_contributions_admin_delete"
  ON public.explore_contributions
  FOR DELETE
  TO authenticated
  USING (public.is_admin((select auth.uid())));

GRANT SELECT ON public.explore_contributions TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.explore_contributions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.explore_contributions TO service_role;

CREATE OR REPLACE FUNCTION public.set_explore_updated_fields()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_explore_settings_updated_at
  ON public.explore_settings;
CREATE TRIGGER set_explore_settings_updated_at
  BEFORE UPDATE ON public.explore_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.set_explore_updated_fields();

DROP TRIGGER IF EXISTS set_explore_contributions_updated_at
  ON public.explore_contributions;
CREATE TRIGGER set_explore_contributions_updated_at
  BEFORE UPDATE ON public.explore_contributions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_explore_updated_fields();

COMMIT;
