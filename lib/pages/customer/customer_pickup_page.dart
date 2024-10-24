import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Booking {
  final String serviceType;
  final String date;
  final String status;
  final String pickupAddress;
  final String preferredDate;
  final String specialInstruction;

  Booking({
    required this.serviceType,
    required this.date,
    required this.status,
    required this.pickupAddress,
    required this.preferredDate,
    required this.specialInstruction,
  });
}

class CustomerPickupPage extends StatefulWidget {
  final String requestId;
  const CustomerPickupPage({super.key, required this.requestId});

  @override
  State<CustomerPickupPage> createState() => _CustomerPickupPageState();
}

class _CustomerPickupPageState extends State<CustomerPickupPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupAddressController = TextEditingController();
  final _specialInstructionController = TextEditingController();
  DateTime? _preferredDate;


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_preferredDate == null) {
        _showSnackBar('Please select a preferred date.');
      } else {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing the dialog
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        final formattedPreferredDate = DateFormat('yyyy-MM-dd').format(_preferredDate!);
        final pickupId = generatePickupId();

        // Creating a Booking instance
        final booking = Booking(
          serviceType: "Pickup",
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          status: "Scheduled for Pickup",
          pickupAddress: _pickupAddressController.text,
          preferredDate: formattedPreferredDate,
          specialInstruction: _specialInstructionController.text,
        );

        try {
          // Saving to Firestore
          await FirebaseFirestore.instance.collection('pickups').add({
            'pickupId': pickupId,
            'serviceType': booking.serviceType,
            'pickup_date': booking.date,
            'status': booking.status,
            'pickupAddress': booking.pickupAddress,
            'preferredDate': booking.preferredDate,
            'specialInstruction': booking.specialInstruction,
            'createdAt': Timestamp.now(),
            'repairId': widget.requestId,
          });

          // Update the status of the repair request
          await updateRepairRequestStatus(widget.requestId);

          // Dismiss the loading dialog and show success dialog
          Navigator.of(context).pop();
          _showDialog();
        } catch (error) {
          // Handle Firestore errors
          Navigator.of(context).pop();
          _showSnackBar('Error scheduling pickup: $error');
        }
      }
    }
  }

  Future<void> updateRepairRequestStatus(String repairRequestId) async {
    try {
      // Get a reference to the repair_request collection
      CollectionReference repairRequests = FirebaseFirestore.instance.collection('repair_request');

      // Update the status to 'scheduled for pickup'
      await repairRequests.doc(repairRequestId).update({
        'status': 'Scheduled for pickup',
      });

      print("Repair request status updated to 'scheduled for pickup'");
    } catch (e) {
      // Handle errors (e.g., show an error message)
      print("Error updating repair request status: $e");
    }
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600]),
              const SizedBox(width: 10),
              Text(
                'Pickup Scheduled',
                style: TextStyle(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  fontFamily: "Mont",
                ),
              ),
            ],
          ),
          content: Text(
            'Your pickup has been scheduled successfully.',
            style: TextStyle(color: Colors.grey[800], fontSize: 18, fontFamily: "Nunito"),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue[900],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Nunito",
                ),
              ),
              onPressed: () => Navigator.popAndPushNamed(context, 'repair_status_page'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
        ),
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[100]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              _buildBackButton(),
              const SizedBox(height: 40),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        label: const Text(
          "Back",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: "Mont"),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            "Schedule Pickup",
            style: TextStyle(
              color: Colors.blue[900]!,
              fontWeight: FontWeight.bold,
              fontSize: 30,
              fontFamily: "june",
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(_pickupAddressController, 'Pickup Address', Icons.location_on, 2),
          const SizedBox(height: 16),
          _buildDateAndTimeButtons(),
          const SizedBox(height: 16),
          _buildTextField(_specialInstructionController, 'Special Instruction(optional)', null, 4, isOptional: true),
          const SizedBox(height: 16),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData? icon, int maxLines,{bool isOptional = false}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextFormField(
            style: const TextStyle(
              color: Colors.white,
            ),
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon) : null,
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
              fillColor: Colors.grey,
              filled: true,
            ),
            validator: (value) {
              if (!isOptional && (value == null || value.isEmpty)) {
                return 'Please enter $label';
              }
              return null; // No validation error
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateAndTimeButtons() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2025),
          );
          setState(() {
            _preferredDate = pickedDate;
          });
        },
        style: _elevatedButtonStyle(),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _preferredDate == null ? 'Preferred Date' : DateFormat('yyyy-MM-dd').format(_preferredDate!),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: "Nunito"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 50,
      constraints: const BoxConstraints(maxWidth: 800),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: _elevatedButtonStyle(),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 10),
            Text(
              "Submit",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: "Nunito", color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  generatePickupId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNumber = (1000 + Random().nextInt(9000)).toString();
    return 'PICKUP_$timestamp$randomNumber';
  }
}