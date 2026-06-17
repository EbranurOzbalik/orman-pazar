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

  Future<ListingModel?> getListingById(String id) async {
    final doc = await _listingsCollection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return ListingModel.fromMap(doc.id, doc.data()!);
  }
}
