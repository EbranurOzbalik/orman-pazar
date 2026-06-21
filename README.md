# Orman Pazar

Orman Pazar, ormancilik urunleri icin gelistirilen Flutter tabanli bir mobil ilan uygulamasidir. Odun, kereste, tomruk, talas gibi urunleri satan kisiler ilan ekleyebilir; alicilar ilanlari listeleyip detaylarini gorebilir.

## Proje Durumu

Bu repo su an ilk MVP gelistirme gunlerini icerir.

- Gun 1: Temel Flutter MVP iskeleti, ilan modeli, servis katmani, ana ekran, ilan ekleme ve detay ekrani.
- Gun 2: Firebase Android baglantisi, Firestore hazirligi ve gercek veritabanina ilan yazma/listeleme akisi.
- Gun 3: Ilan kesfi icin arama, kategori filtresi, bos durum ve hata durumlari.
- Gun 4: Firebase Auth ile email/sifre giris-kayit akisi, ilan eklerken kullanici `uid` bilgisinin `sellerId` olarak kaydedilmesi.
- Gun 5: Kullaniciya ait ilanlar ekrani, ilan duzenleme, ilan silme ve Firestore rules taslagi.

## Ozellikler

- Ilan listeleme
- Ilan detaylarini goruntuleme
- Email/sifre ile kayit ve giris
- Giris yapan kullanicinin ilan eklemesi
- Kullanicinin kendi ilanlarini listelemesi
- Sadece ilan sahibinin ilan duzenleyip silebilmesi
- Kategoriye gore filtreleme
- Baslik, aciklama, sehir, ilce ve agac turune gore arama

## Kullanilan Teknolojiler

- Flutter
- Dart
- Firebase Core
- Cloud Firestore
- Firebase Authentication

## Klasor Yapisi

```text
lib/
  constants/
    app_constants.dart
  models/
    listing_model.dart
  screens/
    add_listing_screen.dart
    edit_listing_screen.dart
    home_screen.dart
    listing_detail_screen.dart
    login_screen.dart
    my_listings_screen.dart
    register_screen.dart
  services/
    auth_service.dart
    listing_service.dart
  widgets/
    listing_card.dart
  main.dart
```

## Firebase Notlari

Android Firebase baglantisi icin `android/app/google-services.json` dosyasi gerekir. Bu dosya guvenlik sebebiyle GitHub'a eklenmemelidir.

Firebase Console tarafinda gerekenler:

- Cloud Firestore aktif olmali.
- Authentication icinde Email/Password giris yontemi aktif olmali.
- Firestore kurallari icin repodaki `firestore.rules` dosyasi taslak olarak kullanilabilir.

## Calistirma

```bash
flutter pub get
flutter run
```

Kontrol komutlari:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Sonraki Adimlar

- Fotograf yukleme
- Harita ve konum destegi
- Favorilere ekleme
- Ilan durumu: aktif, satildi, pasif
- Daha guvenli Firestore kurallari
- Profil ekrani
