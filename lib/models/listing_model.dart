import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  const ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.woodType,
    required this.amount,
    required this.unit,
    required this.price,
    required this.city,
    required this.district,
    required this.moistureStatus,
    required this.hasDelivery,
    required this.phone,
    required this.sellerId,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String woodType;
  final double amount;
  final String unit;
  final double price;
  final String city;
  final String district;
  final String moistureStatus;
  final bool hasDelivery;
  final String phone;
  final String sellerId;
  final DateTime createdAt;

  // Firestore'a yazılacak sade Map yapısı. id alanını belge id'si olarak
  // tuttuğumuz için map içine eklemiyoruz.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'woodType': woodType,
      'amount': amount,
      'unit': unit,
      'price': price,
      'city': city,
      'district': district,
      'moistureStatus': moistureStatus,
      'hasDelivery': hasDelivery,
      'phone': phone,
      'sellerId': sellerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Firestore belge id'si data map'in içinde gelmez. Bu yüzden document.id
  // servis katmanından buraya ayrıca gönderilir.
  factory ListingModel.fromMap(String id, Map<String, dynamic> map) {
    return ListingModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      woodType: map['woodType'] as String? ?? '',
      amount: _toDouble(map['amount']),
      unit: map['unit'] as String? ?? '',
      price: _toDouble(map['price']),
      city: map['city'] as String? ?? '',
      district: map['district'] as String? ?? '',
      moistureStatus: map['moistureStatus'] as String? ?? '',
      hasDelivery: map['hasDelivery'] as bool? ?? false,
      phone: map['phone'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
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
