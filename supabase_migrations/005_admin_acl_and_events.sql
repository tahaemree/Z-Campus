-- ============================================================
-- Campus Online - Admin ACL + Events Module
-- ============================================================
-- Kapsam:
-- 1) Rol tablosu (admin / sks)
-- 2) Venue bazli duzenleme yetkisi
-- 3) Etkinlikler tablosu ve RLS
-- 4) Admin konsolu icin users tablosuna yonetsel policy
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) Tablolar
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('admin', 'sks')),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles (user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles (role);

CREATE TABLE IF NOT EXISTS public.user_venue_permissions (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  venue_id uuid NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, venue_id)
);

CREATE INDEX IF NOT EXISTS idx_uvp_user_id ON public.user_venue_permissions (user_id);
CREATE INDEX IF NOT EXISTS idx_uvp_venue_id ON public.user_venue_permissions (venue_id);

CREATE TABLE IF NOT EXISTS public.events (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  title text NOT NULL,
  description text,
  location text,
  image_url text,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  is_published boolean NOT NULL DEFAULT true,
  created_by uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE RESTRICT,
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_at >= start_at)
);

CREATE INDEX IF NOT EXISTS idx_events_start_at ON public.events (start_at);
CREATE INDEX IF NOT EXISTS idx_events_published_start ON public.events (is_published, start_at DESC);

-- ------------------------------------------------------------
-- B) Yardimci fonksiyonlar
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.has_role(p_user_id uuid, p_role text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p_user_id IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.user_roles ur
      WHERE ur.user_id = p_user_id
        AND ur.role = p_role
    );
$$;

