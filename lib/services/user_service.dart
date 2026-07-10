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
      final resolvedName = existingUser.name.trim().isNotEmpty
          ? existingUser.name
          : name;
      final resolvedEmail = existingUser.email.trim().isNotEmpty
          ? existingUser.email
          : email;
      final resolvedPhone = existingUser.phone.trim().isNotEmpty
          ? existingUser.phone
          : phone;

      final mergedUser = AppUserModel(
        id: existingUser.id,
        name: resolvedName,
        email: resolvedEmail,
        phone: resolvedPhone,
        profileCompleted: _isProfileCompleted(
          name: resolvedName,
          email: resolvedEmail,
          phone: resolvedPhone,
        ),
        trustScore: _buildTrustScore(
          name: resolvedName,
          email: resolvedEmail,
          phone: resolvedPhone,
        ),
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
      profileCompleted: _isProfileCompleted(
        name: name,
        email: email,
        phone: phone,
      ),
      trustScore: _buildTrustScore(name: name, email: email, phone: phone),
      createdAt: DateTime.now(),
    );

    await saveUser(newUser);
    return newUser;
  }

  Future<void> updateUser(AppUserModel user) async {
    final normalizedUser = AppUserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      createdAt: user.createdAt,
      profileCompleted: _isProfileCompleted(
        name: user.name,
        email: user.email,
        phone: user.phone,
      ),
      trustScore: _buildTrustScore(
        name: user.name,
        email: user.email,
        phone: user.phone,
      ),
      favoriteListingIds: user.favoriteListingIds,
    );

    await _usersCollection
        .doc(user.id)
        .set(normalizedUser.toMap(), SetOptions(merge: true));
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
      return removeFavorite(
        userId: userId,
        listingId: listingId,
      ).then((_) => false);
    }

    return addFavorite(userId: userId, listingId: listingId).then((_) => true);
  }

  bool _isProfileCompleted({
    required String name,
    required String email,
    required String phone,
  }) {
    return name.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        phone.trim().isNotEmpty;
  }

  int _buildTrustScore({
    required String name,
    required String email,
    required String phone,
  }) {
    return [
      if (name.trim().isNotEmpty) 1,
      if (email.trim().isNotEmpty) 1,
      if (phone.trim().isNotEmpty) 1,
    ].length;
  }
}
