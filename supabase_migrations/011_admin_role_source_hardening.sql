-- ============================================================
-- Campus Online - Admin Role Source Hardening
-- ============================================================
-- Kapsam:
-- 1) is_admin fonksiyonundan user_metadata fallback'ini kaldirir
-- 2) users direct self-delete policy'sini kapatir (RPC tek yol)
-- 3) storage public listing policy'sini kaldirir
-- 4) events select policy'sini published/manager olarak ayirir
-- 5) helper function execute izinlerini authenticated ile sinirlar
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) is_admin - role source hardening
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- B) users delete policy - tek silme yolu RPC olsun
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Users can delete their own profile" ON public.users;
DROP POLICY IF EXISTS "users_delete_own" ON public.users;

-- ------------------------------------------------------------
-- C) storage objects listing - broad select policy kaldir
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "app_media_public_read" ON storage.objects;

-- ------------------------------------------------------------
-- D) events select policy ayrimi
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "events_select_published_or_manager" ON public.events;
DROP POLICY IF EXISTS "events_select_published_all" ON public.events;
DROP POLICY IF EXISTS "events_select_manager_only" ON public.events;

CREATE POLICY "events_select_published_all"
  ON public.events
  FOR SELECT
  USING (is_published = true);

CREATE POLICY "events_select_manager_only"
  ON public.events
  FOR SELECT
  TO authenticated
  USING (public.can_manage_events((select auth.uid())));

-- ------------------------------------------------------------
-- E) helper function execute izinleri daraltma
-- ------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.is_admin(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.is_admin(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.can_manage_events(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.can_manage_events(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.can_manage_events(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.can_manage_venue(uuid, uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.can_manage_venue(uuid, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.can_manage_venue(uuid, uuid) TO authenticated;

COMMIT;