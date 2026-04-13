import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../data/medical_info_model.dart';

// Comprehensive list of common medical conditions for the searchable dropdown
const List<String> _commonMedicalConditions = [
  'Allergic Rhinitis',
  'Alzheimer\'s Disease',
  'Anemia',
  'Angina',
  'Anxiety Disorder',
  'Aortic Aneurysm',
  'Arrhythmia',
  'Arthritis',
  'Asthma',
  'Atrial Fibrillation',
  'Autism Spectrum Disorder',
  'Bipolar Disorder',
  'Brain Tumor',
  'Bronchitis',
  'Cancer (Breast)',
  'Cancer (Colon)',
  'Cancer (Lung)',
  'Cancer (Prostate)',
  'Cancer (Skin)',
  'Cardiomyopathy',
  'Celiac Disease',
  'Cerebral Palsy',
  'Chronic Fatigue Syndrome',
  'Chronic Kidney Disease',
  'Chronic Obstructive Pulmonary Disease (COPD)',
  'Cirrhosis',
  'Congestive Heart Failure',
  'Coronary Artery Disease',
  'Crohn\'s Disease',
  'Cystic Fibrosis',
  'Deep Vein Thrombosis',
  'Dementia',
  'Depression',
  'Diabetes (Type 1)',
  'Diabetes (Type 2)',
  'Diabetic Neuropathy',
  'Down Syndrome',
  'Eating Disorder',
  'Eczema',
  'Endometriosis',
  'Epilepsy',
  'Fibromyalgia',
  'Gallstones',
  'Gastroesophageal Reflux Disease (GERD)',
  'Glaucoma',
  'Gout',
  'Hashimoto\'s Thyroiditis',
  'Heart Attack (History)',
  'Heart Valve Disease',
  'Hemophilia',
  'Hepatitis B',
  'Hepatitis C',
  'Hernia',
  'High Blood Pressure (Hypertension)',
  'High Cholesterol (Hyperlipidemia)',
  'HIV/AIDS',
  'Huntington\'s Disease',
  'Hyperthyroidism',
  'Hypothyroidism',
  'Inflammatory Bowel Disease',
  'Interstitial Lung Disease',
  'Irritable Bowel Syndrome (IBS)',
  'Kidney Stones',
  'Leukemia',
  'Liver Disease',
  'Lupus (SLE)',
  'Lyme Disease',
  'Lymphoma',
  'Macular Degeneration',
  'Marfan Syndrome',
  'Meniere\'s Disease',
  'Meningitis (History)',
  'Migraine',
  'Multiple Sclerosis',
  'Muscular Dystrophy',
  'Myasthenia Gravis',
  'Narcolepsy',
  'Obesity',
  'Obsessive-Compulsive Disorder (OCD)',
  'Osteoporosis',
  'Pacemaker Implanted',
  'Pancreatitis',
  'Parkinson\'s Disease',
  'Peptic Ulcer Disease',
  'Peripheral Artery Disease',
  'Pneumonia (Recurrent)',
  'Polycystic Ovary Syndrome (PCOS)',
  'Post-Traumatic Stress Disorder (PTSD)',
  'Psoriasis',
  'Pulmonary Embolism (History)',
  'Pulmonary Fibrosis',
  'Rheumatoid Arthritis',
  'Sarcoidosis',
  'Schizophrenia',
  'Scoliosis',
  'Seizure Disorder',
  'Sickle Cell Disease',
  'Sleep Apnea',
  'Spinal Cord Injury',
  'Stroke (History)',
  'Thyroid Cancer',
  'Traumatic Brain Injury',
  'Tuberculosis',
  'Ulcerative Colitis',
  'Vertigo',
];

class MedicalScreen extends StatefulWidget {
  const MedicalScreen({super.key});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _insuranceController = TextEditingController();

  String? _selectedBloodType;
  bool _organDonor = false;
  bool _isLoading = true;

