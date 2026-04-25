# Campus Online v3

Campus Online v3, universite kampusu icindeki mekan, etkinlik, bildirim ve yonetim is akislari icin gelistirilmis production-odakli Flutter uygulamasidir. Proje; Supabase tabanli guvenli veri erisimi, Firebase Cloud Messaging ile push altyapisi ve Riverpod ile olceklenebilir state yonetimi uzerine kuruludur.

## Core Capabilities

- Guvenli kimlik dogrulama ve profil yonetimi (Supabase Auth)
- Mekan kesfi, detay ekranlari, favorileme ve konum bazli deneyim
- Etkinlik olusturma/goruntuleme, etkinlik favorileri ve etkinlik konum secimi
- Rol bazli admin paneli (yetki, mekan, bildirim, geri bildirim yonetimi)
- Uygulama ici bildirimler + FCM push bildirimi kayit/teslim akislari
- Supabase RLS policy hardening ve migration tabanli surumlu veritabani yonetimi

## Technology Stack

- `Flutter` (Dart 3, Material UI)
- `flutter_riverpod` (state management)
- `supabase_flutter` (auth, database, storage, edge functions)
- `firebase_core` + `firebase_messaging` (push notifications)
- `flutter_map` + `latlong2` (harita/koordinat tabanli gorsellestirme)

## Architecture Snapshot

- `lib/models`: Domain veri modelleri (`event`, `venue`, `notification`, `admin`)
- `lib/providers`: Riverpod provider katmani (auth, access, events, notifications, venues)
- `lib/services`: Supabase/Firebase odakli servisler ve is kurali katmani
- `lib/screens`: Feature bazli UI akislari (auth, events, admin, notifications, settings)
- `lib/widgets`: Yeniden kullanilabilir UI bilesenleri
- `supabase_migrations`: Surumlu SQL migration seti (guvenlik + performans iyilestirmeleri)
- `supabase/functions`: Edge Function kodlari (or. staff hesap olusturma, push dispatch)

## Local Development

### Prerequisites

- Flutter SDK `3.38.x` (stable)
- Dart SDK `3.10.x` (Flutter ile gelen)
- Supabase projesi
- Firebase projesi (FCM kullanimi icin)
- Android Studio / VS Code + Flutter eklentileri

### Setup

```bash
git clone https://github.com/tahaemree/campus_online.git
cd campus_online
flutter pub get
```

### Environment Configuration

Uygulama `--dart-define` ile konfigura edilebilir:

```bash
flutter run --dart-define=SUPABASE_URL=<your-url> --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

Not: `lib/config/env_config.dart` icinde publishable varsayilanlar vardir; production ortaminda CI/CD ile override edilmesi onerilir.

### Database Migrations

- `supabase_migrations` altindaki SQL dosyalarini sira numarasina gore uygulayin.
- Migration seti; RLS, ACL, indeksleme, media storage, event favorites, push token ve notification delivery iyilestirmelerini icerir.

### Edge Functions

- Ornek deploy:

```bash
supabase functions deploy create-staff-account
supabase functions deploy dispatch-notification-push --no-verify-jwt
```

Push bildirim zincirinin tamamlanmasi icin Supabase Vault icinde
`firebase_service_account_json` secret'i bulunmalidir. Bu deger, Firebase
projesinin servis hesabi JSON'inin tam icerigi olmalidir.

## iOS Compatibility (v3)

Bu repoda iOS derleme zinciri icin gerekli Flutter iOS yapisi bulunur:

- `ios/Runner.xcodeproj` ve `ios/Runner.xcworkspace`
- `ios/Runner/Info.plist` (kamera ve galeri izin metinleri tanimli)
- `ios/Podfile` (CocoaPods entegrasyonu eklendi)
- `lib/firebase_options.dart` icinde iOS Firebase konfigrasyonu mevcut

iOS release/cihaza yukleme icin bir macOS ortaminda su akisi izleyin:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --release
```

FCM push icin ek olarak Apple Developer tarafinda APNs anahtari, signing ve capability ayarlarinin dogru yapilandirilmasi gerekir.

## Quality Gates

Projede duzenli olarak su kontroller calistirilmalidir:

```bash
flutter analyze
flutter test
```

## Build Notes

- Android release (split-per-abi):

```bash
flutter build apk --release --split-per-abi
```

- Web ve Android aktif olarak calisir durumdadir.
- iOS pipeline, macOS + Xcode ortaminda build dogrulamasi gerektirir.

## Security Notes

- Service role key istemciye gomulmemelidir; sadece Edge Function server tarafinda kullanilmalidir.
- RLS policy'ler migration disina cikmadan degistirilmelidir.
- Push token ve admin yetki akislarinda least-privilege prensibi korunmalidir.

## Contributing

Degisiklikleri feature branch uzerinden acin, test/analyze sonucuyla birlikte PR olusturun. Buyuk mimari degisikliklerde once issue veya design note ile kapsam netlestirilmesi onerilir.

## License

Bu proje MIT lisansi altindadir. Detaylar icin `LICENSE` dosyasina bakin.
