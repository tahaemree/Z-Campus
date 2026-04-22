-- ============================================================
-- Campus Online - Security & Performance Hardening
-- ============================================================
-- Bu migration, mevcut semayi degistirmeden guvenlik ve performans
-- iyilestirmeleri uygular:
-- 1) Yetki modeli: venues admin policy -> app_metadata.role
-- 2) SECURITY DEFINER function execute izinlerinin daraltilmasi
-- 3) RLS expression initplan optimizasyonu
-- 4) Eksik FK indekslerinin eklenmesi
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) venues admin policy uyumu (app_metadata.role)
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "venues_insert_admin_only" ON public.venues;
CREATE POLICY "venues_insert_admin_only"
  ON public.venues
  FOR INSERT
  WITH CHECK (
    (select auth.uid()) IS NOT NULL
    AND ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
  );

DROP POLICY IF EXISTS "venues_update_admin_only" ON public.venues;
CREATE POLICY "venues_update_admin_only"
  ON public.venues
  FOR UPDATE
  USING (
    (select auth.uid()) IS NOT NULL
    AND ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
  );

DROP POLICY IF EXISTS "venues_delete_admin_only" ON public.venues;
CREATE POLICY "venues_delete_admin_only"
  ON public.venues
  FOR DELETE
  USING (
    (select auth.uid()) IS NOT NULL
    AND ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
  );

-- ------------------------------------------------------------
-- B) RLS initplan optimizasyonu
-- ------------------------------------------------------------
-- users
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
CREATE POLICY "Users can view their own profile"
  ON public.users
  FOR SELECT
  USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
CREATE POLICY "Users can update their own profile"
  ON public.users
  FOR UPDATE
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
CREATE POLICY "Users can insert their own profile"
  ON public.users
  FOR INSERT
  WITH CHECK ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can delete their own profile" ON public.users;
CREATE POLICY "Users can delete their own profile"
  ON public.users
  FOR DELETE
  USING ((select auth.uid()) = id);

-- user_favorites
DROP POLICY IF EXISTS "Users can view favorites for venue join" ON public.user_favorites;
CREATE POLICY "Users can view favorites for venue join"
  ON public.user_favorites
  FOR SELECT
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can add their own favorites" ON public.user_favorites;
CREATE POLICY "Users can add their own favorites"
  ON public.user_favorites
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can remove their own favorites" ON public.user_favorites;
CREATE POLICY "Users can remove their own favorites"
  ON public.user_favorites
  FOR DELETE
  USING ((select auth.uid()) = user_id);

-- user_recent_views
DROP POLICY IF EXISTS "Users can view their own recent views" ON public.user_recent_views;
CREATE POLICY "Users can view their own recent views"
  ON public.user_recent_views
  FOR SELECT
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert recent views" ON public.user_recent_views;
CREATE POLICY "Users can insert recent views"
  ON public.user_recent_views
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their recent views" ON public.user_recent_views;
CREATE POLICY "Users can update their recent views"
  ON public.user_recent_views
  FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- user_recent_searches
DROP POLICY IF EXISTS "Users can view their own searches" ON public.user_recent_searches;
CREATE POLICY "Users can view their own searches"
  ON public.user_recent_searches
  FOR SELECT
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert their own searches" ON public.user_recent_searches;
CREATE POLICY "Users can insert their own searches"
  ON public.user_recent_searches
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own searches" ON public.user_recent_searches;
CREATE POLICY "Users can update their own searches"
  ON public.user_recent_searches
  FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ------------------------------------------------------------
-- C) Function execute izinlerini daralt
-- ------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.delete_user() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_user() FROM anon;
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.increment_visit_count(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.increment_visit_count(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.increment_visit_count(uuid) TO authenticated;

-- ------------------------------------------------------------
-- D) Eksik FK indeksleri
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_user_recent_views_venue
  ON public.user_recent_views (venue_id);

CREATE INDEX IF NOT EXISTS idx_user_recent_searches_venue
  ON public.user_recent_searches (venue_id);

COMMIT;