CREATE OR REPLACE FUNCTION public.is_admin(p_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p_user_id IS NOT NULL
    AND (
      ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
      OR public.has_role(p_user_id, 'admin')
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_events(p_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p_user_id IS NOT NULL
    AND (
      public.is_admin(p_user_id)
      OR public.has_role(p_user_id, 'sks')
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_venue(
  p_user_id uuid DEFAULT auth.uid(),
  p_venue_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p_user_id IS NOT NULL
    AND (
      public.is_admin(p_user_id)
      OR EXISTS (
        SELECT 1
        FROM public.user_venue_permissions uvp
        WHERE uvp.user_id = p_user_id
          AND uvp.venue_id = p_venue_id
      )
    );
$$;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, text) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.can_manage_events(uuid) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.can_manage_venue(uuid, uuid) TO authenticated, anon;

-- ------------------------------------------------------------
-- C) Trigger - events updated_at / updated_by
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_events_updated_at()
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

DROP TRIGGER IF EXISTS set_events_updated_at ON public.events;
CREATE TRIGGER set_events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_events_updated_at();

-- ------------------------------------------------------------
-- D) RLS ac
-- ------------------------------------------------------------
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_venue_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- E) Users tablosu - admin konsolu icin policy
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "users_admin_console_select" ON public.users;
CREATE POLICY "users_admin_console_select"
  ON public.users
  FOR SELECT
  USING (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "users_admin_console_insert" ON public.users;
CREATE POLICY "users_admin_console_insert"
  ON public.users
  FOR INSERT
  WITH CHECK (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "users_admin_console_update" ON public.users;
CREATE POLICY "users_admin_console_update"
  ON public.users
  FOR UPDATE
  USING (public.is_admin((select auth.uid())))
  WITH CHECK (public.is_admin((select auth.uid())));

-- ------------------------------------------------------------
-- F) user_roles policies
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "user_roles_select_self_or_admin" ON public.user_roles;
CREATE POLICY "user_roles_select_self_or_admin"
  ON public.user_roles
  FOR SELECT
  USING (
    (select auth.uid()) = user_id
    OR public.is_admin((select auth.uid()))
  );

DROP POLICY IF EXISTS "user_roles_insert_admin_only" ON public.user_roles;
CREATE POLICY "user_roles_insert_admin_only"
  ON public.user_roles
  FOR INSERT
  WITH CHECK (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "user_roles_update_admin_only" ON public.user_roles;
CREATE POLICY "user_roles_update_admin_only"
  ON public.user_roles
  FOR UPDATE
  USING (public.is_admin((select auth.uid())))
  WITH CHECK (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "user_roles_delete_admin_only" ON public.user_roles;
CREATE POLICY "user_roles_delete_admin_only"
  ON public.user_roles
  FOR DELETE
  USING (public.is_admin((select auth.uid())));

-- ------------------------------------------------------------
-- G) user_venue_permissions policies
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "user_venue_permissions_select_self_or_admin" ON public.user_venue_permissions;
CREATE POLICY "user_venue_permissions_select_self_or_admin"
  ON public.user_venue_permissions
  FOR SELECT
  USING (
    (select auth.uid()) = user_id
    OR public.is_admin((select auth.uid()))
  );

DROP POLICY IF EXISTS "user_venue_permissions_insert_admin_only" ON public.user_venue_permissions;
CREATE POLICY "user_venue_permissions_insert_admin_only"
  ON public.user_venue_permissions
  FOR INSERT
  WITH CHECK (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "user_venue_permissions_update_admin_only" ON public.user_venue_permissions;
CREATE POLICY "user_venue_permissions_update_admin_only"
  ON public.user_venue_permissions
  FOR UPDATE
  USING (public.is_admin((select auth.uid())))
  WITH CHECK (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "user_venue_permissions_delete_admin_only" ON public.user_venue_permissions;
CREATE POLICY "user_venue_permissions_delete_admin_only"
  ON public.user_venue_permissions
  FOR DELETE
  USING (public.is_admin((select auth.uid())));

-- ------------------------------------------------------------
-- H) venues policy - venue bazli duzenleme
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "venues_insert_admin_only" ON public.venues;
CREATE POLICY "venues_insert_admin_only"
  ON public.venues
  FOR INSERT
  WITH CHECK (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "venues_update_admin_only" ON public.venues;
CREATE POLICY "venues_update_admin_only"
  ON public.venues
  FOR UPDATE
  USING (public.can_manage_venue((select auth.uid()), id))
  WITH CHECK (public.can_manage_venue((select auth.uid()), id));

DROP POLICY IF EXISTS "venues_delete_admin_only" ON public.venues;
CREATE POLICY "venues_delete_admin_only"
  ON public.venues
  FOR DELETE
  USING (public.is_admin((select auth.uid())));

-- ------------------------------------------------------------
-- I) events policies
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "events_select_published_or_manager" ON public.events;
CREATE POLICY "events_select_published_or_manager"
  ON public.events
  FOR SELECT
  USING (
    is_published = true
    OR public.can_manage_events((select auth.uid()))
  );

DROP POLICY IF EXISTS "events_insert_manager_only" ON public.events;
CREATE POLICY "events_insert_manager_only"
  ON public.events
  FOR INSERT
  WITH CHECK (public.can_manage_events((select auth.uid())));

DROP POLICY IF EXISTS "events_update_manager_only" ON public.events;
CREATE POLICY "events_update_manager_only"
  ON public.events
  FOR UPDATE
  USING (public.can_manage_events((select auth.uid())))
  WITH CHECK (public.can_manage_events((select auth.uid())));

DROP POLICY IF EXISTS "events_delete_manager_only" ON public.events;
CREATE POLICY "events_delete_manager_only"
  ON public.events
  FOR DELETE
  USING (public.can_manage_events((select auth.uid())));

-- ------------------------------------------------------------
-- J) Permission grantleri
-- ------------------------------------------------------------
GRANT SELECT ON public.user_roles TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.user_roles TO authenticated;

GRANT SELECT ON public.user_venue_permissions TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.user_venue_permissions TO authenticated;

GRANT SELECT ON public.events TO authenticated, anon;
GRANT INSERT, UPDATE, DELETE ON public.events TO authenticated;

COMMIT;
