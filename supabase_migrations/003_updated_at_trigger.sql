-- ============================================================
-- Campus Online — updated_at Trigger
-- ============================================================
-- Bu migration'ı Supabase Dashboard > SQL Editor'de çalıştırın.
-- ============================================================

-- Otomatik updated_at güncellemesi için trigger fonksiyonu
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- venues tablosuna trigger ekle
DROP TRIGGER IF EXISTS set_updated_at ON public.venues;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.venues
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- users tablosuna trigger ekle
DROP TRIGGER IF EXISTS set_updated_at ON public.users;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();
