import 'package:flutter/material.dart';
import 'package:insurance_reporter/pages/report_details_page.dart';

import '../models/accident_record.dart';

class ReportListItem extends StatelessWidget {
  final AccidentReport report;

  const ReportListItem({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title:
          Text("${report.location} with ${report.passengerCount} passengers"),
      subtitle: Text(
          "On ${(report.timestamp.toString())} by driver ${report.driverName}"),
      trailing: Text(
        report.status!,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: report.status == 'Pending'
              ? Colors.orange
              : report.status == 'Approved'
                  ? Colors.green
                  : Colors.red,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailsPage(report: report),
          ),
        );
      },
    );
  }
}
