import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../contacts/presentation/pages/contacts_screen.dart';
import '../../../medical/presentation/pages/medical_screen.dart';
import '../../../emergency/presentation/bloc/emergency_bloc.dart';
import '../../../emergency/presentation/bloc/emergency_event.dart';
import '../../../emergency/presentation/bloc/emergency_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // We'll use a local state for the "Background Protection" switch for now,
  // effectively mocking it as "Always On" or allowing toggle if we had a service manager.
  bool _backgroundProtection = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Safety Profile',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppConstants.backgroundBlack,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle("Emergency Contacts"),
            const SizedBox(height: 8),
            _buildContactsSection(context),
            const SizedBox(height: 24),
            _buildSectionTitle("Medical Info"),
            const SizedBox(height: 8),
            _buildMedicalSection(context),
            const SizedBox(height: 24),
            _buildSectionTitle("App Preferences"),
            const SizedBox(height: 8),
            _buildPreferencesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppConstants.primaryRed,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        final name = appState.displayName;
        final phone = appState.userPhone.isNotEmpty
            ? appState.userPhone
            : 'No phone saved';
        final blood = appState.medicalInfo.bloodType.isNotEmpty
            ? appState.medicalInfo.bloodType
            : '--';

        return Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppConstants.primaryRed,
                  backgroundImage: appState.profilePhotoPath.isNotEmpty
                      ? FileImage(File(appState.profilePhotoPath))
                      : null,
                  child: appState.profilePhotoPath.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone,
                              color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Blood Type: $blood',
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Edit profile shortcut
                IconButton(
                  icon: const Icon(Icons.edit,
                      color: AppConstants.primaryRed, size: 20),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MedicalScreen()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactsSection(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Consumer<AppStateProvider>(
            builder: (context, appState, _) {
              final contacts = appState.emergencyContacts;
              if (contacts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No contacts added yet.',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }
              return Column(
                children: contacts.take(3).map((contact) {
                  return ListTile(
                    leading: const Icon(Icons.phone, color: Colors.white70),
                    title: Text(
                      contact.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      contact.phoneNumber,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          ListTile(
            title: const Text(
              'Manage Contacts',
              style: TextStyle(
                color: AppConstants.primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppConstants.primaryRed,
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ContactsScreen()),
              );
              // Refresh contact cache when returning
              if (context.mounted) {
                context.read<AppStateProvider>().refreshContacts();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSection(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Consumer<AppStateProvider>(
            builder: (context, appState, _) {
              final info = appState.medicalInfo;
              if (info.bloodType.isEmpty && info.medicalConditions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No medical info set.',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blood Type: ${info.bloodType}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (info.organDonor)
                          const Text(
                            'Organ Donor: Yes',
                            style: TextStyle(color: Colors.green),
                          ),
                      ],
                    ),
                    if (info.medicalConditions.isNotEmpty)
                      const Icon(Icons.medical_services,
                          color: Colors.white54),
                  ],
                ),
              );
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          ListTile(
            title: const Text(
              'Edit Medical ID',
              style: TextStyle(
                color: AppConstants.primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppConstants.primaryRed,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MedicalScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              "Background Protection",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Keep app alive in background",
              style: TextStyle(color: Colors.white54),
            ),
            value: _backgroundProtection,
            activeThumbColor: AppConstants.primaryRed,
            onChanged: (val) {
              setState(() => _backgroundProtection = val);
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          BlocBuilder<EmergencyBloc, EmergencyState>(
            builder: (context, state) {
              final isMonitoring = state.status == EmergencyStatus.monitoring;
              return SwitchListTile(
                title: const Text(
                  "Crash Detection",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "Listen for impacts & falls",
                  style: TextStyle(color: Colors.white54),
                ),
                value: isMonitoring,
                activeThumbColor: AppConstants.primaryRed,
                onChanged: (val) {
                  if (val) {
                    context.read<EmergencyBloc>().add(StartMonitoring());
                  } else {
                    context.read<EmergencyBloc>().add(StopMonitoring());
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
