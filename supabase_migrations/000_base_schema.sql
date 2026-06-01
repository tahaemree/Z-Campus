-- ============================================================
-- Campus Online - Base Schema
-- ============================================================
-- Purpose:
-- 1) Make the migration set runnable on a clean Supabase project
-- 2) Create the base tables expected by the historical RLS migrations
-- 3) Provide the visit-count RPC used by the Flutter app
-- ============================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  display_name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.venues (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name text NOT NULL CHECK (char_length(btrim(name)) > 0),
  category text,
  location text,
  latitude double precision,
  longitude double precision,
  hours text NOT NULL DEFAULT '',
  weekend_hours text NOT NULL DEFAULT '',
  menu text,
  description text,
  announcement text,
  image_url text,
  amenities text[] NOT NULL DEFAULT ARRAY[]::text[],
  visit_count integer NOT NULL DEFAULT 0 CHECK (visit_count >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT venues_coordinates_pair_check CHECK (
    (
      latitude IS NULL
      AND longitude IS NULL
    )
    OR (
      latitude IS NOT NULL
      AND longitude IS NOT NULL
      AND latitude BETWEEN -90 AND 90
      AND longitude BETWEEN -180 AND 180
    )
  )
);

CREATE INDEX IF NOT EXISTS idx_venues_name ON public.venues (name);
CREATE INDEX IF NOT EXISTS idx_venues_category_name
  ON public.venues (category, name)
  WHERE category IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_venues_visit_count_name
  ON public.venues (visit_count DESC, name);

CREATE TABLE IF NOT EXISTS public.user_favorites (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  venue_id uuid NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, venue_id)
);

CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id
  ON public.user_favorites (user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_venue_id
  ON public.user_favorites (venue_id);

CREATE TABLE IF NOT EXISTS public.user_recent_views (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  venue_id uuid NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  viewed_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, venue_id)
);

CREATE INDEX IF NOT EXISTS idx_user_recent_views_user_viewed
  ON public.user_recent_views (user_id, viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_recent_views_venue
  ON public.user_recent_views (venue_id);

CREATE TABLE IF NOT EXISTS public.user_recent_searches (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  venue_id uuid REFERENCES public.venues(id) ON DELETE SET NULL,
  query text NOT NULL DEFAULT '',
  searched_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_recent_searches_user_searched
  ON public.user_recent_searches (user_id, searched_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_recent_searches_venue
  ON public.user_recent_searches (venue_id);

CREATE OR REPLACE FUNCTION public.increment_visit_count(p_venue_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_venue_id IS NULL THEN
    RAISE EXCEPTION 'Venue id is required' USING ERRCODE = '22023';
  END IF;

  UPDATE public.venues
  SET visit_count = COALESCE(visit_count, 0) + 1,
      updated_at = now()
  WHERE id = p_venue_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.increment_visit_count(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.increment_visit_count(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.increment_visit_count(uuid) TO authenticated;

COMMIT;
