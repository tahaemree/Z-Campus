-- ============================================================
-- Campus Online - Bildirim Sistemi
-- ============================================================
-- Kapsam:
-- 1) Uygulama ici bildirimler icin notifications tablosu
-- 2) Admin panelinden ozel bildirim gonderimi
-- 3) user_feedback INSERT trigger -> admin bildirimi olusturma
-- 4) RLS: Kullanici kendi bildirimlerini gorur, admin hepsini gorur
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) Bildirimler tablosu
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 200),
  body text NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 2000),
  type text NOT NULL DEFAULT 'general'
    CHECK (type IN ('general', 'event', 'venue', 'feedback', 'admin_broadcast')),
  target_id text,
  is_read boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Ikincil indeksler: kullaniciya gore ve zaman sirasina gore sorgular
CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON public.notifications (user_id, created_at DESC)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_broadcast_created
  ON public.notifications (created_at DESC)
  WHERE user_id IS NULL AND type = 'admin_broadcast';

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id, is_read)
  WHERE is_read = false;

-- ------------------------------------------------------------
-- B) RLS
-- ------------------------------------------------------------
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Kullanici: kendi bildirimlerini + broadcast bildirimlerini gorebilir
DROP POLICY IF EXISTS "notifications_select_own_or_broadcast" ON public.notifications;
CREATE POLICY "notifications_select_own_or_broadcast"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid())
    OR (user_id IS NULL AND type = 'admin_broadcast')
    OR public.is_admin((select auth.uid()))
  );

-- Kullanici: kendi bildirimlerini okundu olarak isaret edebilir
DROP POLICY IF EXISTS "notifications_update_own_read" ON public.notifications;
CREATE POLICY "notifications_update_own_read"
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (
    user_id = (select auth.uid())
    OR (user_id IS NULL AND type = 'admin_broadcast')
  )
  WITH CHECK (
    user_id = (select auth.uid())
    OR (user_id IS NULL AND type = 'admin_broadcast')
  );

-- Admin: bildirim olusturabilir
DROP POLICY IF EXISTS "notifications_insert_admin" ON public.notifications;
CREATE POLICY "notifications_insert_admin"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_admin((select auth.uid()))
  );

-- Admin: bildirim silebilir
DROP POLICY IF EXISTS "notifications_delete_admin" ON public.notifications;
CREATE POLICY "notifications_delete_admin"
  ON public.notifications
  FOR DELETE
  TO authenticated
  USING (
    public.is_admin((select auth.uid()))
  );

-- Admin: tum bildirimleri guncelleyebilir (okundu/silinmis vb.)
DROP POLICY IF EXISTS "notifications_update_admin" ON public.notifications;
CREATE POLICY "notifications_update_admin"
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (public.is_admin((select auth.uid())))
  WITH CHECK (public.is_admin((select auth.uid())));

-- ------------------------------------------------------------
-- C) Trigger: updated_at otomatik guncelleme
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS set_notifications_updated_at ON public.notifications;
CREATE TRIGGER set_notifications_updated_at
  BEFORE UPDATE ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------
-- D) Trigger: user_feedback INSERT -> admin bildirimi olustur
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_admin_on_feedback()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_category_label text;
  v_admin_row record;
BEGIN
  -- Kategori etiketini belirle
  CASE NEW.category
    WHEN 'general' THEN v_category_label := 'Genel Geri Bildirim';
    WHEN 'suggestion' THEN v_category_label := 'Öneri';
    WHEN 'recommendation' THEN v_category_label := 'Tavsiye';
    WHEN 'bug_report' THEN v_category_label := 'Hata Bildirimi';
    ELSE v_category_label := 'Geri Bildirim';
  END CASE;

  -- Her admin kullanicisi icin bildirim olustur
  FOR v_admin_row IN
    SELECT ur.user_id
    FROM public.user_roles ur
    WHERE ur.role = 'admin'
  LOOP
    INSERT INTO public.notifications (
      user_id,
      title,
      body,
      type,
      target_id,
      created_by
    ) VALUES (
      v_admin_row.user_id,
      v_category_label || ': ' || left(NEW.subject, 80),
      left(NEW.message, 200),
      'feedback',
      NEW.id::text,
      NEW.user_id
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_admin_on_feedback ON public.user_feedback;
CREATE TRIGGER trg_notify_admin_on_feedback
  AFTER INSERT ON public.user_feedback
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_admin_on_feedback();

-- ------------------------------------------------------------
-- E) Izinler
-- ------------------------------------------------------------
GRANT SELECT, UPDATE ON public.notifications TO authenticated;
GRANT INSERT ON public.notifications TO authenticated;
GRANT DELETE ON public.notifications TO authenticated;

COMMIT;
