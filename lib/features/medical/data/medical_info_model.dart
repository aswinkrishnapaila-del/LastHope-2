class MedicalInfo {
  final String name;
  final String age;
  final String bloodType;
  final String allergies;
  final String medications;
  final String medicalConditions;
  final bool organDonor;
  final String insuranceProvider;

  MedicalInfo({
    required this.name,
    required this.age,
    required this.bloodType,
    required this.allergies,
    required this.medications,
    required this.medicalConditions,
    required this.organDonor,
    required this.insuranceProvider,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications,
      'medicalConditions': medicalConditions,
      'organDonor': organDonor,
      'insuranceProvider': insuranceProvider,
    };
  }

  factory MedicalInfo.fromMap(Map<String, dynamic> map) {
    return MedicalInfo(
      name: map['name'] ?? '',
      age: map['age'] ?? '',
      bloodType: map['bloodType'] ?? 'Unknown',
      allergies: map['allergies'] ?? 'None',
      medications: map['medications'] ?? 'None',
      medicalConditions: map['medicalConditions'] ?? 'None',
      organDonor: map['organDonor'] ?? false,
      insuranceProvider: map['insuranceProvider'] ?? 'None',
    );
  }

  // Empty factory for initial state
  factory MedicalInfo.empty() {
    return MedicalInfo(
      name: '',
      age: '',
      bloodType: '',
      allergies: '',
      medications: '',
      medicalConditions: '',
      organDonor: false,
      insuranceProvider: '',
    );
  }
}
