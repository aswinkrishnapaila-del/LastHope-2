class Contact {
  final String id;
  final String name;
  final String phoneNumber;

  Contact({required this.id, required this.name, required this.phoneNumber});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phoneNumber': phoneNumber};
  }

  factory Contact.fromMap(Map<String, dynamic> map, String docId) {
    return Contact(
      id: docId,
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}
