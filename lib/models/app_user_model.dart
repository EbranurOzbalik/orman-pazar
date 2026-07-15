import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
    this.userMode = 'buyer_seller',
    this.profileCompleted = false,
    this.trustScore = 0,
    this.favoriteListingIds = const [],
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime createdAt;
  final String userMode;
  final bool profileCompleted;
  final int trustScore;
  final List<String> favoriteListingIds;

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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'userMode': userMode,
      'profileCompleted': profileCompleted,
      'trustScore': trustScore,
      'favoriteListingIds': favoriteListingIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUserModel.fromMap(String id, Map<String, dynamic> map) {
    return AppUserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      userMode: map['userMode'] as String? ?? 'buyer_seller',
      profileCompleted: map['profileCompleted'] as bool? ?? false,
      trustScore: _toInt(map['trustScore']),
      favoriteListingIds: _toStringList(map['favoriteListingIds']),
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
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

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return 0;
  }
}
