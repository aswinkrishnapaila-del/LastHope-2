import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'medical_info_model.dart';

class MedicalService {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      debugPrint("⚠️ Warning: No authenticated user found for MedicalService");
      return '00000000-0000-0000-0000-000000000000';
    }
    return id;
  }

  // SAVE (upsert — insert or update)
  Future<void> saveMedicalInfo(MedicalInfo info) async {
    try {
      await _client.from('medical_info').upsert({
        'id': _userId,
        'name': info.name,
        'age': info.age,
        'blood_type': info.bloodType,
        'allergies': info.allergies,
        'medications': info.medications,
        'medical_conditions': info.medicalConditions,
        'organ_donor': info.organDonor,
        'insurance_provider': info.insuranceProvider,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint("✅ Medical info saved to Supabase");
    } catch (e) {
      debugPrint("❌ Failed to save medical info: $e");
      rethrow;
    }
  }

  // GET (fetch single row by user ID)
  Future<MedicalInfo> getMedicalInfo() async {
    try {
      final data = await _client
          .from('medical_info')
          .select()
          .eq('id', _userId)
          .maybeSingle();

      if (data != null) {
        return MedicalInfo(
          name: data['name'] ?? '',
          age: data['age'] ?? '',
          bloodType: data['blood_type'] ?? 'Unknown',
          allergies: data['allergies'] ?? 'None',
          medications: data['medications'] ?? 'None',
          medicalConditions: data['medical_conditions'] ?? 'None',
          organDonor: data['organ_donor'] ?? false,
          insuranceProvider: data['insurance_provider'] ?? 'None',
        );
      }
      return MedicalInfo.empty();
    } catch (e) {
      debugPrint("❌ Failed to fetch medical info: $e");
      return MedicalInfo.empty();
    }
  }

  // STREAM for Real-time UI (Supabase Realtime)
  Stream<MedicalInfo> getMedicalInfoStream() {
    return _client
        .from('medical_info')
        .stream(primaryKey: ['id'])
        .eq('id', _userId)
        .map((list) {
          if (list.isNotEmpty) {
            final data = list.first;
            return MedicalInfo(
              name: data['name'] ?? '',
              age: data['age'] ?? '',
              bloodType: data['blood_type'] ?? 'Unknown',
              allergies: data['allergies'] ?? 'None',
              medications: data['medications'] ?? 'None',
              medicalConditions: data['medical_conditions'] ?? 'None',
              organDonor: data['organ_donor'] ?? false,
              insuranceProvider: data['insurance_provider'] ?? 'None',
            );
          }
          return MedicalInfo.empty();
        });
  }
}
