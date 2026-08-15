/// Represents one emergency contact saved by the user.
class Contact {
  String id; // Firestore document ID, empty until saved
  String name;
  String phoneNumber;
  String relation; // e.g. "Mother", "Friend", "Colleague"

  Contact({
    this.id = '',
    required this.name,
    required this.phoneNumber,
    this.relation = '',
  });

  /// Converts this contact into a Map for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relation': relation,
    };
  }

  /// Builds a Contact from a Firestore document snapshot.
  factory Contact.fromMap(String id, Map<String, dynamic> map) {
    return Contact(
      id: id,
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relation: map['relation'] ?? '',
    );
  }
}
