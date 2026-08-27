import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/contacts_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _contactsService = ContactsService();

  Future<void> _openAddEditDialog({Contact? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phoneNumber ?? '');
    final relationController = TextEditingController(text: existing?.relation ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Contact' : 'Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
            TextField(controller: relationController, decoration: const InputDecoration(labelText: 'Relation (e.g. Mother, Friend)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and phone number are required')),
                );
                return;
              }
              final contact = Contact(
                id: existing?.id ?? '',
                name: name,
                phoneNumber: phone,
                relation: relationController.text.trim(),
              );
              // Capture the Navigator BEFORE the await, so we're not touching
              // `context` again after an async gap.
              final navigator = Navigator.of(context);
              if (existing == null) {
                await _contactsService.addContact(contact);
              } else {
                await _contactsService.updateContact(contact);
              }
              // Defer the pop to after this frame finishes, so it never races
              // with the StreamBuilder rebuilding from the Firestore write we
              // just made. This is what actually fixes the _dependents.isEmpty
              // assertion -- capturing navigator early wasn't enough on its own.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                navigator.pop(true);
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // Defer disposal too -- for the same reason. The dialog's TextFields
    // might not have fully unmounted yet when this line runs otherwise.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      phoneController.dispose();
      relationController.dispose();
    });
    // No manual refresh needed -- watchContacts() is a live stream (see build()).
    if (saved == true && mounted) {
      // no-op: StreamBuilder updates automatically
    }
  }

  Future<void> _confirmDelete(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Remove ${contact.name} from your emergency contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _contactsService.deleteContact(contact.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Contact>>(
        stream: _contactsService.watchContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contacts = snapshot.data ?? [];
          if (contacts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No emergency contacts added yet. Tap + to add one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${contact.phoneNumber}\n${contact.relation}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => _openAddEditDialog(existing: contact)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(contact)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditDialog(),
        backgroundColor: const Color(0xFFFF4081),
        child: const Icon(Icons.add),
      ),
    );
  }
}