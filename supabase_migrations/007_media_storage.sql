-- ============================================================
-- Campus Online - Media Storage for Events and Venues
-- ============================================================
-- Kapsam:
-- 1) app-media adinda public storage bucket olusturur
-- 2) image mime tiplerini ve dosya boyutu limitini tanimlar
-- 3) events/venues gorsel yukleme policy'lerini rol bazli tanimlar
-- ============================================================

BEGIN;

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'app-media',
  'app-media',
  true,
  8388608,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "app_media_public_read" ON storage.objects;
CREATE POLICY "app_media_public_read"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'app-media');

DROP POLICY IF EXISTS "app_media_insert_authorized" ON storage.objects;
CREATE POLICY "app_media_insert_authorized"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'app-media'
    AND (select auth.uid()) IS NOT NULL
    AND (storage.foldername(name))[2] = (select auth.uid())::text
    AND (
      (
        (storage.foldername(name))[1] = 'events'
        AND public.can_manage_events((select auth.uid()))
      )
      OR
      (
        (storage.foldername(name))[1] = 'venues'
        AND (
          public.is_admin((select auth.uid()))
          OR EXISTS (
            SELECT 1
            FROM public.user_venue_permissions uvp
            WHERE uvp.user_id = (select auth.uid())
          )
        )
      )
    )
  );

DROP POLICY IF EXISTS "app_media_update_authorized" ON storage.objects;
CREATE POLICY "app_media_update_authorized"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'app-media'
    AND (select auth.uid()) IS NOT NULL
    AND (storage.foldername(name))[2] = (select auth.uid())::text
    AND (
      (
        (storage.foldername(name))[1] = 'events'
        AND public.can_manage_events((select auth.uid()))
      )
      OR
      (
        (storage.foldername(name))[1] = 'venues'
        AND (
          public.is_admin((select auth.uid()))
          OR EXISTS (
            SELECT 1
            FROM public.user_venue_permissions uvp
            WHERE uvp.user_id = (select auth.uid())
          )
        )
      )
    )
  )
  WITH CHECK (
    bucket_id = 'app-media'
    AND (select auth.uid()) IS NOT NULL
    AND (storage.foldername(name))[2] = (select auth.uid())::text
    AND (
      (
        (storage.foldername(name))[1] = 'events'
        AND public.can_manage_events((select auth.uid()))
      )
      OR
      (
        (storage.foldername(name))[1] = 'venues'
        AND (
          public.is_admin((select auth.uid()))
          OR EXISTS (
            SELECT 1
            FROM public.user_venue_permissions uvp
            WHERE uvp.user_id = (select auth.uid())
          )
        )
      )
    )
  );

DROP POLICY IF EXISTS "app_media_delete_authorized" ON storage.objects;
CREATE POLICY "app_media_delete_authorized"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'app-media'
    AND (select auth.uid()) IS NOT NULL
    AND (storage.foldername(name))[2] = (select auth.uid())::text
    AND (
      (
        (storage.foldername(name))[1] = 'events'
        AND public.can_manage_events((select auth.uid()))
      )
      OR
      (
        (storage.foldername(name))[1] = 'venues'
        AND (
          public.is_admin((select auth.uid()))
          OR EXISTS (
            SELECT 1
            FROM public.user_venue_permissions uvp
            WHERE uvp.user_id = (select auth.uid())
          )
        )
      )
    )
  );

COMMIT;
