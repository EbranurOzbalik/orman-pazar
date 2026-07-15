# Orman Pazar

Orman Pazar, orman ürünleri için geliştirilen Flutter ve Firebase tabanlı bir mobil ilan uygulamasıdır.

Uygulamanın odağı; odun, kereste, tomruk, talaş ve benzeri ürünleri satan kişiler ile bu ürünleri arayan kullanıcıları daha düzenli bir ilan deneyiminde buluşturmaktır. Bu repo da projenin MVP sürecini adım adım kurduğumuz, okunabilir ve geliştirmeye açık Flutter kod tabanını içerir.

## Kısa Bakış

| Başlık | Durum |
| --- | --- |
| Platform | Flutter mobil uygulama |
| Backend | Firebase / Cloud Firestore |
| Kimlik doğrulama | Firebase Authentication |
| Temel akış | İlan ekleme, listeleme, detay, düzenleme, silme, favorilere ekleme |
| Tasarım | Orman temasına uygun modern pazar arayüzü |
| Aşama | MVP geliştirme süreci |

## Şu Anda Neler Var?

- İlan listeleme ve detay görüntüleme
- Kategori, durum ve metin tabanlı arama / filtreleme
- E-posta ve şifre ile kayıt / giriş
- Giriş yapan kullanıcının ilan eklemesi
- Kendi ilanlarını düzenleme ve silme
- İlan durumlarını `Aktif`, `Rezerve`, `Satıldı` olarak yönetme
- Favorilere ekleme ve favori ilanları ayrı ekranda görme
- Satıcı profiline gidip satıcının diğer ilanlarını inceleme
- Profil bilgilerini düzenleme
- Firestore servis katmanı üzerinden veri yönetimi

## Gelişim Günlüğü

### Gün 1 - MVP iskeleti

- Flutter proje yapısı kuruldu.
- `ListingModel` ve `ListingService` ayrıldı.
- Ana ekran, ilan ekleme, ilan detay ve ilan kartı yapısı oluşturuldu.
- Firebase kodları ekranlardan ayrılarak daha temiz bir yapı kuruldu.

### Gün 2 - Firebase Android bağlantısı

- Android Firebase bağlantısı hazırlandı.
- `google-services.json` yerelde projeye eklendi.
- Firestore ile temel ilan ekleme ve listeleme akışı kuruldu.
- Gizli dosyaların GitHub'a gitmemesi için düzenleme yapıldı.

### Gün 3 - İlan keşfi

- Arama alanı eklendi.
- Kategori filtreleri eklendi.
- Boş liste, yükleniyor ve hata durumları iyileştirildi.
- Ana ekran daha kullanılır hale getirildi.

### Gün 4 - Auth akışı

- Firebase Auth servisi eklendi.
- Giriş ve kayıt ekranları hazırlandı.
- İlan eklemek için giriş kontrolü eklendi.
- `sellerId` alanı Firebase kullanıcısının `uid` değeriyle çalışmaya başladı.

### Gün 5 - Kullanıcı ilan yönetimi

- Benim ilanlarım ekranı eklendi.
- İlan düzenleme ekranı eklendi.
- İlan silme akışı eklendi.
- Sadece ilan sahibinin düzenleme ve silme yapması sağlandı.
- Form doğrulamaları güçlendirildi.

### Gün 6 - Tasarım iyileştirmeleri

- Ana ekran daha güçlü bir pazar paneline dönüştürüldü.
- Toplam ve görünen ilan sayaçları eklendi.
- Kategori filtreleri ikonlarla desteklendi.
- İlan kartları kategoriye göre yenilendi.
- Detay ekranında fiyat ve miktar daha belirgin hale getirildi.
- Giriş ve kayıt ekranları daha düzenli bir yapıya taşındı.

### Gün 7 - Firebase entegrasyon testleri

- Firestore kuralları canlı Firebase projesinde uygulandı.
- Email/Password Authentication aktif edildi.
- Test kullanıcısı oluşturuldu.
- `users/{uid}` dokümanı tutulmaya başlandı.
- Firestore'a manuel test ilanları eklendi.
- Uygulamada Auth ve Firestore akışları test edildi.

### Gün 8 - Profil ve satıcı bilgisi

- Kayıt formuna ad soyad ve telefon alanları eklendi.
- Kullanıcı profili `name + email + phone + createdAt` ile genişletildi.
- Profil ekranı ve profil düzenleme ekranı eklendi.
- Benim ilanlarım ekranına kullanıcı özeti bağlandı.
- İlan detayında satıcı adı gösterilmeye başlandı.
- Yeni ilan formu profil telefonunu otomatik dolduracak hale geldi.

### Gün 9 - Firebase bağlantısını tamamlama

- Gerçek `firebase_options.dart` yapısı projeye bağlandı.
- `main.dart` içinde Firebase başlatma akışı resmi FlutterFire yapısına taşındı.
- Uygulama açılışına yükleniyor ve hata durum ekranları eklendi.
- Auth ile Firestore kullanıcı dokümanı senkronu güçlendirildi.

### Gün 10 - İlan durum akışı

- İlan modeline durum alanı eklendi.
- `Aktif`, `Rezerve` ve `Satıldı` durumları tanımlandı.
- Ana ekranda duruma göre filtreleme eklendi.
- İlan kartları ve detay ekranına durum rozetleri eklendi.
- Benim ilanlarım ekranında durum özeti güçlendirildi.

### Gün 11 - Favoriler

