import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';

import '../models/accident_record.dart';

class ReportDetailsPage extends StatefulWidget {
  final AccidentReport report;

  const ReportDetailsPage({Key? key, required this.report}) : super(key: key);

  @override
  _ReportDetailsPageState createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  late StreamSubscription<List<ConnectivityResult>> subscription;

  XFile? _selectedImage;

  bool _isNetworkConnected = false;

  Future<void> _pickImage() async {
    if (!_isNetworkConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You are offline at the moment. You can upload images when you are online.'),
        ),
      );
      return;
    }

    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _selectedImage = pickedImage;
    });

    await _uploadImage();
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      return;
    }

    EasyLoading.show(status: 'Uploading image...', dismissOnTap: false);

    final storageRef = FirebaseStorage.instance.ref().child(
        'reports/${widget.report.id}/${DateTime.now().millisecondsSinceEpoch}');
    final file = File(_selectedImage!.path);
    final uploadTask = storageRef.putFile(file);

    try {
      await uploadTask.whenComplete(() async {
        final imageUrl = await storageRef.getDownloadURL();
        FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.report.id)
            .update({
          'imageUrls': FieldValue.arrayUnion([imageUrl])
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
        setState(() {
          widget.report.imageUrls!.add(imageUrl);
        });
      });
      EasyLoading.dismiss();
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image')),
      );
      EasyLoading.dismiss();
    }
  }

  @override
  void initState() {
    super.initState();
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (result.contains(ConnectivityResult.none)) {
        setState(() {
          _isNetworkConnected = false;
        });
      } else if (result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi)) {
        setState(() {
          _isNetworkConnected = true;
        });
      } else {
        setState(() {
          _isNetworkConnected = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          if (widget.report.status == 'Pending')
            IconButton(
              icon: const Icon(Icons.highlight_remove_rounded),
              onPressed: _removeReport,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report ID: ${widget.report.id}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Status: ${widget.report.status}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.report.status == 'Pending'
                      ? Colors.orange
                      : widget.report.status == 'Approved'
                          ? Colors.green
                          : Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Location: ${widget.report.location}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text('Passenger Count: ${widget.report.passengerCount}'),
              const SizedBox(height: 10),
              Text('Vehicle Number: ${widget.report.vehicleNumber}'),
              const SizedBox(height: 10),
              Text('Driver Name: ${widget.report.driverName}'),
              const SizedBox(height: 10),
              Text(
                  'Driver License Number: ${widget.report.driverLicenseNumber}'),
              const SizedBox(height: 10),
              Text('Accident Remarks: ${widget.report.accidentRemarks}'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: widget.report.imageUrls?.length,
                itemBuilder: (context, index) {
                  return Image.network(widget.report.imageUrls![index]);
                },
              ),
              if (widget.report.status == 'Pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo_rounded),
                      label: const Text('Upload New Image'),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _removeReport() {
    FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.report.id)
        .delete();
    Navigator.pop(context);
  }
}
