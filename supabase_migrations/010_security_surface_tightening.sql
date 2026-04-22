-- ============================================================
-- Campus Online - Security Surface Tightening
-- ============================================================
-- Kapsam:
-- 1) users tablosunda direct self-delete policy'yi kaldirir
--    (hesap silme sadece delete_user RPC uzerinden ilerler)
-- 2) app-media icin broad public listing policy'yi kaldirir
-- 3) events select policy'sini anon/public ile manager okumalarini ayiracak
--    sekilde iki policy'ye boler
-- 4) role helper function execute izinlerini anon/public'dan daraltir
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) users delete policy - tek silme yolu RPC olsun
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Users can delete their own profile" ON public.users;
DROP POLICY IF EXISTS "users_delete_own" ON public.users;

-- ------------------------------------------------------------
-- B) storage objects listing - broad select policy kaldir
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "app_media_public_read" ON storage.objects;

-- ------------------------------------------------------------
-- C) events select policy ayrimi
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
-- D) helper function execute izinleri daraltma
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