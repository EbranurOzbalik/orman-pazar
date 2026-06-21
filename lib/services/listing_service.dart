import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';

class ListingService {
  ListingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _listingsCollection {
    return _firestore.collection(AppConstants.listingsCollection);
  }

  // Yeni ilanı Firestore'daki `listings` koleksiyonuna ekler.
  // Belge id'sini Firestore otomatik üretir.
  Future<void> addListing(ListingModel listing) async {
    await _listingsCollection.add(listing.toMap());
  }

  // Koleksiyonu canlı dinler. Firestore'da değişiklik oldukça StreamBuilder
  // otomatik yeni listeyi alır ve ekranı günceller.
  Stream<List<ListingModel>> getListings() {
    return _listingsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ListingModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Giris yapan kullanicinin kendi ilanlarini canli dinler.
  // Siralamayi uygulama icinde yapiyoruz; bu sekilde ek Firestore index gerekmez.
  Stream<List<ListingModel>> getListingsBySeller(String sellerId) {
    return _listingsCollection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          final listings = snapshot.docs.map((doc) {
            return ListingModel.fromMap(doc.id, doc.data());
          }).toList();

          listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return listings;
        });
  }

  Future<ListingModel?> getListingById(String id) async {
    final doc = await _listingsCollection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return ListingModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateListing(ListingModel listing) async {
    if (listing.id.isEmpty) {
      throw ArgumentError('Guncellenecek ilanin id bilgisi yok.');
    }

    await _listingsCollection.doc(listing.id).update(listing.toMap());
  }

  Future<void> deleteListing(String id) async {
    await _listingsCollection.doc(id).delete();
  }
}
