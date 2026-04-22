-- ============================================================
-- Campus Online - Policy and Index Hardening
-- ============================================================
-- Kapsam:
-- 1) users tablosundaki coklu permissive policy'leri tek policy setine indirir
-- 2) Advisor tarafinda raporlanan eksik FK indekslerini ekler
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) users policies - self + admin birlestirme
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "users_admin_console_select" ON public.users;
CREATE POLICY "users_select_self_or_admin"
  ON public.users
  FOR SELECT
  USING (
    (select auth.uid()) = id
    OR public.is_admin((select auth.uid()))
  );

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "users_admin_console_insert" ON public.users;
CREATE POLICY "users_insert_self_or_admin"
  ON public.users
  FOR INSERT
  WITH CHECK (
    (select auth.uid()) = id
    OR public.is_admin((select auth.uid()))
  );

DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "users_admin_console_update" ON public.users;
CREATE POLICY "users_update_self_or_admin"
  ON public.users
  FOR UPDATE
  USING (
    (select auth.uid()) = id
    OR public.is_admin((select auth.uid()))
  )
  WITH CHECK (
    (select auth.uid()) = id
    OR public.is_admin((select auth.uid()))
  );

-- ------------------------------------------------------------
-- B) Eksik FK indeksleri
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_events_created_by
  ON public.events (created_by);

CREATE INDEX IF NOT EXISTS idx_events_updated_by
  ON public.events (updated_by);

CREATE INDEX IF NOT EXISTS idx_user_roles_created_by
  ON public.user_roles (created_by);

CREATE INDEX IF NOT EXISTS idx_uvp_created_by
  ON public.user_venue_permissions (created_by);

COMMIT;