- Kullanıcı bazlı favori ilan id'leri `users/{uid}` altında tutulmaya başlandı.
- Ana liste kartlarına kalp butonu eklendi.
- Favorilerim ekranı eklendi.
- İlan detay ekranına favori ekleme ve çıkarma akışı bağlandı.
- Profil ekranında favori sayısı görünür hale geldi.

### Gün 12 - Satıcı profili

- İlan detayından satıcı bilgisi tıklanabilir hale getirildi.
- `SellerProfileScreen` eklendi.
- Satıcının telefon, toplam ilan, aktif ilan ve satılan ilan özeti gösterilmeye başlandı.
- Satıcının diğer ilanları tek ekranda listelendi.
- Satıcı profilinden ilan detayına geri akış bağlandı.

### Gün 13 - İlan görselleri

- İlan modeline çoklu görsel desteği eklendi.
- İlan kartlarına kapak görseli, detay ekranına yatay galeri alanı eklendi.
- İlan ekleme ve düzenleme formlarına görsel URL alanları eklendi.
- Cihazdan galeri veya kamera ile görsel seçme akışı bağlandı.
- Seçilen görseller Firebase Storage'a yüklenip ilan kaydına URL olarak eklenmeye başlandı.

### Gün 14 - Görsel deneyimi

- İlan detay ekranındaki galeri kaydırılabilir hale getirildi.
- Görsellere dokununca tam ekran galeri açılmaya başlandı.
- Tam ekran galeride yakınlaştırma ve küçük önizleme şeridi eklendi.
- İlan kartlarında çoklu görsel sayısı daha görünür hale getirildi.

### Gün 15 - Gelişmiş keşif

- Ana ekrana sıralama seçenekleri eklendi.
- Fiyat aralığına göre filtreleme desteği eklendi.
- Ağaç türü ve nakliye durumuna göre ayrıntılı filtreleme eklendi.
- Aktif filtre sayısı görünür hale getirildi.
- Gelişmiş filtreleri tek dokunuşla temizleme akışı eklendi.

### Gün 16 - Satıcı paneli

- `Benim ilanlarım` ekranı daha güçlü bir satıcı paneline dönüştürüldü.
- Toplam portföy değeri, aktif değer ve toplam miktar özetleri eklendi.
- Aktif, rezerve ve satıldı sayılarını daha görünür bir yapıda gösteren üst alan güçlendirildi.
- Duruma göre hızlı filtreleme chip'leri eklendi.
- Seçilen duruma göre sonuç yoksa özel boş durum ekranı eklendi.

### Gün 17 - Güven sinyalleri

- İlan detay ekranına satıcı güven sinyalleri alanı eklendi.
- Satıcının üyelik süresi, profil doluluk hissi ve ilan geçmişi görünür hale geldi.
- İlanın ne kadar önce eklendiği detaya bağlandı.
- Satıcı profilinde güven rozeti ve üyelik süresi alanı güçlendirildi.
- Satıcı profiline rezerve ilan sayısı da eklendi.

### Gün 18 - İlan raporlama temeli

- `ReportModel` ve `ReportService` ile raporlama altyapısı eklendi.
- Firestore için `reports` koleksiyonu hazırlığı yapıldı.
- İlan detay ekranına `İlanı rapor et` akışı eklendi.
- Kullanıcılar seçili neden ve ek not ile rapor bırakabilir hale geldi.
- Kullanıcının kendi ilanını raporlaması engellendi.

### Gün 19 - Raporlama iyileştirmeleri

- Aynı kullanıcının aynı ilanı ikinci kez raporlaması engellendi.
- Kullanıcının bıraktığı mevcut rapor Firestore üzerinden izlenebilir hale geldi.
- İlan detayında rapor durumu için daha belirgin ve modern bir durum alanı eklendi.
- Rapor butonu daha güçlü bir aksiyon düzenine taşındı.

## Proje Yapısı

```text
lib/
  constants/
    app_constants.dart
  models/
    app_user_model.dart
    listing_model.dart
    report_model.dart
  screens/
    add_listing_screen.dart
    edit_listing_screen.dart
    edit_profile_screen.dart
    favorites_screen.dart
    home_screen.dart
    image_gallery_screen.dart
    listing_detail_screen.dart
    login_screen.dart
    my_listings_screen.dart
    profile_screen.dart
    register_screen.dart
    seller_profile_screen.dart
  services/
    auth_service.dart
    listing_service.dart
    report_service.dart
    user_service.dart
  widgets/
    listing_card.dart
  main.dart
```

## Kullandığımız Teknolojiler

- Flutter
- Dart
- Firebase Core
- Cloud Firestore
- Firebase Authentication
- Firebase Storage
- Image Picker

## Çalıştırma

Projeyi çalıştırmadan önce Flutter kurulumu hazır olmalı.

```bash
flutter pub get
flutter run
```

Firebase ile çalıştırmak için kendi Firebase projenizi Android uygulaması olarak ekleyip `google-services.json` dosyasını `android/app/` klasörüne koymanız gerekir. Bu dosya repoya dahil edilmez.

`users` koleksiyonu için temel Firestore rule örneği:

```js
match /users/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow create, update: if request.auth != null && request.auth.uid == userId;
}
```

Kontrol komutları:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Sonraki Adımlar

- Gerçek cihaz veya emülatör üzerinde daha kapsamlı test
- Fiyat aralığı ve daha gelişmiş filtreleme
- Daha gelişmiş profil yönetimi
- Harita ve konum desteği
- Production için daha sıkı Firestore kuralları
