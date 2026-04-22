-- ============================================================
-- Campus Online - Fix Internal Edge Invoke Key
-- ============================================================
-- Scope:
-- 1) Use legacy anon JWT for internal DB -> Edge Function calls
-- ============================================================

BEGIN;

DO $$
DECLARE
  v_secret_id uuid;
BEGIN
  SELECT id
  INTO v_secret_id
  FROM vault.decrypted_secrets
  WHERE name = 'edge_function_anon_key'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_secret_id IS NULL THEN
    PERFORM vault.create_secret(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4bmt4Y3hnZGtuZXZva3Bsa2tvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwMjE1MTAsImV4cCI6MjA4NzU5NzUxMH0.t3VqcywN1jfbW0WNo5v4GjQoohqRgrJ5e9o90aFzWbc',
      'edge_function_anon_key',
      'Campus Online internal Edge Function invoke key'
    );
  ELSE
    PERFORM vault.update_secret(
      v_secret_id,
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4bmt4Y3hnZGtuZXZva3Bsa2tvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwMjE1MTAsImV4cCI6MjA4NzU5NzUxMH0.t3VqcywN1jfbW0WNo5v4GjQoohqRgrJ5e9o90aFzWbc',
      'edge_function_anon_key',
      'Campus Online internal Edge Function invoke key'
    );
  END IF;
END;
$$;

COMMIT;
