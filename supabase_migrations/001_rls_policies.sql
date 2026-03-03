-- ============================================================
-- Campus Online — RLS Policies Migration
-- ============================================================
-- Bu migration'ı Supabase Dashboard > SQL Editor'de çalıştırın.
-- ============================================================

-- 1. venues tablosunda RLS'yi etkinleştir
ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;

-- 2. Herkes okuyabilir (SELECT)
CREATE POLICY "venues_select_all"
  ON public.venues
  FOR SELECT
  USING (true);

-- 3. Sadece admin kullanıcılar INSERT yapabilir
-- (user_metadata.role = 'admin' veya legacy admin email kontrolü)
CREATE POLICY "venues_insert_admin_only"
  ON public.venues
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
      (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
      OR (auth.jwt() ->> 'email') = 'admin@admin.com'
    )
  );

-- 4. Sadece admin kullanıcılar UPDATE yapabilir
CREATE POLICY "venues_update_admin_only"
  ON public.venues
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND (
      (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
      OR (auth.jwt() ->> 'email') = 'admin@admin.com'
    )
  );

-- 5. Sadece admin kullanıcılar DELETE yapabilir
CREATE POLICY "venues_delete_admin_only"
  ON public.venues
  FOR DELETE
  USING (
    auth.uid() IS NOT NULL
    AND (
      (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
      OR (auth.jwt() ->> 'email') = 'admin@admin.com'
    )
  );

-- ============================================================
-- user_favorites tablosu RLS
-- ============================================================

ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

-- Kullanıcı sadece kendi favorilerini görebilir
CREATE POLICY "user_favorites_select_own"
  ON public.user_favorites
  FOR SELECT
  USING (auth.uid() = user_id);

-- Kullanıcı sadece kendi favorilerini ekleyebilir
CREATE POLICY "user_favorites_insert_own"
  ON public.user_favorites
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Kullanıcı sadece kendi favorilerini silebilir
CREATE POLICY "user_favorites_delete_own"
  ON public.user_favorites
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- user_recent_views tablosu RLS
-- ============================================================

ALTER TABLE public.user_recent_views ENABLE ROW LEVEL SECURITY;

-- Kullanıcı sadece kendi görüntülemelerini görebilir
CREATE POLICY "user_recent_views_select_own"
  ON public.user_recent_views
  FOR SELECT
  USING (auth.uid() = user_id);

-- Kullanıcı sadece kendi görüntülemelerini ekleyebilir/güncelleyebilir
CREATE POLICY "user_recent_views_insert_own"
  ON public.user_recent_views
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_recent_views_update_own"
  ON public.user_recent_views
  FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- users tablosu RLS
-- ============================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Kullanıcı sadece kendi profilini okuyabilir
CREATE POLICY "users_select_own"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- Kullanıcı sadece kendi profilini güncelleyebilir
CREATE POLICY "users_update_own"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id);

-- Kullanıcı kendi profilini oluşturabilir (signup sırasında)
CREATE POLICY "users_insert_own"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Kullanıcı sadece kendi profilini silebilir
CREATE POLICY "users_delete_own"
  ON public.users
  FOR DELETE
  USING (auth.uid() = id);
