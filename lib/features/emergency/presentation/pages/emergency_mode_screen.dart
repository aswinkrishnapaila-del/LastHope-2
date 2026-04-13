import 'package:flutter/material.dart';
import '../../../../dependency_injection.dart';
import '../../../medical/data/medical_info_model.dart';
import '../../../medical/data/medical_service.dart';
import '../../../contacts/data/contact_model.dart';
import '../../../contacts/data/contact_service.dart';
import '../../../../core/services/sms_service.dart';

class EmergencyModeScreen extends StatelessWidget {
  const EmergencyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        title: const Text(
          "EMERGENCY MODE",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[900],
        automaticallyImplyLeading: false, // Prevent going back easily
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          sl<MedicalService>().getMedicalInfo(),
          sl<ContactService>().getContacts().first,
        ]),
        builder: (context, snapshot) {
          final info = (snapshot.data != null && snapshot.data!.isNotEmpty) 
              ? (snapshot.data![0] as MedicalInfo?) ?? MedicalInfo.empty()
              : MedicalInfo.empty();
          final List<Contact> contacts = (snapshot.data != null && snapshot.data!.length > 1) 
              ? (snapshot.data![1] as List).cast<Contact>() 
              : [];

          return Column(
            children: [
              // Flashing Banner (Simulated with simple container for now)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: const Text(
                  "HELP REQUESTED",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "MEDICAL ID",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard("Blood Type", info.bloodType),
                      _buildInfoCard("Allergies", info.allergies),
                      _buildInfoCard("Medications", info.medications),
                      _buildInfoCard(
                        "Organ Donor",
                        info.organDonor ? "YES" : "NO",
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "EMERGENCY CONTACTS",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (contacts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "No emergency contacts found.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      else
                        ...contacts.map((c) => _buildContactCard(c)),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          // Allow exit for user (PIN could be added later)
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("I AM SAFE"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              value.isNotEmpty ? value : "None/Unknown",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.red, size: 36),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(contact.phoneNumber, style: const TextStyle(fontSize: 16)),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Colors.green, size: 32),
          onPressed: () => autoDial(contact.phoneNumber),
        ),
      ),
    );
  }
}
