-- ============================================================
-- Campus Online - Event Coordinate Support
-- ============================================================
-- Kapsam:
-- 1) events tablosuna latitude/longitude alanlarini ekler
-- 2) Koordinat ciftini dogrular (ikisi birlikte dolu veya birlikte bos)
-- 3) Enlem/boylam araligi kontrolunu zorunlu kilar
-- ============================================================

BEGIN;

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS latitude double precision,
  ADD COLUMN IF NOT EXISTS longitude double precision;

ALTER TABLE public.events
  DROP CONSTRAINT IF EXISTS events_coordinates_pair_check;

ALTER TABLE public.events
  ADD CONSTRAINT events_coordinates_pair_check
  CHECK (
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
  );

COMMIT;
