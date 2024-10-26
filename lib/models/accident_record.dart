import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AccidentReport {
  String? id;
  String? userId;
  DateTime? timestamp;
  String? location;
  int? passengerCount;
  String? vehicleNumber;
  String? driverName;
  String? driverLicenseNumber;
  String? accidentRemarks;
  List<String>? imageUrls;
  String? status;

  AccidentReport({
    this.id,
    this.userId,
    this.timestamp,
    this.location,
    this.passengerCount,
    this.vehicleNumber,
    this.driverName,
    this.driverLicenseNumber,
    this.accidentRemarks,
    this.imageUrls,
    this.status,
  });

  // Factory constructor to create an AccidentReport from a Firestore DocumentSnapshot
  factory AccidentReport.fromFirestore(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return AccidentReport(
      id: data['id'],
      userId: data['userId'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      location: data['location'],
      passengerCount: data['passengerCount'],
      vehicleNumber: data['vehicleNumber'],
      driverName: data['driverName'],
      driverLicenseNumber: data['driverLicenseNumber'],
      accidentRemarks: data['accidentRemarks'],
      imageUrls: List<String>.from(data['imageUrls']),
      status: data['status'],
    );
  }

  // Method to convert the AccidentReport to a Map for Firestore
  Map<String, dynamic> toMap() {
    if (id == null) {
      id = const Uuid().v4();
    }
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp,
      'location': location,
      'passengerCount': passengerCount,
      'vehicleNumber': vehicleNumber,
      'driverName': driverName,
      'driverLicenseNumber': driverLicenseNumber,
      'accidentRemarks': accidentRemarks,
      'imageUrls': imageUrls,
      'status': status,
    };
  }
}
