-- ============================================================
-- Z Kampüs - Venue Favorite Counts
-- ============================================================
-- Purpose:
-- 1) Expose aggregate venue favorite counts without relaxing user_favorites RLS
-- 2) Support venue detail statistics in the Flutter app
-- ============================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.get_venue_favorite_count(
  p_venue_id uuid
)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::integer
  FROM public.user_favorites uf
  WHERE uf.venue_id = p_venue_id;
$$;

REVOKE ALL ON FUNCTION public.get_venue_favorite_count(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_venue_favorite_count(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_venue_favorite_count(uuid) TO authenticated;

COMMIT;
