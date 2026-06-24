import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  final String id;
  final String email;
  final DateTime createdAt;

  // Firestore'da belge id'si olarak Firebase Auth uid kullanıyoruz.
  // Bu yüzden uid map içine ayrıca yazılmıyor.
  Map<String, dynamic> toMap() {
    return {'email': email, 'createdAt': Timestamp.fromDate(createdAt)};
  }

  // Firestore document id, Auth uid ile aynı olduğu için modele id olarak gelir.
  factory AppUserModel.fromMap(String id, Map<String, dynamic> map) {
    return AppUserModel(
      id: id,
      email: map['email'] as String? ?? '',
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }
}
