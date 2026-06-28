import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/app_user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection(AppConstants.usersCollection);
  }

  Future<void> saveUser(AppUserModel user) async {
    await _usersCollection.doc(user.id).set(user.toMap());
  }

  Future<AppUserModel> ensureUserDocument({
    required String id,
    required String email,
    String name = '',
    String phone = '',
  }) async {
    final existingUser = await getUserById(id);

    if (existingUser != null) {
      final mergedUser = AppUserModel(
        id: existingUser.id,
        name: existingUser.name.trim().isNotEmpty ? existingUser.name : name,
        email: existingUser.email.trim().isNotEmpty
            ? existingUser.email
            : email,
        phone: existingUser.phone.trim().isNotEmpty ? existingUser.phone : phone,
        favoriteListingIds: existingUser.favoriteListingIds,
        createdAt: existingUser.createdAt,
      );

      await updateUser(mergedUser);
      return mergedUser;
    }

    final newUser = AppUserModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      createdAt: DateTime.now(),
    );

    await saveUser(newUser);
    return newUser;
  }

  Future<void> updateUser(AppUserModel user) async {
    await _usersCollection
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUserModel?> getUserById(String id) async {
    final doc = await _usersCollection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return AppUserModel.fromMap(doc.id, doc.data()!);
  }

  Stream<AppUserModel?> watchUserById(String id) {
    return _usersCollection.doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }

      return AppUserModel.fromMap(doc.id, data);
    });
  }

  Stream<Set<String>> watchFavoriteIds(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return <String>{};
      }

      final user = AppUserModel.fromMap(doc.id, data);
      return user.favoriteListingIds.toSet();
    });
  }

  Future<void> addFavorite({
    required String userId,
    required String listingId,
  }) async {
    await _usersCollection.doc(userId).set({
      'favoriteListingIds': FieldValue.arrayUnion([listingId]),
    }, SetOptions(merge: true));
  }

  Future<void> removeFavorite({
    required String userId,
    required String listingId,
  }) async {
    await _usersCollection.doc(userId).set({
      'favoriteListingIds': FieldValue.arrayRemove([listingId]),
    }, SetOptions(merge: true));
  }

  Future<bool> toggleFavorite({
    required String userId,
    required String listingId,
    required bool isFavorite,
  }) {
    if (isFavorite) {
      return removeFavorite(userId: userId, listingId: listingId).then((_) => false);
    }

    return addFavorite(userId: userId, listingId: listingId).then((_) => true);
  }
}
