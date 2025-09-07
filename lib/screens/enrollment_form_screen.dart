import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/toast_util.dart';
import '../models/enrollment_model.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class EnrollmentFormScreen extends StatefulWidget {
  const EnrollmentFormScreen({super.key});

  @override
  State<EnrollmentFormScreen> createState() => _EnrollmentFormScreenState();
}

class _EnrollmentFormScreenState extends State<EnrollmentFormScreen> {
  // Form keys for each step
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _educationFormKey = GlobalKey<FormState>();
  final _courseFormKey = GlobalKey<FormState>();
  final _financialFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();
  
  // Services
  final _applicationService = ApplicationService();
  final _authService = AuthService();
  
  // State variables
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _enrollmentId;
  int _currentStep = 0;
  
  // Step 1: Personal Information controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _nationality;
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  String? _gender;
  
  // Step 2: Educational Background controllers
  final _previousSchoolController = TextEditingController();
  final _previousGradeController = TextEditingController();
  final _previousPerformanceController = TextEditingController();
  final _gpaController = TextEditingController();
  final _yearOfCompletionController = TextEditingController();
  List<String> _certificates = [];
  
  // Step 3: Course Selection controllers
  String? _desiredClass;
  String? _desiredGrade;
  String? _academicYear;
  String? _preferredStartDate;
  bool _needsTransportation = false;
  
  // Step 4: Financial Information controllers
  String? _paymentMethod;
  bool _hasScholarship = false;
  final _scholarshipAmountController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianRelationshipController = TextEditingController();
  
  // Step 5: Document Uploads
  String? _idCardUrl;
  String? _photoUrl;
  String? _previousReportCardsUrl;
  String? _certificatesUrl;
  String? _medicalRecordsUrl;
  String? _parentConsentFormUrl;
  String? _otherDocumentsUrl;
  
  // Lists for dropdown options
  final List<String> _nationalityOptions = ['Local', 'Foreign', 'Other'];
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _classOptions = ['Class A', 'Class B', 'Class C', 'Class D', 'Special Class'];
  final List<String> _gradeOptions = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'];
  final List<String> _academicYearOptions = ['2025-2026', '2026-2027', '2027-2028'];
  final List<String> _startDateOptions = ['Fall 2025', 'Spring 2026', 'Fall 2026', 'Spring 2027'];
  final List<String> _paymentMethodOptions = ['Monthly', 'Termly', 'Yearly', 'Other'];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    // Step 1 controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    
    // Step 2 controllers
    _previousSchoolController.dispose();
    _previousGradeController.dispose();
    _previousPerformanceController.dispose();
    _gpaController.dispose();
    _yearOfCompletionController.dispose();
    
    // Step 4 controllers
    _scholarshipAmountController.dispose();
    _guardianNameController.dispose();
    _guardianRelationshipController.dispose();
    
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user
      final user = await _authService.getCurrentUser();
      
