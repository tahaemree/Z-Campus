# Supabase SQL Migrations

Bu klasördeki SQL dosyalarını **sırasıyla** Supabase Dashboard > SQL Editor'de çalıştırın.

## Uygulama Sırası

| # | Dosya | Açıklama | Öncelik |
|---|---|---|---|
| 1 | `001_rls_policies.sql` | Tüm tablolara Row Level Security politikaları | **KRİTİK** |
| 2 | `002_delete_user_function.sql` | Hesap silme RPC fonksiyonu (KVKK/GDPR) | **KRİTİK** |
| 3 | `003_updated_at_trigger.sql` | Otomatik güncelleme zamanı takibi | Normal |
| 4 | `004_security_and_performance_hardening.sql` | Yetki uyumu, RLS performans, function privilege daraltma, FK indeksleri | **KRİTİK** |
| 5 | `005_admin_acl_and_events.sql` | Rol tablosu, venue bazli yetki, SKS etkinlik yetkisi, events tablosu ve RLS | **KRİTİK** |
| 6 | `006_policy_and_index_hardening.sql` | users policy tekillestirme + eksik FK indeksleri | **KRİTİK** |
| 7 | `007_media_storage.sql` | Event/venue gorselleri icin storage bucket + role bazli upload policy | **KRİTİK** |
| 8 | `008_event_favorites.sql` | Event favorileme altyapisi (tablo, RLS, indeks) | **KRİTİK** |
| 9 | `009_event_coordinates.sql` | Event koordinat destegi (latitude/longitude + check constraint) | **KRİTİK** |
| 10 | `010_security_surface_tightening.sql` | users self-delete policy kapatma + storage listing daraltma + helper function execute daraltma | **KRİTİK** |
| 11 | `011_admin_role_source_hardening.sql` | admin role kaynagi sertlestirme + security surface tightening idempotent uygulama | **KRİTİK** |
| 12 | `012_contact_feedback_module.sql` | Bize Ulaşın geri bildirim modülü (tablo, RLS, indeksler) | **KRİTİK** |
| 13 | `013_notifications_system.sql` | Uygulama ici bildirim sistemi + feedback trigger bildirimleri | **KRİTİK** |
| 14 | `014_push_tokens_and_fcm_registration.sql` | FCM cihaz token kaydi ve RPC bazli token yonetimi | **KRİTİK** |
| 15 | `015_push_tokens_acl_hardening.sql` | Push token tablosu icin varsayilan genis haklari kaldirma | **KRİTİK** |
| 16 | `016_enterprise_notification_delivery.sql` | Push dispatch pipeline, trigger ve delivery audit altyapisi | **KRİTİK** |
| 17 | `017_fix_internal_edge_invoke_key.sql` | Internal edge invoke key'i legacy anon JWT ile sabitleme | **KRİTİK** |
| 18 | `018_feedback_admin_target_fix.sql` | Feedback admin hedefleme duzeltmesi | **KRİTİK** |
| 19 | `019_push_dispatch_auth_header_fix.sql` | DB->Edge dispatch cagrisinda Authorization header kaynagini sabitleme | **KRİTİK** |
| 20 | `020_broadcast_target_auth_users_fix.sql` | Broadcast bildirim hedeflemesini auth.users tabanli ve eksiksiz hale getirme | **KRİTİK** |

## Nasıl Çalıştırılır

1. [Supabase Dashboard](https://supabase.com/dashboard) > Projenizi seçin
2. Sol menüden **SQL Editor** seçin
3. Her dosyanın içeriğini kopyalayıp yapıştırın
4. **Run** butonuna basın
5. Sırayla 001, 002, 003, 004, 005, 006, 007, 008, 009, 010, 011, 012, 013, 014, 015, 016, 017, 018, 019, 020 şeklinde ilerleyin

## Notlar

- Eğer tablolarda zaten RLS politikaları varsa, `001_rls_policies.sql` hata verebilir.
  Bu durumda mevcut politikaları önce `DROP POLICY` ile silin.
- `002_delete_user_function.sql` `security definer` kullanır — bu fonksiyon
  `auth.users` tablosuna erişim sağlar. Dikkatli olun.
