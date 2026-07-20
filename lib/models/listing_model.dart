import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

class ListingModel {
  const ListingModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrls = const [],
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
    required this.sellerName,
    required this.status,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final List<String> imageUrls;
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
  final String sellerName;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  ListingModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? imageUrls,
    String? category,
    String? woodType,
    double? amount,
    String? unit,
    double? price,
    String? city,
    String? district,
    String? moistureStatus,
    bool? hasDelivery,
    String? phone,
    String? sellerId,
    String? sellerName,
    String? status,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return ListingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      woodType: woodType ?? this.woodType,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      city: city ?? this.city,
      district: district ?? this.district,
      moistureStatus: moistureStatus ?? this.moistureStatus,
      hasDelivery: hasDelivery ?? this.hasDelivery,
      phone: phone ?? this.phone,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
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
      'sellerName': sellerName,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ListingModel.fromMap(String id, Map<String, dynamic> map) {
    return ListingModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrls: _toStringList(map['imageUrls']),
      category: _normalizeCategory(map['category'] as String?),
      woodType: _normalizeWoodType(map['woodType'] as String?),
      amount: _toDouble(map['amount']),
      unit: _normalizeUnit(map['unit'] as String?),
      price: _toDouble(map['price']),
      city: map['city'] as String? ?? '',
      district: map['district'] as String? ?? '',
      moistureStatus: _normalizeMoistureStatus(
        map['moistureStatus'] as String?,
      ),
      hasDelivery: map['hasDelivery'] as bool? ?? false,
      phone: map['phone'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? '',
      status: _normalizeStatus(map['status'] as String?),
      latitude: _toNullableDouble(map['latitude']),
      longitude: _toNullableDouble(map['longitude']),
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  static String _normalizeStatus(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.activeStatus;
    }

    final normalized = value.trim().toLowerCase();
    if (normalized == AppConstants.reservedStatus.toLowerCase()) {
      return AppConstants.reservedStatus;
    }
    if (normalized == AppConstants.soldStatus.toLowerCase()) {
      return AppConstants.soldStatus;
    }
    return AppConstants.activeStatus;
  }

  static String _normalizeCategory(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'yakacak odun':
        return 'Yakacak Odun';
      case 'kereste':
        return 'Kereste';
      case 'tomruk':
        return 'Tomruk';
      case 'talaş':
      case 'talas':
        return 'Talas';
      case 'diğer':
      case 'diger':
        return 'Diger';
      default:
        return value?.trim().isNotEmpty == true ? value!.trim() : 'Diger';
    }
  }

  static String _normalizeWoodType(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'meşe':
      case 'mese':
        return 'Mese';
      case 'çam':
      case 'cam':
        return 'Cam';
      case 'gürgen':
      case 'gurgen':
        return 'Gurgen';
      case 'kayın':
      case 'kayin':
        return 'Kayin';
      case 'diğer':
      case 'diger':
        return 'Diger';
      default:
        return value?.trim().isNotEmpty == true ? value!.trim() : 'Diger';
    }
  }

  static String _normalizeUnit(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'm³':
      case 'm3':
        return 'm3';
      case 'çuval':
      case 'cuval':
        return 'cuval';
      default:
        return value?.trim().isNotEmpty == true ? value!.trim() : 'kg';
    }
  }

  static String _normalizeMoistureStatus(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'yaş':
      case 'yas':
        return 'Yas';
      case 'karışık':
      case 'karisik':
        return 'Karisik';
      case 'kuru':
        return 'Kuru';
      default:
        return value?.trim().isNotEmpty == true ? value!.trim() : 'Kuru';
    }
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

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
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
}
