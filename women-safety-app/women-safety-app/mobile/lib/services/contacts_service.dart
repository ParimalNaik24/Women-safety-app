import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact.dart';

/// Handles all Firestore CRUD for a user's emergency contacts.
///
/// DATA STRUCTURE: users/{uid}/emergency_contacts/{contactId}
/// Nested under each user's own document so Firestore security rules can
/// simply say "a user can only read/write documents under their own uid".
class ContactsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');
    return _db.collection('users').doc(uid).collection('emergency_contacts');
  }

  Future<void> addContact(Contact contact) async {
    await _collection().add(contact.toMap());
  }

  Future<void> updateContact(Contact contact) async {
    if (contact.id.isEmpty) throw Exception('Contact has no id to update');
    await _collection().doc(contact.id).set(contact.toMap());
  }

  Future<void> deleteContact(String contactId) async {
    await _collection().doc(contactId).delete();
  }

  /// Real-time stream of the user's contacts -- the UI updates live
  /// whenever a contact is added/edited/deleted.
  Stream<List<Contact>> watchContacts() {
    return _collection().snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Contact.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
