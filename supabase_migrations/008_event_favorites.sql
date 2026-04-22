-- ============================================================
-- Campus Online - Event Favorites Infrastructure
-- ============================================================
-- Kapsam:
-- 1) Etkinlik favorileri tablosunu olusturur
-- 2) RLS policy'leri ile sadece kullanicinin kendi favorilerini yonetmesini saglar
-- 3) Event detail favori aksiyonu icin gerekli DB altyapisini tamamlar
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.event_favorites (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, event_id)
);

CREATE INDEX IF NOT EXISTS idx_event_favorites_user_id
  ON public.event_favorites (user_id);

CREATE INDEX IF NOT EXISTS idx_event_favorites_event_id
  ON public.event_favorites (event_id);

ALTER TABLE public.event_favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "event_favorites_select_own" ON public.event_favorites;
CREATE POLICY "event_favorites_select_own"
  ON public.event_favorites
  FOR SELECT
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "event_favorites_insert_own" ON public.event_favorites;
CREATE POLICY "event_favorites_insert_own"
  ON public.event_favorites
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "event_favorites_delete_own" ON public.event_favorites;
CREATE POLICY "event_favorites_delete_own"
  ON public.event_favorites
  FOR DELETE
  USING ((select auth.uid()) = user_id);

GRANT SELECT, INSERT, DELETE ON public.event_favorites TO authenticated;

COMMIT;
