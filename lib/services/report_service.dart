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
}
