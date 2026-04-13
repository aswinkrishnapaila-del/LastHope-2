import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'contact_model.dart';

class ContactService {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      debugPrint("⚠️ Warning: No authenticated user found for ContactService");
      // Return a dummy UUID-like string if absolutely necessary for anonymous access, 
      // but ideally we should wait for auth.
      return '00000000-0000-0000-0000-000000000000'; 
    }
    return id;
  }

  // STREAM: Get Contacts Real-time
  Stream<List<Contact>> getContacts() {
    return _client
        .from('contacts')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map((list) {
          return list.map((data) {
            return Contact(
              id: data['id'].toString(),
              name: data['name'] ?? '',
              phoneNumber: data['phone_number'] ?? '',
            );
          }).toList();
        });
  }

  // ADD
  Future<void> addContact(String name, String phoneNumber) async {
    try {
      await _client.from('contacts').insert({
        'user_id': _userId,
        'name': name,
        'phone_number': phoneNumber,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint("✅ Contact added to Supabase");
    } catch (e) {
      debugPrint("❌ Failed to add contact: $e");
      rethrow;
    }
  }

  // DELETE
  Future<void> deleteContact(String contactId) async {
    try {
      await _client.from('contacts').delete().eq('id', contactId);
      debugPrint("✅ Contact deleted from Supabase");
    } catch (e) {
      debugPrint("❌ Failed to delete contact: $e");
      rethrow;
    }
  }
}
