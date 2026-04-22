-- ============================================================
-- Campus Online - Push Token ACL Hardening
-- ============================================================
-- Scope:
-- 1) Remove broad default table privileges for anon/authenticated
-- 2) Keep read access for authenticated users only
-- ============================================================

BEGIN;

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
