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

  // Yeni kayıt olan kullanıcıyı `users/{uid}` dokümanı olarak saklar.
  // set kullanıyoruz; aynı uid ile tekrar çağrılırsa doküman güvenli şekilde güncellenir.
  Future<void> saveUser(AppUserModel user) async {
    await _usersCollection.doc(user.id).set(user.toMap());
  }

  // İleride profil ekranı için tek kullanıcı dokümanını okumamız gerekebilir.
  Future<AppUserModel?> getUserById(String id) async {
    final doc = await _usersCollection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return AppUserModel.fromMap(doc.id, doc.data()!);
  }
}