  // Selected medical conditions (multi-select)
  final List<String> _selectedConditions = [];

  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown',
  ];

  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final appState = context.read<AppStateProvider>();
    final info = appState.medicalInfo;
    final profile = appState.profile;

    _nameController.text = profile.fullName.isNotEmpty ? profile.fullName : info.name;
    _phoneController.text = profile.userPhone;
    _ageController.text = info.age;
    _selectedBloodType = info.bloodType.isNotEmpty && info.bloodType != 'Unknown' ? info.bloodType : null;
    _allergiesController.text = info.allergies == 'None' ? '' : info.allergies;
    _medicationsController.text = info.medications == 'None' ? '' : info.medications;
    _insuranceController.text = info.insuranceProvider == 'None' ? '' : info.insuranceProvider;
    _organDonor = info.organDonor;
    _localPhotoPath = appState.profilePhotoPath.isNotEmpty ? appState.profilePhotoPath : null;

    if (info.medicalConditions.isNotEmpty && info.medicalConditions != 'None') {
      _selectedConditions.addAll(
        info.medicalConditions.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
      );
    }
    _conditionsController.text = _selectedConditions.join(', ');
    _isLoading = false;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _localPhotoPath = pickedFile.path;
      });
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final info = MedicalInfo(
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        bloodType: _selectedBloodType ?? 'Unknown',
        allergies: _allergiesController.text.isNotEmpty ? _allergiesController.text : 'None',
        medications: _medicationsController.text.isNotEmpty ? _medicationsController.text : 'None',
        medicalConditions: _selectedConditions.isNotEmpty
            ? _selectedConditions.join(', ')
            : _conditionsController.text.isNotEmpty ? _conditionsController.text : 'None',
        organDonor: _organDonor,
        insuranceProvider: _insuranceController.text.isNotEmpty ? _insuranceController.text : 'None',
      );

      final appState = context.read<AppStateProvider>();
      
      // Save locally (which handles network backup syncs smoothly)
      await appState.saveMedical(info);
      await appState.saveProfile(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        photoPath: _localPhotoPath,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Saved ✅')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _addCondition(String condition) {
    if (condition.isNotEmpty && !_selectedConditions.contains(condition)) {
      setState(() {
        _selectedConditions.add(condition);
        _conditionsController.text = _selectedConditions.join(', ');
      });
    }
  }

  void _removeCondition(String condition) {
    setState(() {
      _selectedConditions.remove(condition);
      _conditionsController.text = _selectedConditions.join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medical Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: _localPhotoPath != null
                                  ? FileImage(File(_localPhotoPath!))
                                  : null,
                              child: _localPhotoPath == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Full Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Your Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedBloodType),
                      initialValue: _bloodTypes.contains(_selectedBloodType) ? _selectedBloodType : null,
                      decoration: const InputDecoration(
                        labelText: 'Blood Type',
                      ),
                      items: _bloodTypes.map((type) {
                        return DropdownMenuItem(
                            value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBloodType = val),
                    ),
                    const SizedBox(height: 24),

                    // Medical Conditions - Searchable Dropdown
                    const Text(
                      'Medical Conditions / Symptoms',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Selected conditions chips
                    if (_selectedConditions.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _selectedConditions.map((condition) {
                          return Chip(
                            label: Text(
                              condition,
                              style: const TextStyle(fontSize: 13),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeCondition(condition),
                            backgroundColor: Colors.red.withValues(alpha: 0.2),
                            side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.4),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Autocomplete search field
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        final query =
                            textEditingValue.text.toLowerCase();
                        return _commonMedicalConditions.where((condition) {
                          return condition.toLowerCase().contains(query) &&
                              !_selectedConditions.contains(condition);
                        });
                      },
                      onSelected: (String selection) {
                        _addCondition(selection);
                        // Clear the text field after selection
                      },
                      fieldViewBuilder: (context, textController,
                          focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText:
                                'Type to search or add a condition...',
                            prefixIcon:
                                const Icon(Icons.search, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Add custom condition',
                              onPressed: () {
                                if (textController.text
                                    .trim()
                                    .isNotEmpty) {
                                  _addCondition(
                                      textController.text.trim());
                                  textController.clear();
                                }
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              _addCondition(value.trim());
                              textController.clear();
                            }
                          },
                        );
                      },
                      optionsViewBuilder:
                          (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[850],
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 250,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option =
                                      options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.medical_services_outlined,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    title: Text(option),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _allergiesController,
                      decoration:
                          const InputDecoration(labelText: 'Allergies'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _medicationsController,
                      decoration: const InputDecoration(
                        labelText: 'Medications',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _insuranceController,
                      decoration: const InputDecoration(
                        labelText: 'Insurance Provider',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Organ Donor'),
                      value: _organDonor,
                      onChanged: (val) =>
                          setState(() => _organDonor = val),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
