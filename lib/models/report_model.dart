import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.sellerId,
    required this.reporterId,
    required this.reason,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String sellerId;
  final String reporterId;
  final String reason;
  final String note;
  final String status;
  final DateTime createdAt;

  // Firestore'a yazilacak sade rapor haritasini olusturur.
  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'sellerId': sellerId,
      'reporterId': reporterId,
      'reason': reason,
      'note': note,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Firestore dokumanini uygulama icindeki ReportModel'e cevirir.
  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      listingId: map['listingId'] as String? ?? '',
      listingTitle: map['listingTitle'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      note: map['note'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
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
