import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/medical/data/medical_service.dart';
import '../../features/contacts/data/contact_service.dart';
import '../../dependency_injection.dart'; 

class CloudRescueService {
  Future<void> triggerCloudSOS() async {
    try {
      // 1. Get Location
      Position? position;
      try {
        const LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.best,
        );
        position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
      } catch (e) {
        debugPrint("CloudSOS Location Error: $e");
      }
      
      final double lat = position?.latitude ?? 0.0;
      final double lng = position?.longitude ?? 0.0;

      // 2. Get Data
      final MedicalService medicalService = sl<MedicalService>();
      final ContactService contactService = sl<ContactService>();
      
      final medicalInfo = await medicalService.getMedicalInfo();
      final contacts = await contactService.getContacts().first;

      String medicalDetails = medicalInfo.bloodType.isNotEmpty 
          ? "Blood: ${medicalInfo.bloodType}. " 
          : "Blood: Unknown. ";
      
      if (medicalInfo.allergies.isNotEmpty && medicalInfo.allergies != "None") {
        medicalDetails += "Allergies: ${medicalInfo.allergies}. ";
      }
      if (medicalInfo.medicalConditions.isNotEmpty && medicalInfo.medicalConditions != "None") {
        medicalDetails += "Conditions: ${medicalInfo.medicalConditions}.";
      }

      List<String> recipients = contacts.map((c) => c.phoneNumber).toList();
      final name = medicalInfo.name.isNotEmpty ? medicalInfo.name : "User";

      // 3. Format Payload
      final payload = {
        "user_name": name,
        "latitude": lat,
        "longitude": lng,
        "medical_info": medicalDetails.trim(),
        "contacts": recipients,
      };

      // 4. Send POST Request
      final String apiUrl = 'https://lasthope-production-76b5.up.railway.app/api/v1/sos-trigger';

      debugPrint("Extracted Cloud Backup Logic Executing -> Triggering SOS at $apiUrl");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint("Cloud SOS Response: ${response.statusCode} - ${response.body}");
    } catch (e) {
      debugPrint("Cloud SOS Failed: $e");
    }
  }
}
