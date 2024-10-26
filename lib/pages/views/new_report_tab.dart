import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insurance_reporter/models/accident_record.dart';
import 'package:uuid/uuid.dart';

class NewReportTab extends StatefulWidget {
  const NewReportTab({Key? key}) : super(key: key);

  @override
  _NewReportTabState createState() => _NewReportTabState();
}

class _NewReportTabState extends State<NewReportTab> {
  late StreamSubscription<List<ConnectivityResult>> subscription;

  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _passengerCountController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverLicenseNumberController = TextEditingController();
  final _accidentRemarksController = TextEditingController();

  List<XFile?> _images = [];
  List<String> uploadedImageUrls = [];

  bool _isNetworkConnected = false;

  Future<void> _pickImage() async {
    if (_isNetworkConnected == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You are offline at the moment. You can create the report'
              ' without images now and upload them later when you are online.'),
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
      _images.add(pickedImage);
    });
  }

  Future<void> _submitReport() async {
    try {
      if (_formKey.currentState!.validate()) {
        EasyLoading.show(status: 'Submitting report...', dismissOnTap: false);

        final reportId = const Uuid().v4();
        final userId = FirebaseAuth.instance.currentUser!.uid;

        List<String> imageUrls = [];
        for (XFile? image in _images) {
          final storageRef = FirebaseStorage.instance.ref().child(
              'reports/$reportId/${DateTime.now().millisecondsSinceEpoch}');

          final File? file = File(image!.path);

          final uploadTask = storageRef.putFile(file!);

          try {
            await uploadTask.whenComplete(() async {
              final imageUrl = await storageRef.getDownloadURL();
              imageUrls.add(imageUrl);
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error uploading image')),
            );
            EasyLoading.dismiss();
          }
        }

        final report = AccidentReport(
          id: reportId,
          userId: userId,
          timestamp: DateTime.now(),
          location: _locationController.text,
          passengerCount: int.parse(_passengerCountController.text),
          vehicleNumber: _vehicleNumberController.text,
          driverName: _driverNameController.text,
          driverLicenseNumber: _driverLicenseNumberController.text,
          accidentRemarks: _accidentRemarksController.text,
          imageUrls: imageUrls,
          status: 'Pending',
        );

        final firebaseDB = FirebaseFirestore.instance;
        firebaseDB.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );

        if (!_isNetworkConnected) {
          firebaseDB.collection('reports').doc(reportId).set(report.toMap());
        } else {
          await firebaseDB
              .collection('reports')
              .doc(reportId)
              .set(report.toMap());
        }

        _locationController.clear();
        _passengerCountController.clear();
        _vehicleNumberController.clear();
        _driverNameController.clear();
        _driverLicenseNumberController.clear();
        _accidentRemarksController.clear();

        setState(() {
          _images.clear();
          uploadedImageUrls.clear();
        });

        EasyLoading.dismiss();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error submitting report. Please try again later. ${e}'),
        ),
      );
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
          FirebaseFirestore.instance.disableNetwork();
        });
      } else if (result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi)) {
        setState(() {
          _isNetworkConnected = true;
          FirebaseFirestore.instance.enableNetwork();
        });
      } else {
        setState(() {
          _isNetworkConnected = false;
          FirebaseFirestore.instance.disableNetwork();
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passengerCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Passenger Count',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter passenger count' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter vehicle number' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _driverNameController,
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter driver name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _driverLicenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Driver License Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty
                    ? 'Please enter driver license number'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _accidentRemarksController,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Accident Remarks',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter accident remarks' : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Select and upload images of your accident"),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _pickImage,
                    iconSize: 18,
                    icon: const Icon(Icons.add_a_photo_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 4,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  if (_images[index] == null) {
                    return const SizedBox.shrink();
                  } else {
                    return Image.file(File(_images[index]!.path));
                  }
                },
              ),
              const SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _submitReport,
                    child: const Text('Submit Report'),
                  ),
                  TextButton(
                    onPressed: () {
                      _formKey.currentState!.reset();
                      setState(() {
                        _images.clear();
                        uploadedImageUrls.clear();
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
