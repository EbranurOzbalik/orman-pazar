import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/report_model.dart';

class ReportService {
  ReportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reportsCollection {
    return _firestore.collection(AppConstants.reportsCollection);
  }

  // Yeni raporu `reports` koleksiyonuna ekler.
  Future<void> addReport(ReportModel report) async {
    await _reportsCollection.add(report.toMap());
  }

  Future<ReportModel?> getUserReportForListing({
    required String listingId,
    required String reporterId,
  }) async {
    final snapshot = await _reportsCollection
        .where('listingId', isEqualTo: listingId)
        .where('reporterId', isEqualTo: reporterId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return ReportModel.fromMap(doc.id, doc.data());
  }

  Stream<ReportModel?> watchUserReportForListing({
    required String listingId,
    required String reporterId,
  }) {
    return _reportsCollection
        .where('listingId', isEqualTo: listingId)
        .where('reporterId', isEqualTo: reporterId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final doc = snapshot.docs.first;
          return ReportModel.fromMap(doc.id, doc.data());
        });
  }
}