      if (user != null) {
        // Pre-fill name and email
        _nameController.text = user.name;
        _emailController.text = user.email;
        
        // Check if user has an existing enrollment
        // This is a placeholder - in a real app, you would fetch from Firestore
        await Future.delayed(const Duration(milliseconds: 500));
        
        // For demo purposes, we'll assume no existing enrollment
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveEnrollment({bool submit = false}) async {
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // In a real app, this would save to Firestore
      // For now, we'll just simulate a delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Show success message
      if (submit) {
        ToastUtil.showToast(
          context: context,
          message: 'Enrollment submitted successfully!',
        );
        
        // Navigate back to dashboard
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        ToastUtil.showToast(
          context: context,
          message: 'Enrollment saved as draft',
        );
      }
    } catch (e) {
      debugPrint('Error saving enrollment: $e');
      
      // Show error message
      ToastUtil.showToast(
        context: context,
        message: 'Error saving enrollment: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  void _submitEnrollment() async {
    // Validate current step
    if (!_validateCurrentStep()) return;
    
    // Submit enrollment
    await _saveEnrollment(submit: true);
  }
  
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _personalInfoFormKey.currentState?.validate() ?? false;
      case 1:
        return _educationFormKey.currentState?.validate() ?? false;
      case 2:
        return _courseFormKey.currentState?.validate() ?? false;
      case 3:
        return _financialFormKey.currentState?.validate() ?? false;
      case 4:
        return _documentsFormKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Enrollment'),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _submitEnrollment,
            icon: _isSubmitting 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_validateCurrentStep()) {
                  if (_currentStep < 4) {
                    setState(() {
                      _currentStep += 1;
                    });
                  } else {
                    _submitEnrollment();
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep -= 1;
                  });
                }
              },
              onStepTapped: (step) {
                setState(() {
                  _currentStep = step;
                });
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(_currentStep == 4 ? 'Submit' : 'Continue'),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ],
                      const Spacer(),
                      TextButton(
                        onPressed: _isSubmitting ? null : () => _saveEnrollment(),
                        child: const Text('Save Draft'),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Personal Information
                Step(
                  title: const Text('Personal Information'),
                  content: _buildPersonalInfoForm(),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                
                // Step 2: Educational Background
                Step(
                  title: const Text('Educational Background'),
                  content: _buildEducationForm(),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                
                // Step 3: Course Selection
                Step(
                  title: const Text('Course Selection'),
                  content: _buildCourseForm(),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                ),
                
                // Step 4: Financial Information
                Step(
                  title: const Text('Financial Information'),
                  content: _buildFinancialForm(),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                ),
                
                // Step 5: Document Uploads
                Step(
                  title: const Text('Document Uploads'),
                  content: _buildDocumentsForm(),
                  isActive: _currentStep >= 4,
                  state: _currentStep > 4 ? StepState.complete : StepState.indexed,
                ),
              ],
            ),
    );
  }
  
  Widget _buildPersonalInfoForm() {
    return Form(
      key: _personalInfoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              hintText: 'Enter your full name',
            ),
            validator: Validators.validateName,
          ),
          const SizedBox(height: 16),
          
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              hintText: 'Enter your email address',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),
          
          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              hintText: 'Enter your phone number',
            ),
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: 16),
          
          // Date of Birth field
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth ?? DateTime(2010),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              
              if (date != null) {
                setState(() {
                  _dateOfBirth = date;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth *',
                hintText: 'Select your date of birth',
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dateOfBirth != null
                        ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                        : 'Select date',
                    style: TextStyle(
                      color: _dateOfBirth != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Nationality dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Nationality',
              hintText: 'Select your nationality',
            ),
            value: _nationality,
            items: _nationalityOptions.map((nationality) {
              return DropdownMenuItem(
                value: nationality,
                child: Text(nationality),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _nationality = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // ID Number field
          TextFormField(
            controller: _idNumberController,
            decoration: const InputDecoration(
              labelText: 'ID Number',
              hintText: 'Enter your ID number',
            ),
          ),
          const SizedBox(height: 16),
          
          // Address field
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Current Address *',
              hintText: 'Enter your current address',
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Gender dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Gender',
              hintText: 'Select your gender',
            ),
            value: _gender,
            items: _genderOptions.map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(gender),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _gender = value;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildEducationForm() {
    return Form(
      key: _educationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Previous School field
          TextFormField(
            controller: _previousSchoolController,
            decoration: const InputDecoration(
              labelText: 'Previous School *',
              hintText: 'Enter your previous school name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your previous school';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Previous Grade field
          TextFormField(
            controller: _previousGradeController,
            decoration: const InputDecoration(
              labelText: 'Previous Grade *',
              hintText: 'Enter your previous grade',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your previous grade';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Previous Performance field
          TextFormField(
            controller: _previousPerformanceController,
            decoration: const InputDecoration(
              labelText: 'Previous Academic Performance',
              hintText: 'Describe your previous academic performance',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          // GPA field
          TextFormField(
            controller: _gpaController,
            decoration: const InputDecoration(
              labelText: 'GPA (if applicable)',
              hintText: 'Enter your GPA',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          // Year of Completion field
          TextFormField(
            controller: _yearOfCompletionController,
            decoration: const InputDecoration(
              labelText: 'Year of Completion',
              hintText: 'Enter year of completion',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCourseForm() {
    return Form(
      key: _courseFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Desired Class dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Desired Class *',
              hintText: 'Select your desired class',
            ),
            value: _desiredClass,
            items: _classOptions.map((classOption) {
              return DropdownMenuItem(
                value: classOption,
                child: Text(classOption),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _desiredClass = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a class';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Desired Grade dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Desired Grade *',
              hintText: 'Select your desired grade',
            ),
            value: _desiredGrade,
            items: _gradeOptions.map((grade) {
              return DropdownMenuItem(
                value: grade,
                child: Text(grade),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _desiredGrade = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a grade';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Academic Year dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Academic Year *',
              hintText: 'Select academic year',
            ),
            value: _academicYear,
            items: _academicYearOptions.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _academicYear = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an academic year';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Preferred Start Date dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Preferred Start Date',
              hintText: 'Select preferred start date',
            ),
            value: _preferredStartDate,
            items: _startDateOptions.map((date) {
              return DropdownMenuItem(
                value: date,
                child: Text(date),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _preferredStartDate = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Transportation Checkbox
          CheckboxListTile(
            title: const Text('Needs Transportation'),
            subtitle: const Text('Check if you need school transportation'),
            value: _needsTransportation,
            onChanged: (value) {
              setState(() {
                _needsTransportation = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinancialForm() {
    return Form(
      key: _financialFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Method dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Payment Method *',
              hintText: 'Select payment method',
            ),
            value: _paymentMethod,
            items: _paymentMethodOptions.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(method),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _paymentMethod = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a payment method';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Scholarship Checkbox
          CheckboxListTile(
            title: const Text('Applying for Scholarship'),
            subtitle: const Text('Check if you are applying for a scholarship'),
            value: _hasScholarship,
            onChanged: (value) {
              setState(() {
                _hasScholarship = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          
          // Scholarship Amount field (visible only if scholarship is checked)
          if (_hasScholarship)
            TextFormField(
              controller: _scholarshipAmountController,
              decoration: const InputDecoration(
                labelText: 'Scholarship Amount Requested',
                hintText: 'Enter amount in USD',
              ),
              keyboardType: TextInputType.number,
            ),
          if (_hasScholarship)
            const SizedBox(height: 16),
          
          // Guardian Name field
          TextFormField(
            controller: _guardianNameController,
            decoration: const InputDecoration(
              labelText: 'Guardian Name *',
              hintText: 'Enter guardian\'s full name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter guardian\'s name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Guardian Relationship field
          TextFormField(
            controller: _guardianRelationshipController,
            decoration: const InputDecoration(
              labelText: 'Relationship to Guardian *',
              hintText: 'E.g., Parent, Sibling, etc.',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your relationship to guardian';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentsForm() {
    return Form(
      key: _documentsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please upload the following documents:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // ID Card Upload
          _buildDocumentUploadField(
            'ID Card or Birth Certificate',
            _idCardUrl != null,
            () {
              // In a real app, this would open a file picker
              setState(() {
                _idCardUrl = 'https://example.com/id_card.pdf';
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Photo Upload
          _buildDocumentUploadField(
            'Recent Passport-sized Photo',
            _photoUrl != null,
            () {
              // In a real app, this would open a file picker
              setState(() {
                _photoUrl = 'https://example.com/photo.jpg';
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Previous Report Cards Upload
          _buildDocumentUploadField(
            'Previous Report Cards',
            _previousReportCardsUrl != null,
            () {
              // In a real app, this would open a file picker
              setState(() {
                _previousReportCardsUrl = 'https://example.com/report_cards.pdf';
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Certificates Upload
          _buildDocumentUploadField(
            'Certificates (if any)',
            _certificatesUrl != null,
            () {
              // In a real app, this would open a file picker
              setState(() {
                _certificatesUrl = 'https://example.com/certificates.pdf';
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Medical Records Upload
          _buildDocumentUploadField(
            'Medical Records',
            _medicalRecordsUrl != null,
            () {
              // In a real app, this would open a file picker
              setState(() {
                _medicalRecordsUrl = 'https://example.com/medical_records.pdf';
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Parent Consent Form Upload
          _buildDocumentUploadField(
            'Parent Consent Form',
            _parentConsentFormUrl != null,
            () {
              // In a real app, this would open a file picker
              setState(() {
                _parentConsentFormUrl = 'https://example.com/consent_form.pdf';
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Other Documents Upload
          _buildDocumentUploadField(
            'Other Documents (if any)',
            _otherDocumentsUrl != null,
            () {
              // In a real app, this would open a file picker
              setState(() {
                _otherDocumentsUrl = 'https://example.com/other_documents.pdf';
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentUploadField(
    String label,
    bool isUploaded,
    VoidCallback onUpload,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(label),
        ),
        const SizedBox(width: 16),
        if (isUploaded)
          const Icon(Icons.check_circle, color: Colors.green)
        else
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload'),
          ),
      ],
    );
  }
}
