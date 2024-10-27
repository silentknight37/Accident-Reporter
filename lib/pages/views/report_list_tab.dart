import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:insurance_reporter/components/report_list_item.dart';
import 'package:insurance_reporter/models/accident_record.dart';

class ReportListTab extends StatefulWidget {
  const ReportListTab({Key? key}) : super(key: key);

  @override
  _ReportListTabState createState() => _ReportListTabState();
}

class _ReportListTabState extends State<ReportListTab> {
  Stream<QuerySnapshot>? _reportsStream;

  @override
  void initState() {
    super.initState();
    final firebaseDB = FirebaseFirestore.instance;
    firebaseDB.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _reportsStream = firebaseDB
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _reportsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs
            .map((doc) => AccidentReport.fromFirestore(doc))
            .toList();

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            return ReportListItem(report: reports[index]);
          },
        );
      },
    );
  }
}
