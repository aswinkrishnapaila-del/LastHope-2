import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String fullName;
  final String userPhone;

  const UserProfile({required this.fullName, required this.userPhone});

  bool get isEmpty => fullName.isEmpty && userPhone.isEmpty;

  static const UserProfile empty = UserProfile(fullName: '', userPhone: '');
}

class EmergencyContact {
  final String name;
  final String phone;

  const EmergencyContact({required this.name, required this.phone});
}

/// Central DatabaseService for user_profile and emergency contacts.
class DatabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      debugPrint('⚠️ DatabaseService: No authenticated user found.');
      return '00000000-0000-0000-0000-000000000000';
    }
    return id;
  }

  // ─────────────────────────────────────────────────────────────────
  //  USER PROFILE  (table: user_profile)
  // ─────────────────────────────────────────────────────────────────

  /// Save (upsert) the current user's name and phone to user_profile.
  Future<void> saveUserProfile(String name, String phone) async {
    try {
      await _client.from('user_profile').upsert({
        'id': _userId,
        'full_name': name.trim(),
        'user_phone': phone.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ DatabaseService: user_profile saved.');
    } catch (e) {
      debugPrint('❌ DatabaseService: Failed to save user_profile — $e');
      rethrow;
    }
  }

  /// Fetch the current user's profile. Returns [UserProfile.empty] on error.
  Future<UserProfile> getUserProfile() async {
    try {
      final data = await _client
          .from('user_profile')
          .select('full_name, user_phone')
          .eq('id', _userId)
          .maybeSingle();

      if (data != null) {
        return UserProfile(
          fullName: data['full_name'] as String? ?? '',
          userPhone: data['user_phone'] as String? ?? '',
        );
      }
      return UserProfile.empty;
    } catch (e) {
      debugPrint('❌ DatabaseService: Failed to fetch user_profile — $e');
      return UserProfile.empty;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  EMERGENCY CONTACTS  (table: contacts — existing schema)
  // ─────────────────────────────────────────────────────────────────

  /// Add a new emergency contact. Uses the existing `contacts` Supabase table.
  Future<void> addEmergencyContact(String name, String phone) async {
    try {
      await _client.from('contacts').insert({
        'user_id': _userId,
        'name': name.trim(),
        'phone_number': phone.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ DatabaseService: Emergency contact added.');
    } catch (e) {
      debugPrint('❌ DatabaseService: Failed to add contact — $e');
      rethrow;
    }
  }

  /// Fetch all emergency contacts for the current user.
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final data = await _client
          .from('contacts')
          .select('name, phone_number')
          .eq('user_id', _userId);

      return (data as List).map((row) {
        return EmergencyContact(
          name: row['name'] as String? ?? 'Unknown',
          phone: row['phone_number'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ DatabaseService: Failed to fetch contacts — $e');
      return [];
    }
  }

  /// Stream of emergency contacts (real-time via Supabase Realtime).
  Stream<List<EmergencyContact>> getEmergencyContactsStream() {
    return _client
        .from('contacts')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map((list) => list
            .map((row) => EmergencyContact(
                  name: row['name'] as String? ?? 'Unknown',
                  phone: row['phone_number'] as String? ?? '',
                ))
            .toList());
  }
}
