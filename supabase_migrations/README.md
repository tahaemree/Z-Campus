# Supabase SQL Migrations

Bu klasördeki SQL dosyalarını **sırasıyla** Supabase Dashboard > SQL Editor'de çalıştırın.

## Uygulama Sırası

| # | Dosya | Açıklama | Öncelik |
|---|---|---|---|
| 1 | `001_rls_policies.sql` | Tüm tablolara Row Level Security politikaları | **KRİTİK** |
| 2 | `002_delete_user_function.sql` | Hesap silme RPC fonksiyonu (KVKK/GDPR) | **KRİTİK** |
| 3 | `003_updated_at_trigger.sql` | Otomatik güncelleme zamanı takibi | Normal |

## Nasıl Çalıştırılır

1. [Supabase Dashboard](https://supabase.com/dashboard) > Projenizi seçin
2. Sol menüden **SQL Editor** seçin
3. Her dosyanın içeriğini kopyalayıp yapıştırın
4. **Run** butonuna basın
5. Sırayla 001, 002, 003 şeklinde ilerleyin

## Notlar

- Eğer tablolarda zaten RLS politikaları varsa, `001_rls_policies.sql` hata verebilir.
  Bu durumda mevcut politikaları önce `DROP POLICY` ile silin.
- `002_delete_user_function.sql` `security definer` kullanır — bu fonksiyon
  `auth.users` tablosuna erişim sağlar. Dikkatli olun.
