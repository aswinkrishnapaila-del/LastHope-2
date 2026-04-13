import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../../features/medical/data/medical_info_model.dart';
import '../../features/medical/data/medical_service.dart';
import '../../features/contacts/data/contact_model.dart';
import '../../features/contacts/data/contact_service.dart';

/// Global in-memory cache and Offline-First Storage for the user's profile, contacts, and medical info.
/// Data is read/written to SharedPreferences instantly, and synced to Supabase asynchronously.
class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db;
  final MedicalService _medical;
  final ContactService _contacts;

  SharedPreferences? _prefs;

  // ── Cached state ──────────────────────────────────────────────────────
  UserProfile _profile = UserProfile.empty;
  String _profilePhotoPath = '';
  MedicalInfo _medicalInfo = MedicalInfo.empty();
  List<Contact> _emergencyContacts = [];
  String? _starredContactId;
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────
  UserProfile get profile => _profile;
  String get profilePhotoPath => _profilePhotoPath;
  MedicalInfo get medicalInfo => _medicalInfo;
  List<Contact> get emergencyContacts => _emergencyContacts;
  String? get starredContactId => _starredContactId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Friendly display name (falls back to 'User').
  String get displayName =>
      _profile.fullName.isNotEmpty ? _profile.fullName : _medicalInfo.name.isNotEmpty ? _medicalInfo.name : 'User';

  /// User's own phone number.
  String get userPhone => _profile.userPhone;

  AppStateProvider({
    required DatabaseService db,
    required MedicalService medical,
    required ContactService contacts,
  })  : _db = db,
        _medical = medical,
        _contacts = contacts;

  // ── Load all data at startup ──────────────────────────────────────────
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadLocally();
      // Don't await the network load so UI starts instantly
      _syncFromNetwork();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ AppStateProvider.init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Offline First Reads ───────────────────────────────────────────────
  void _loadLocally() {
    if (_prefs == null) return;
    
    // Profile
    final name = _prefs!.getString('profile_name') ?? '';
    final phone = _prefs!.getString('profile_phone') ?? '';
    _profile = UserProfile(fullName: name, userPhone: phone);
    _profilePhotoPath = _prefs!.getString('profile_photo') ?? '';

    // Medical
    final medJson = _prefs!.getString('medical_info');
    if (medJson != null && medJson.isNotEmpty) {
      try {
        _medicalInfo = MedicalInfo.fromMap(jsonDecode(medJson));
      } catch (e) {
        debugPrint('Failed to parse local medical info: $e');
      }
    }

    // Contacts
    final contactsJson = _prefs!.getString('contacts');
    if (contactsJson != null && contactsJson.isNotEmpty) {
      try {
        final List list = jsonDecode(contactsJson);
        _emergencyContacts = list.map((c) => Contact(
          id: c['id'] ?? '',
          name: c['name'] ?? '',
          phoneNumber: c['phoneNumber'] ?? '',
        )).toList();
      } catch (e) {
        debugPrint('Failed to parse local contacts: $e');
      }
    }
    
    // Starred Contact ID
    _starredContactId = _prefs!.getString('starred_contact_id');
  }

  // ── Sync from Supabase in Background ────────────────────────────────
  Future<void> _syncFromNetwork() async {
    try {
      final netProfile = await _db.getUserProfile();
      if (!netProfile.isEmpty) {
        _profile = netProfile;
        _prefs?.setString('profile_name', netProfile.fullName);
        _prefs?.setString('profile_phone', netProfile.userPhone);
      }

      final netMed = await _medical.getMedicalInfo();
      if (netMed.name.isNotEmpty) {
        _medicalInfo = netMed;
        _prefs?.setString('medical_info', jsonEncode(netMed.toMap()));
      }

      await for (final netContacts in _contacts.getContacts()) {
        if (netContacts.isNotEmpty) {
           _emergencyContacts = netContacts;
           final String encoded = jsonEncode(netContacts.map((c) => c.toMap()).toList());
           _prefs?.setString('contacts', encoded);
           notifyListeners();
        }
        break; // Only take the first chunk
      }
      
      notifyListeners();
    } catch (e) {
       debugPrint('⚠️ Sync from network failed: $e (This is expected if offline or unauthenticated)');
    }
  }

  // ── Offline First Writes ─────────────────────────────────────────────

  Future<void> saveProfile(String name, String phone, {String? photoPath}) async {
    _profile = UserProfile(fullName: name, userPhone: phone);
    _prefs?.setString('profile_name', name);
    _prefs?.setString('profile_phone', phone);
    
    if (photoPath != null) {
      _profilePhotoPath = photoPath;
      _prefs?.setString('profile_photo', photoPath);
    }
    
    notifyListeners();
    
    // Async save to network
    try {
      await _db.saveUserProfile(name, phone);
    } catch (e) {
      debugPrint('⚠️ Network save failed: $e. Handled locally.');
    }
  }

  Future<void> saveMedical(MedicalInfo info) async {
    _medicalInfo = info;
    _prefs?.setString('medical_info', jsonEncode(info.toMap()));
    notifyListeners();

    // Async save to network
    try {
      await _medical.saveMedicalInfo(info);
    } catch (e) {
      debugPrint('⚠️ Network save failed: $e. Handled locally.');
    }
  }

  Future<void> addContact(String name, String phone) async {
    // Generate temporary ID
    final String tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final newContact = Contact(id: tempId, name: name, phoneNumber: phone);
    
    _emergencyContacts.add(newContact);
    _prefs?.setString('contacts', jsonEncode(_emergencyContacts.map((c) => c.toMap()).toList()));
    notifyListeners();

    // Async save to network
    try {
      await _contacts.addContact(name, phone);
      // Let it refresh logic
      _syncFromNetwork();
    } catch (e) {
      debugPrint('⚠️ Network save failed: $e. Handled locally.');
    }
  }

  Future<void> deleteContact(String id) async {
    _emergencyContacts.removeWhere((c) => c.id == id);
    _prefs?.setString('contacts', jsonEncode(_emergencyContacts.map((c) => c.toMap()).toList()));
    notifyListeners();

    // Async save to network
    try {
      await _contacts.deleteContact(id);
      _syncFromNetwork();
    } catch (e) {
      debugPrint('⚠️ Network delete failed: $e. Handled locally.');
    }
  }

  Future<void> setStarredContactId(String id) async {
    _starredContactId = id;
    _prefs?.setString('starred_contact_id', id);
    notifyListeners();
  }

  /// These remain for backward compatibility or direct network refresh requests.
  Future<void> refreshProfile() async => _syncFromNetwork();
  Future<void> refreshMedical() async => _syncFromNetwork();
  Future<void> refreshContacts() async => _syncFromNetwork();
}
