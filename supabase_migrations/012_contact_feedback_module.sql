-- ============================================================
-- Campus Online - Contact Feedback Module
-- ============================================================
-- Kapsam:
-- 1) Kullanici geri bildirimlerini toplamak icin user_feedback tablosu
-- 2) Guest+authenticated insert, owner/admin select, admin update/delete RLS
-- 3) Durum takibi ve sorgu performansi icin indeksler
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.user_feedback (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  category text NOT NULL DEFAULT 'general'
    CHECK (category IN ('general', 'suggestion', 'recommendation', 'bug_report')),
  subject text NOT NULL
    CHECK (char_length(btrim(subject)) BETWEEN 4 AND 140),
  message text NOT NULL
    CHECK (char_length(btrim(message)) BETWEEN 10 AND 2000),
  contact_email text
    CHECK (
      contact_email IS NULL
      OR contact_email ~* '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$'
    ),
  device_platform text NOT NULL DEFAULT 'unknown'
    CHECK (char_length(btrim(device_platform)) BETWEEN 2 AND 32),
  status text NOT NULL DEFAULT 'new'
    CHECK (status IN ('new', 'in_review', 'resolved', 'archived')),
  handled_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  admin_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (
    user_id IS NOT NULL
    OR contact_email IS NOT NULL
  )
);

CREATE INDEX IF NOT EXISTS idx_user_feedback_created_at_desc
  ON public.user_feedback (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_feedback_status_created_at
  ON public.user_feedback (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_feedback_user_id_created_at
  ON public.user_feedback (user_id, created_at DESC)
  WHERE user_id IS NOT NULL;

ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_feedback_insert_authenticated_or_guest" ON public.user_feedback;
CREATE POLICY "user_feedback_insert_authenticated_or_guest"
  ON public.user_feedback
  FOR INSERT
  TO authenticated, anon
  WITH CHECK (
    (
      (select auth.uid()) IS NOT NULL
      AND user_id = (select auth.uid())
    )
    OR (
      (select auth.uid()) IS NULL
      AND user_id IS NULL
    )
  );

DROP POLICY IF EXISTS "user_feedback_select_owner_or_admin" ON public.user_feedback;
CREATE POLICY "user_feedback_select_owner_or_admin"
  ON public.user_feedback
  FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid())
    OR public.is_admin((select auth.uid()))
  );

DROP POLICY IF EXISTS "user_feedback_update_admin_only" ON public.user_feedback;
CREATE POLICY "user_feedback_update_admin_only"
  ON public.user_feedback
  FOR UPDATE
  TO authenticated
  USING (public.is_admin((select auth.uid())))
  WITH CHECK (public.is_admin((select auth.uid())));

DROP POLICY IF EXISTS "user_feedback_delete_admin_only" ON public.user_feedback;
CREATE POLICY "user_feedback_delete_admin_only"
  ON public.user_feedback
  FOR DELETE
  TO authenticated
  USING (public.is_admin((select auth.uid())));

DROP TRIGGER IF EXISTS set_user_feedback_updated_at ON public.user_feedback;
CREATE TRIGGER set_user_feedback_updated_at
  BEFORE UPDATE ON public.user_feedback
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

GRANT INSERT ON public.user_feedback TO authenticated, anon;
GRANT SELECT, UPDATE, DELETE ON public.user_feedback TO authenticated;

COMMIT;