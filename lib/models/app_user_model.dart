import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime createdAt;

  String get displayName {
    if (name.trim().isNotEmpty) {
      return name.trim();
    }

    final emailPrefix = email.split('@').first.trim();
    if (emailPrefix.isNotEmpty) {
      return emailPrefix;
    }

    return 'Kullanici';
  }

  // Firestore'da belge id'si olarak Firebase Auth uid kullanıyoruz.
  // Bu yüzden uid map içine ayrıca yazılmıyor.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Firestore document id, Auth uid ile aynı olduğu için modele id olarak gelir.
  factory AppUserModel.fromMap(String id, Map<String, dynamic> map) {
    return AppUserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
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
