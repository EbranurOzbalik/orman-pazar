# Orman Pazar

Orman urunleri icin Flutter ve Firebase tabanli mobil ilan uygulamasi.

Orman Pazar; odun, kereste, tomruk, talas ve benzeri ormancilik urunleri icin gelistirilen nis bir pazar uygulamasidir. Saticilar ilan ekleyebilir, alicilar ilanlari listeleyip detaylarini inceleyebilir.

Bu repo, uygulamanin MVP surecini gun gun ilerleten temiz ve ogrenilebilir bir Flutter projesi olarak hazirlandi.

## Proje Ozeti

| Alan | Durum |
| --- | --- |
| Platform | Flutter mobil uygulama |
| Backend | Firebase / Cloud Firestore |
| Kimlik dogrulama | Firebase Authentication |
| Temel akis | Ilan ekleme, listeleme, detay, duzenleme, silme |
| Tasarim | Orman temasina uygun modern pazar arayuzu |
| Durum | MVP gelistirme asamasi |

## Mevcut Ozellikler

- Orman urunleri icin ilan listeleme
- Ilan detayi goruntuleme
- Kategoriye gore filtreleme
- Baslik, aciklama, sehir, ilce ve agac turune gore arama
- E-posta ve sifre ile kayit / giris
- Giris yapan kullanicinin ilan ekleyebilmesi
- Kullanicinin kendi ilanlarini ayri ekranda yonetebilmesi
- Sadece ilan sahibinin ilan duzenleyip silebilmesi
- Firestore servis katmani uzerinden veri yonetimi
- Profil, satici bilgisi ve temel kullanici altyapisi

## Gelisim Gunlugu

### Gun 1 - MVP iskeleti

- Flutter proje yapisi kuruldu.
- `ListingModel` olusturuldu.
- Firestore islemleri icin `ListingService` ayrildi.
- Ana ekran, ilan ekleme ekrani, ilan detay ekrani ve ilan karti yapisi eklendi.
- Firebase kodlari ekranlardan ayrilip servis katmaninda toplandi.

### Gun 2 - Firebase Android baglantisi

- Android Firebase baglantisi hazirlandi.
- `google-services.json` yerelde projeye eklendi.
- Firestore ile ilan ekleme ve listeleme akisi kuruldu.
- Gizli dosyalarin GitHub'a gitmemesi icin gerekli duzenlemeler yapildi.

### Gun 3 - Ilan kesfi

- Arama alani eklendi.
- Kategori filtreleri eklendi.
- Bos liste, yukleniyor ve hata durumlari iyilestirildi.
- Ana ekran daha kullanisli hale getirildi.

### Gun 4 - Auth akisi

- Firebase Auth servisi eklendi.
- Giris ve kayit ekranlari olusturuldu.
- Ilan eklemek icin giris kontrolu eklendi.
- `sellerId` alani Firebase kullanicisinin `uid` degeriyle calismaya basladi.

### Gun 5 - Kullanici ilan yonetimi

- Benim ilanlarim ekrani eklendi.
- Ilan duzenleme ekrani eklendi.
- Ilan silme akisi eklendi.
- Sadece ilan sahibinin duzenleme ve silme islemi yapmasi saglandi.
- Form dogrulamalari guclendirildi.

### Gun 6 - Tasarim iyilestirmeleri

- Ana ekran daha guclu bir pazar paneline donusturuldu.
- Toplam ve gorunen ilan sayaclari eklendi.
- Kategori filtreleri ikonlarla desteklendi.
- Ilan kartlari kategoriye gore renk ve ikon alacak sekilde yenilendi.
- Detay ekraninda fiyat ve miktar daha belirgin hale getirildi.
- Giris ve kayit ekranlari marka paneli ve form karti duzenine tasindi.

### Gun 7 - Firebase entegrasyon testleri

- Firestore kurallari canli Firebase projesinde uygulandi.
- Email/Password Authentication aktif edildi.
- Test kullanicisi olusturuldu.
- Kayit olan kullanicilarin `users/{uid}` dokumaninda tutulmasi eklendi.
- Firestore'a manuel test ilanlari eklendi.
- Uygulamada Auth ve Firestore ile ilan listeleme test edildi.
- Arama alani sehir ve ilce dahil tek kutuda calisacak sekilde sadelestirildi.
- Ana ekran ust paneli daha kompakt hale getirildi.
- Uygulamadan kayit olma ve ilan ekleme akisi test edildi.

### Gun 8 - Profil ve satici bilgisi

- Kayit formuna ad soyad ve telefon alanlari eklendi.
- Kullanici profili `name + email + phone + createdAt` ile genisletildi.
- Profil ekrani ve profil duzenleme ekrani eklendi.
- Benim ilanlarim ekranina kullanici ozeti baglandi.
- Ilan detayinda satici adi gosterilmeye baslandi.
- Yeni ilan formu, profil telefon bilgisini otomatik dolduracak hale getirildi.

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
    edit_profile_screen.dart
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

Projeyi calistirmadan once Flutter kurulumu tamamlanmis olmalidir.

```bash
flutter pub get
flutter run
```

Firebase ile calistirmak icin kendi Firebase projenizi Android uygulamasi olarak ekleyip `google-services.json` dosyasini `android/app/` klasorune yerlestirin. Bu dosya repoya dahil edilmez.

Kayit olan kullanicilari Firestore'da tutmak icin rules tarafinda `users` koleksiyonu icin su izinler bulunmalidir:

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

## Siradaki Adimlar

- Gercek cihaz veya emulator uzerinde kapsamli kullanici testi
- Fotograf yukleme
- Favorilere ekleme
- Ilan durumu: aktif, satildi, pasif
- Daha gelismis profil yonetimi
- Harita ve konum destegi
- Production icin daha siki Firestore kurallari
