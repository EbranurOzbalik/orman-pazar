# Orman Pazar

description: "Orman ürünleri için Flutter ve Firebase tabanlı mobil ilan uygulaması."

Orman Pazar, ormancılık ürünleri için geliştirilen Flutter tabanlı bir mobil ilan uygulamasıdır. Odun, kereste, tomruk, talaş gibi ürünleri satan kişiler ilan ekleyebilir; alıcılar ilanları listeleyip detaylarını inceleyebilir.

Bu repo, uygulamanin MVP surecini gun gun ilerleten temiz ve ogrenilebilir bir Flutter projesi olarak hazirlanmistir.

## Kisa Ozet

| Alan | Durum |
| --- | --- |
| Platform | Flutter mobil uygulama |
| Backend | Firebase / Cloud Firestore |
| Auth | Firebase Authentication |
| Ana akis | Ilan ekleme, listeleme, detay, duzenleme, silme |
| Tasarim | Orman temasina uygun modern pazar arayuzu |
| Durum | MVP gelistirme asamasi |

## Temel Ozellikler

- Ormancilik urunleri icin ilan listeleme
- Ilan detayi goruntuleme
- Kategoriye gore filtreleme
- Baslik, aciklama, sehir, ilce ve agac turune gore arama
- Email/sifre ile kayit ve giris
- Giris yapan kullanicinin ilan eklemesi
- Kullanicinin kendi ilanlarini ayri ekranda gorebilmesi
- Sadece ilan sahibinin ilan duzenleyip silebilmesi
- Firestore rules taslagi
- Modern ana ekran, ilan karti, detay ve auth ekranlari

## Gelisim Gunlugu

### Gun 1 - MVP Iskeleti

- Flutter proje yapisi duzenlendi.
- `ListingModel` olusturuldu.
- Firestore islemleri icin `ListingService` ayrildi.
- Ana ekran, ilan ekleme ekrani, ilan detay ekrani ve ilan karti eklendi.
- Firebase kodlari ekranlarin icine dagitilmadan servis katmaninda toplandi.

### Gun 2 - Firebase Android Baglantisi

- Android Firebase baglantisi hazirlandi.
- `google-services.json` yerelde projeye eklendi.
- Firestore ile ilan ekleme ve listeleme akisi hazirlandi.
- Gizli config dosyalarinin GitHub'a gitmemesi icin dikkat edildi.

### Gun 3 - Ilan Kesfi

- Arama alani eklendi.
- Kategori filtreleri eklendi.
- Bos liste, yukleniyor ve hata durumlari iyilestirildi.
- Ana ekran daha kullanilir hale getirildi.

### Gun 4 - Auth Akisi

- Firebase Auth servisi eklendi.
- Giris ve kayit ekranlari olusturuldu.
- Ilan eklemek icin giris kontrolu eklendi.
- `sellerId` degeri gecici kullanicidan Firebase kullanici `uid` degerine tasindi.

### Gun 5 - Kullanici Ilan Yonetimi

- Benim ilanlarim ekrani eklendi.
- Ilan duzenleme ekrani eklendi.
- Ilan silme akisi eklendi.
- Sadece ilan sahibinin duzenleme/silme islemi yapmasi saglandi.
- Form dogrulamalari guclendirildi.

### Gun 6 - Tasarim Polish

- Ana ekran daha guclu bir pazar paneline donusturuldu.
- Toplam ve gorunen ilan sayaclari eklendi.
- Kategori filtreleri ikonlandi.
- Ilan kartlari kategoriye gore renk ve ikon alacak sekilde yenilendi.
- Detay ekraninda fiyat ve miktar daha belirgin hale getirildi.
- Giris ve kayit ekranlari marka paneli + form karti yapisina tasindi.

### Gün 7 - Firebase Entegrasyon Testleri

- Firestore kuralları canlı Firebase projesinde uygulandı.
- Email/Password Authentication aktif edildi.
- Test kullanıcı oluşturuldu.
- Kayıt olan kullanıcıların `users/{uid}` dokümanında tutulması eklendi.
- Firestore'a manuel test ilanları eklendi.
- Uygulamada Auth + Firestore ile ilan listeleme test edildi.
- Arama alanı şehir/ilçe dahil tek kutuda çalışacak şekilde sadeleştirildi.
- Ana ekran üst paneli daha kompakt hale getirildi.
- Uygulamadan kayıt olma ve ilan ekleme akışı test kapsamına alındı.

### Gün 8 - Profil ve Satıcı Bilgisi

- Kayıt formuna `ad soyad` alanı eklendi.
- Kullanıcı profili `name + email + createdAt` ile Firestore'da tutulacak şekilde genişletildi.
- Profil ekranı eklendi.
- Benim ilanlarım ekranına kullanıcı özeti bağlandı.
- İlan detayında satıcı adı ve satıcı e-posta bilgisi gösterilmeye başlandı.

## Teknik Yapi

```text
lib/
  constants/
    app_constants.dart
  models/
    app_user_model.dart
    listing_model.dart
  screens/
    add_listing_screen.dart
    edit_listing_screen.dart
    home_screen.dart
    listing_detail_screen.dart
    login_screen.dart
    my_listings_screen.dart
    profile_screen.dart
    register_screen.dart
  services/
    auth_service.dart
    listing_service.dart
    user_service.dart
  widgets/
    listing_card.dart
  main.dart
```

## Kullanilan Teknolojiler

- Flutter
- Dart
- Firebase Core
- Cloud Firestore
- Firebase Authentication

## Calistirma

Projeyi calistirmadan once Flutter kurulumu tamamlanmis olmali.

```bash
flutter pub get
flutter run
```

Firebase ile calistirmak icin kendi Firebase projenizi Android uygulamasi olarak ekleyip `google-services.json` dosyasini `android/app/` klasorune yerlestirin. Bu dosya repoya dahil edilmez.

Kayıt olan kullanıcıları Firestore'da tutmak için rules içinde `users` koleksiyonuna şu izin de eklenmelidir:

```js
match /users/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow create, update: if request.auth != null && request.auth.uid == userId;
}
```

Kontrol komutlari:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Yol Haritasi

- Gercek cihaz/emulator uzerinde kayit, giris, ilan ekleme, duzenleme ve silme testi
- Fotograf yukleme
- Favorilere ekleme
- Ilan durumu: aktif, satildi, pasif
- Profil ekrani
- Harita ve konum destegi
- Daha guvenli production Firestore kurallari
