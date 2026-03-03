-- ============================================================
-- Campus Online — delete_user RPC Function
-- ============================================================
-- Bu migration'ı Supabase Dashboard > SQL Editor'de çalıştırın.
--
-- BU FONKSİYON KRİTİKTİR:
-- `security definer` olarak çalışır — auth.users tablosuna
-- yalnızca bu fonksiyon üzerinden erişim sağlanır.
-- Kullanıcı sadece kendi hesabını silebilir (auth.uid() kontrolü).
-- ============================================================

-- Kullanıcının kendi hesabını silmesi için güvenli RPC fonksiyonu
CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Önce public şemadaki ilişkili verileri temizle
  DELETE FROM public.user_favorites WHERE user_id = auth.uid();
  DELETE FROM public.user_recent_views WHERE user_id = auth.uid();
  DELETE FROM public.users WHERE id = auth.uid();

  -- auth.users'tan sil (security definer sayesinde mümkün)
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- RPC erişim izni
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;

-- Anonim kullanıcıların bu fonksiyonu çağırmasını engelle
REVOKE EXECUTE ON FUNCTION public.delete_user() FROM anon;
