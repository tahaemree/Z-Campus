-- ============================================================
-- Campus Online - Deprecated Internal Edge Invoke Key
-- ============================================================
-- Scope:
-- 1) Preserve migration ordering without storing client API keys in source
-- ============================================================

BEGIN;

DO $$
BEGIN
  RAISE NOTICE 'edge_function_anon_key is deprecated; push dispatch uses push_dispatch_secret only.';
END;
$$;

COMMIT;
