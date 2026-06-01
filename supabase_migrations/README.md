# Supabase SQL Migrations

Bu klasordeki SQL dosyalari sira numarasina gore uygulanmalidir. Yeni kurulumlarda `000_base_schema.sql` ile baslayin; mevcut canli projelerde daha once uygulanmis dosyalari tekrar calistirmeden yalnizca eksik sonraki migration'lari uygulayin.

## Uygulama Sirasi

| # | Dosya | Aciklama | Oncelik |
|---|---|---|---|
| 0 | `000_base_schema.sql` | Temel tablo seti ve `increment_visit_count` RPC | Kritik |
| 1 | `001_rls_policies.sql` | Ana tablolar icin RLS policy seti | Kritik |
| 2 | `002_delete_user_function.sql` | Hesap silme RPC fonksiyonu | Kritik |
| 3 | `003_updated_at_trigger.sql` | Otomatik `updated_at` trigger'lari | Normal |
| 4 | `004_security_and_performance_hardening.sql` | RLS ve FK indeks sertlestirmeleri | Kritik |
| 5 | `005_admin_acl_and_events.sql` | Admin ACL, venue yetkileri ve events modulu | Kritik |
| 6 | `006_policy_and_index_hardening.sql` | Users policy tekillestirme ve ek indeksler | Kritik |
| 7 | `007_media_storage.sql` | App media bucket ve storage policy'leri | Kritik |
| 8 | `008_event_favorites.sql` | Event favorileri | Kritik |
| 9 | `009_event_coordinates.sql` | Event koordinat alanlari ve constraint | Kritik |
| 10 | `010_security_surface_tightening.sql` | Users delete/storage/function yuzeyi daraltma | Kritik |
| 11 | `011_admin_role_source_hardening.sql` | Admin role kaynagi sertlestirme | Kritik |
| 12 | `012_contact_feedback_module.sql` | Geri bildirim modulu | Kritik |
| 13 | `013_notifications_system.sql` | Uygulama ici bildirim sistemi | Kritik |
| 14 | `014_push_tokens_and_fcm_registration.sql` | FCM token kayit RPC'leri | Kritik |
| 15 | `015_push_tokens_acl_hardening.sql` | Push token ACL daraltma | Kritik |
| 16 | `016_enterprise_notification_delivery.sql` | Push delivery pipeline ve audit tablo seti | Kritik |
| 17 | `017_fix_internal_edge_invoke_key.sql` | Eski invoke key migration placeholder'i | Kritik |
| 18 | `018_feedback_admin_target_fix.sql` | Feedback admin hedefleme duzeltmesi | Kritik |
| 19 | `019_push_dispatch_auth_header_fix.sql` | Push dispatch auth header duzeltmesi | Kritik |
| 20 | `020_broadcast_target_auth_users_fix.sql` | Broadcast hedeflerini `auth.users` tabanli yapma | Kritik |
| 21 | `021_notification_pipeline_reliability_repair.sql` | Notification pipeline indeks ve fonksiyon tekrar sabitleme | Kritik |
| 22 | `022_professional_hardening.sql` | Dar notification RPC'leri, hesap silme ve event FK onarimi | Kritik |
| 23 | `023_venue_favorite_counts.sql` | Venue detay favori sayisi RPC'si | Kritik |
| 24 | `024_explore_contributions_and_notification_delete.sql` | Kesfet katki yonetimi ve notification delete onarimi | Kritik |
| 25 | `025_notification_read_rpc_and_explore_schedule_hardening.sql` | Notification okundu RPC onarimi ve Kesfet zamanlama sertlestirmesi | Kritik |
| 26 | `026_push_dispatch_secret_only.sql` | Push dispatch icin client key/JWT bagimliligini kaldirma | Kritik |

## Canli Proje Icin

1. Supabase Dashboard > SQL Editor'a girin.
2. Son uygulanan migration numarasini netlestirin.
3. Sadece eksik dosyalari sirayla calistirin.
4. Bu revizyondan sonra mevcut proje icin en az `021`, `022`, `023`, `024`, `025` ve `026` uygulanmis olmalidir.

## Yeni Proje Icin

1. `000_base_schema.sql` dosyasindan baslayin.
2. Tum dosyalari `000` -> `026` sirasiyla uygulayin.
3. Edge Function'lari deploy edin:

```bash
supabase functions deploy create-staff-account
supabase functions deploy dispatch-notification-push --no-verify-jwt
```

4. Supabase Vault icinde `firebase_service_account_json` secret'ini ekleyin.

## Notlar

- `delete_user`, `mark_notification_read`, `mark_all_notifications_read`, `delete_notification` ve `get_venue_favorite_count` `SECURITY DEFINER` RPC'leridir. Yetkiyi fonksiyon icinde daraltirlar; aggregate sayim icin RLS policy gevsetilmez.
- Bildirim satirlarinda kullanici update/delete yetkisi tablo seviyesinde daraltilmistir; istemci bu islemler icin RPC kullanmalidir.
- `dispatch-notification-push` JWT dogrulamasi kapali deploy edilir ve yalnizca Vault'taki `push_dispatch_secret` webhook header'i ile cagrilmalidir.
- Service role key istemciye gomulmemelidir. Yalnizca Edge Function ortam degiskenlerinde bulunmalidir.
