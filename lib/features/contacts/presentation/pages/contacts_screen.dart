import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:provider/provider.dart';
import '../../../../core/providers/app_state_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  Future<void> _importFromPhone() async {
    if (!await fc.FlutterContacts.requestPermission(readonly: true)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final contacts = await fc.FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    if (!mounted) return;

    final contactsWithPhone =
        contacts.where((c) => c.phones.isNotEmpty).toList();

    if (contactsWithPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts with phone numbers found')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PhoneContactPicker(
        contacts: contactsWithPhone,
        onSelected: (name, phone) async {
          // Capture refs BEFORE the await to avoid async-context gaps
          final appState = context.read<AppStateProvider>();
          final scaffold = ScaffoldMessenger.of(context);
          await appState.addContact(name, phone);
          if (ctx.mounted) Navigator.pop(ctx);
          scaffold.showSnackBar(
            SnackBar(content: Text('$name added as emergency contact ✅')),
          );
        },
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Emergency Contact',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.person, color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red.shade400),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.phone, color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red.shade400),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                // Capture refs BEFORE the await
                final appState = context.read<AppStateProvider>();
                final scaffold = ScaffoldMessenger.of(context);
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                await appState.addContact(name, phone);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                scaffold.showSnackBar(
                  SnackBar(content: Text('$name added ✅')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.black,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import_contacts',
            onPressed: _importFromPhone,
            icon: const Icon(Icons.contacts),
            label: const Text('Import'),
            backgroundColor: Colors.blue[700],
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add_manual',
            onPressed: _showAddDialog,
            backgroundColor: Colors.red.shade800,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          final contacts = appState.emergencyContacts;

          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contacts_outlined,
                      size: 72, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text(
                    'No Emergency Contacts.\nAdd one so we can alert them!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _importFromPhone,
                    icon: const Icon(Icons.contacts),
                    label: const Text('Import from Phone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Dismissible(
                key: Key(contact.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade900,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  // Capture refs BEFORE the await
                  final appState = context.read<AppStateProvider>();
                  final scaffold = ScaffoldMessenger.of(context);
                  await appState.deleteContact(contact.id);
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('${contact.name} removed'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade800,
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(contact.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(contact.phoneNumber,
                        style: const TextStyle(color: Colors.white54)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            appState.starredContactId == contact.id
                                ? Icons.star
                                : Icons.star_border,
                            color: appState.starredContactId == contact.id
                                ? Colors.yellow
                                : Colors.grey,
                          ),
                          onPressed: () {
                            context.read<AppStateProvider>().setStarredContactId(contact.id);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 22),
                          onPressed: () async {
                            await context.read<AppStateProvider>().deleteContact(contact.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Phone picker sheet ────────────────────────────────────────────────────────
class _PhoneContactPicker extends StatefulWidget {
  final List<fc.Contact> contacts;
  final void Function(String name, String phone) onSelected;

  const _PhoneContactPicker({
    required this.contacts,
    required this.onSelected,
  });

  @override
  State<_PhoneContactPicker> createState() => _PhoneContactPickerState();
}

class _PhoneContactPickerState extends State<_PhoneContactPicker> {
  String _searchQuery = '';

  List<fc.Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) return widget.contacts;
    final query = _searchQuery.toLowerCase();
    return widget.contacts.where((c) {
      return c.displayName.toLowerCase().contains(query) ||
          c.phones.any((p) => p.number.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Select a Contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  final phone = contact.phones.first.number;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[700],
                      child: Text(
                        contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(contact.displayName),
                    subtitle: Text(phone),
                    onTap: () => widget.onSelected(contact.displayName, phone),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
