import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'sms_service.dart';
import 'package:latlong2/latlong.dart';
import '../providers/app_state_provider.dart';
import '../../features/contacts/data/contact_model.dart';
import '../../features/medical/data/medical_info_model.dart';
import 'hardware_alert_service.dart';

/// Holds everything the ActiveEmergencyScreen needs to render instantly.
class RescueResult {
  final double lat;
  final double lng;
  final LatLng location;
  final List<Contact> contacts;
  final MedicalInfo medicalInfo;
  final String userName;
  final String userPhone;
  final bool smsSent;

  RescueResult({
    required this.lat,
    required this.lng,
    required this.contacts,
    required this.medicalInfo,
    required this.userName,
    required this.userPhone,
    required this.smsSent,
  }) : location = LatLng(lat, lng);
}

/// Self-contained rescue service. Uses cached [AppStateProvider] so it never
/// waits for a Supabase round-trip during the emergency trigger.
class StaticRescueService {

  final AppStateProvider _state;

  StaticRescueService(this._state);

  /// Execute the full rescue sequence. Returns a [RescueResult] for the
  /// ActiveEmergencyScreen to display immediately.
  Future<RescueResult> trigger({String? reason}) async {
    debugPrint('🚨 StaticRescueService: trigger() called');

    // ── 1. Location ────────────────────────────────────────────────
    double lat = 0.0;
    double lng = 0.0;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      ).timeout(const Duration(seconds: 10));
      lat = position.latitude;
      lng = position.longitude;
      debugPrint('📍 Location: $lat, $lng');
    } catch (e) {
      debugPrint('⚠️ Location failed (using 0,0): $e');
    }

    final locationUrl =
        'https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

    // ── 2. Profile & Contacts from cache ──────────────────────────
    final nameStr = _state.displayName;
    final phoneStr = _state.userPhone.isNotEmpty ? _state.userPhone : 'N/A';
    final contacts = _state.emergencyContacts;
    final medicalInfo = _state.medicalInfo;

    // Build the medical string
    String medStr = "";
    if (medicalInfo.bloodType.isNotEmpty) medStr += "Blood: ${medicalInfo.bloodType}. ";
    if (medicalInfo.allergies.isNotEmpty) medStr += "Allergies: ${medicalInfo.allergies}. ";
    if (medicalInfo.medications.isNotEmpty) medStr += "Meds: ${medicalInfo.medications}. ";
    if (medicalInfo.medicalConditions.isNotEmpty) medStr += "Conditions: ${medicalInfo.medicalConditions}. ";
    if (medStr.isEmpty) medStr = "None provided.";

    final sosReason = reason ?? 'SOS Manually Clicked';

    // ── 3. Format SMS ──────────────────────────────────────────────
    final message =
        '[$sosReason]\n'
        'I need immediate assistance!\n'
        'I am $nameStr (Ph: $phoneStr).\n'
        'Live Loc: $locationUrl\n'
        'Medical: $medStr';
    debugPrint('📩 SMS: $message');

    // ── 4. Send SMS to ALL contacts ────────────────────────────────
    bool smsSent = false;
    final phoneNumbers = contacts.where((c) => c.phoneNumber.isNotEmpty).map((c) => c.phoneNumber).toList();
    if (phoneNumbers.isNotEmpty) {
      try {
        await sendSMS(message: message, recipients: phoneNumbers);
        smsSent = true;
      } catch (e) {
        debugPrint('❌ SMS failed: $e');
      }
    }

    HardwareAlertService().startAlert();

    // ── 5. Direct-call starred or first contact ──────────────────────────────
    if (contacts.isNotEmpty) {
      final starredContact = contacts.firstWhere(
        (c) => c.id == _state.starredContactId, 
        orElse: () => contacts.first,
      );
      
      if (starredContact.phoneNumber.isNotEmpty) {
        final phone = starredContact.phoneNumber;
        debugPrint('📞 Dialling ${starredContact.name} ($phone)');
        try {
          await autoDial(phone);
        } catch (e) {
          debugPrint('❌ Direct call failed: $e');
        }
      }
    }

    return RescueResult(
      lat: lat,
      lng: lng,
      contacts: contacts,
      medicalInfo: medicalInfo,
      userName: nameStr,
      userPhone: phoneStr,
      smsSent: smsSent,
    );
  }
}
