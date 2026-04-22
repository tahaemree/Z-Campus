-- ============================================================
-- Campus Online - Push Tokens and FCM Registration
-- ============================================================
-- Scope:
-- 1) user_push_tokens table for device token storage
-- 2) RLS policies for per-user visibility
-- 3) RPC functions for secure token register/unregister
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) Device push tokens
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_push_tokens (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL UNIQUE CHECK (char_length(btrim(token)) > 0),
  platform text NOT NULL DEFAULT 'unknown'
    CHECK (platform IN ('android', 'ios', 'web', 'macos', 'windows', 'linux', 'unknown')),
  device_locale text,
  is_active boolean NOT NULL DEFAULT true,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_push_tokens_user_active
  ON public.user_push_tokens (user_id, is_active, last_seen_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_push_tokens_last_seen
  ON public.user_push_tokens (last_seen_at DESC);

-- ------------------------------------------------------------
-- B) RLS
-- ------------------------------------------------------------
ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "push_tokens_select_own_or_admin" ON public.user_push_tokens;
CREATE POLICY "push_tokens_select_own_or_admin"
  ON public.user_push_tokens
  FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid())
    OR public.is_admin((select auth.uid()))
  );

DROP POLICY IF EXISTS "push_tokens_insert_own_or_admin" ON public.user_push_tokens;
CREATE POLICY "push_tokens_insert_own_or_admin"
  ON public.user_push_tokens
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = (select auth.uid())
    OR public.is_admin((select auth.uid()))
  );

DROP POLICY IF EXISTS "push_tokens_update_own_or_admin" ON public.user_push_tokens;
CREATE POLICY "push_tokens_update_own_or_admin"
  ON public.user_push_tokens
  FOR UPDATE
  TO authenticated
  USING (
    user_id = (select auth.uid())
    OR public.is_admin((select auth.uid()))
  )
  WITH CHECK (
    user_id = (select auth.uid())
    OR public.is_admin((select auth.uid()))
  );

DROP POLICY IF EXISTS "push_tokens_delete_own_or_admin" ON public.user_push_tokens;
CREATE POLICY "push_tokens_delete_own_or_admin"
  ON public.user_push_tokens
  FOR DELETE
  TO authenticated
  USING (
    user_id = (select auth.uid())
    OR public.is_admin((select auth.uid()))
  );

-- ------------------------------------------------------------
-- C) updated_at trigger
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS set_user_push_tokens_updated_at ON public.user_push_tokens;
CREATE TRIGGER set_user_push_tokens_updated_at
  BEFORE UPDATE ON public.user_push_tokens
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------
-- D) RPC: register/unregister push token
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.register_push_token(
  p_token text,
  p_platform text DEFAULT 'unknown',
  p_device_locale text DEFAULT null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_token text := nullif(btrim(p_token), '');
  v_platform text := lower(coalesce(nullif(btrim(p_platform), ''), 'unknown'));
  v_locale text := nullif(btrim(p_device_locale), '');
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF v_token IS NULL THEN
    RAISE EXCEPTION 'Token is required';
  END IF;

  IF v_platform NOT IN ('android', 'ios', 'web', 'macos', 'windows', 'linux', 'unknown') THEN
    v_platform := 'unknown';
  END IF;

  INSERT INTO public.user_push_tokens (
    user_id,
    token,
    platform,
    device_locale,
    is_active,
    last_seen_at
  ) VALUES (
    v_user_id,
    v_token,
    v_platform,
    v_locale,
    true,
    now()
  )
  ON CONFLICT (token)
  DO UPDATE SET
    user_id = EXCLUDED.user_id,
    platform = EXCLUDED.platform,
    device_locale = EXCLUDED.device_locale,
    is_active = true,
    last_seen_at = now(),
    updated_at = now();
END;
$$;

CREATE OR REPLACE FUNCTION public.unregister_push_token(
  p_token text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_token text := nullif(btrim(p_token), '');
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF v_token IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.user_push_tokens
  SET is_active = false,
      last_seen_at = now(),
      updated_at = now()
  WHERE token = v_token
    AND user_id = v_user_id;
END;
$$;

-- ------------------------------------------------------------
-- E) Privileges
-- ------------------------------------------------------------
REVOKE ALL ON public.user_push_tokens FROM anon;
REVOKE ALL ON public.user_push_tokens FROM authenticated;
GRANT SELECT ON public.user_push_tokens TO authenticated;

REVOKE EXECUTE ON FUNCTION public.register_push_token(text, text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.register_push_token(text, text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.register_push_token(text, text, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.unregister_push_token(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.unregister_push_token(text) FROM anon;
GRANT EXECUTE ON FUNCTION public.unregister_push_token(text) TO authenticated;

COMMIT;
