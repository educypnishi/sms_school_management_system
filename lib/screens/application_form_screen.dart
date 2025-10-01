import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/toast_util.dart';
import '../models/application_model.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class ApplicationFormScreen extends StatefulWidget {
  const ApplicationFormScreen({super.key});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  // Form keys for each step
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _educationFormKey = GlobalKey<FormState>();
  final _programFormKey = GlobalKey<FormState>();
  final _financialFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();
  
  // Services
  final _applicationService = ApplicationService();
  final _authService = AuthService();
  
  // State variables
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _applicationId;
  int _currentStep = 0;
  
  // Step 1: Personal Information controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _nationality;
  final _passportNumberController = TextEditingController();
  DateTime? _passportExpiryDate;
  final _addressController = TextEditingController();
  String? _gender;
  
  // Step 2: Educational Background controllers
  String? _highestEducation;
  final _institutionController = TextEditingController();
  final _fieldOfStudyController = TextEditingController();
  final _gpaController = TextEditingController();
  final _yearOfCompletionController = TextEditingController();
  List<String> _certificates = [];
  
  // Step 3: Program Selection controllers
  String? _desiredProgram;
  String? _desiredUniversity;
  String? _studyLevel;
  String? _preferredStartDate;
  bool _needsAccommodation = false;
  
  // Step 4: Financial Information controllers
  String? _fundingSource;
  bool _hasFinancialDocuments = false;
  final _availableFundsController = TextEditingController();
  final _sponsorNameController = TextEditingController();
  final _sponsorRelationshipController = TextEditingController();
  
  // Step 5: Document Uploads
  String? _passportScanUrl;
  String? _photoUrl;
  String? _transcriptsUrl;
  String? _certificatesUrl;
  String? _financialDocumentsUrl;
  String? _motivationLetterUrl;
  String? _recommendationLettersUrl;
  
  // Lists for dropdown options
  final List<String> _nationalityOptions = ['Cypriot', 'Greek', 'Turkish', 'British', 'Russian', 'Ukrainian', 'Nigerian', 'Indian', 'Pakistani', 'Chinese', 'Other'];
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _educationOptions = ['High School', 'Associate Degree', 'Bachelor\'s Degree', 'Master\'s Degree', 'PhD', 'Other'];
  final List<String> _programOptions = ['Computer Science', 'Business Administration', 'Medicine', 'Law', 'Engineering', 'Arts', 'Education', 'Tourism & Hospitality', 'Other'];
  final List<String> _universityOptions = ['University of Karachi', 'National University of Sciences and Technology (NUST)', 'Lahore University of Management Sciences (LUMS)', 'Aga Khan University', 'Institute of Business Administration (IBA) Karachi', 'University of Punjab', 'Other'];
  final List<String> _studyLevelOptions = ['Bachelor\'s', 'Master\'s', 'PhD', 'Certificate', 'Diploma'];
  final List<String> _startDateOptions = ['Fall 2025', 'Spring 2026', 'Fall 2026', 'Spring 2027'];
  final List<String> _fundingSourceOptions = ['Self-funded', 'Family Support', 'Scholarship', 'Student Loan', 'Employer Sponsored', 'Other'];
  
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
    _passportNumberController.dispose();
    _addressController.dispose();
    
    // Step 2 controllers
    _institutionController.dispose();
    _fieldOfStudyController.dispose();
    _gpaController.dispose();
    _yearOfCompletionController.dispose();
    
    // Step 4 controllers
    _availableFundsController.dispose();
    _sponsorNameController.dispose();
    _sponsorRelationshipController.dispose();
    
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
        // Pre-fill form with user data
        _nameController.text = user.name;
        _emailController.text = user.email;
        
        // Check if user has an existing application
        final applications = await _applicationService.getUserApplications();
        if (applications.isNotEmpty) {
          // Use the most recent application
          final application = applications.last;
          _applicationId = application.id;
          
          // Step 1: Personal Information
          _nameController.text = application.name;
          _emailController.text = application.email;
          _phoneController.text = application.phone;
          _dateOfBirth = application.dateOfBirth;
          _nationality = application.nationality;
          _passportNumberController.text = application.passportNumber ?? '';
          _passportExpiryDate = application.passportExpiryDate;
          _addressController.text = application.currentAddress ?? '';
          _gender = application.gender;
          
          // Step 2: Educational Background
          _highestEducation = application.highestEducation;
          _institutionController.text = application.previousInstitution ?? '';
          _fieldOfStudyController.text = application.fieldOfStudy ?? '';
          _gpaController.text = application.gpa?.toString() ?? '';
          _yearOfCompletionController.text = application.yearOfCompletion?.toString() ?? '';
          _certificates = application.certificates ?? [];
          
          // Step 3: Program Selection
          _desiredProgram = application.desiredProgram;
          _desiredUniversity = application.desiredUniversity;
          _studyLevel = application.studyLevel;
          _preferredStartDate = application.preferredStartDate;
          _needsAccommodation = application.needsAccommodation ?? false;
          
          // Step 4: Financial Information
          _fundingSource = application.fundingSource;
          _hasFinancialDocuments = application.hasFinancialDocuments ?? false;
          _availableFundsController.text = application.availableFunds?.toString() ?? '';
          _sponsorNameController.text = application.sponsorName ?? '';
          _sponsorRelationshipController.text = application.sponsorRelationship ?? '';
          
          // Step 5: Document Uploads
          _passportScanUrl = application.passportScanUrl;
          _photoUrl = application.photoUrl;
          _transcriptsUrl = application.transcriptsUrl;
          _certificatesUrl = application.certificatesUrl;
          _financialDocumentsUrl = application.financialDocumentsUrl;
          _motivationLetterUrl = application.motivationLetterUrl;
          _recommendationLettersUrl = application.recommendationLettersUrl;
          
          // Set current step
          _currentStep = application.currentStep ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _saveDraft() async {
    // Validate current step
    if (!_validateCurrentStep()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Save all application data
      await _saveApplicationData();
      
      // Show success message
      ToastUtil.showToast(
        context: context,
        message: 'Application draft saved',
      );
    } catch (e) {
      // Show error message
      ToastUtil.showToast(
        context: context,
        message: 'Error saving draft: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Save application data with all fields
  Future<void> _saveApplicationData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Parse numeric values
      double? gpa;
      if (_gpaController.text.isNotEmpty) {
        gpa = double.tryParse(_gpaController.text);
      }
      
      int? yearOfCompletion;
      if (_yearOfCompletionController.text.isNotEmpty) {
        yearOfCompletion = int.tryParse(_yearOfCompletionController.text);
      }
      
      double? availableFunds;
      if (_availableFundsController.text.isNotEmpty) {
        availableFunds = double.tryParse(_availableFundsController.text);
      }
      
      // Save all application data
      final application = await _applicationService.saveDraft(
        id: _applicationId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _dateOfBirth,
        nationality: _nationality,
        passportNumber: _passportNumberController.text.trim(),
        passportExpiryDate: _passportExpiryDate,
        currentAddress: _addressController.text.trim(),
        gender: _gender,
        highestEducation: _highestEducation,
        previousInstitution: _institutionController.text.trim(),
        fieldOfStudy: _fieldOfStudyController.text.trim(),
        gpa: gpa,
        yearOfCompletion: yearOfCompletion,
        certificates: _certificates,
        desiredProgram: _desiredProgram,
        desiredUniversity: _desiredUniversity,
        studyLevel: _studyLevel,
        preferredStartDate: _preferredStartDate,
        needsAccommodation: _needsAccommodation,
        fundingSource: _fundingSource,
        hasFinancialDocuments: _hasFinancialDocuments,
        availableFunds: availableFunds,
        sponsorName: _sponsorNameController.text.trim(),
        sponsorRelationship: _sponsorRelationshipController.text.trim(),
        passportScanUrl: _passportScanUrl,
        photoUrl: _photoUrl,
        transcriptsUrl: _transcriptsUrl,
        certificatesUrl: _certificatesUrl,
        financialDocumentsUrl: _financialDocumentsUrl,
        motivationLetterUrl: _motivationLetterUrl,
        recommendationLettersUrl: _recommendationLettersUrl,
        currentStep: _currentStep,
      );
      
      // Update application ID
      _applicationId = application.id;
      
      return;
    } catch (e) {
      debugPrint('Error saving application data: $e');
      ToastUtil.showToast(
        context: context,
        message: 'Error saving application data: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Validate the current step
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Personal Information
        return _personalInfoFormKey.currentState?.validate() ?? false;
      case 1: // Educational Background
        return _educationFormKey.currentState?.validate() ?? false;
      case 2: // Program Selection
        return _programFormKey.currentState?.validate() ?? false;
      case 3: // Financial Information
        return _financialFormKey.currentState?.validate() ?? false;
      case 4: // Document Uploads
        return _documentsFormKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }
  
  // Move to the next step
  void _nextStep() {
    if (_validateCurrentStep()) {
      _saveApplicationData().then((_) {
        if (_currentStep < 4) {
          setState(() {
            _currentStep += 1;
          });
        }
      });
    }
  }
  
  // Move to the previous step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }
  
  Future<void> _submitApplication() async {
    // Validate all steps before submission
    if (!_validateCurrentStep()) {
      ToastUtil.showToast(
        context: context,
        message: 'Please complete all required fields',
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // First save all data to ensure everything is up to date
      await _saveApplicationData();
      
      if (_applicationId == null) {
        throw Exception('Application not found');
      }
      
      // Submit application
      await _applicationService.submitApplication(_applicationId!);
      
      // Show success message
      ToastUtil.showToast(
        context: context,
        message: 'Application submitted successfully',
      );
      
      // Navigate back to student dashboard
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      // Show error message
      ToastUtil.showToast(
        context: context,
        message: 'Error submitting application: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Step 1: Personal Information Form
  Widget _buildPersonalInfoStep() {
    return Form(
      key: _personalInfoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please provide your basic personal information',
            style: TextStyle(
              color: AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: Validators.validateName,
          ),
          const SizedBox(height: 16),
          
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email *',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),
          
          // Phone Field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone),
            ),
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: 16),
          
          // Date of Birth
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
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
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _dateOfBirth != null
                    ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                    : 'Select your date of birth',
                style: TextStyle(
                  color: _dateOfBirth != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Nationality Dropdown
          DropdownButtonFormField<String>(
            value: _nationality,
            decoration: const InputDecoration(
              labelText: 'Nationality *',
              prefixIcon: Icon(Icons.flag),
            ),
            items: _nationalityOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _nationality = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select your nationality' : null,
          ),
          const SizedBox(height: 16),
          
          // Passport Number
          TextFormField(
            controller: _passportNumberController,
            decoration: const InputDecoration(
              labelText: 'Passport Number *',
              hintText: 'Enter your passport number',
              prefixIcon: Icon(Icons.credit_card),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your passport number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Passport Expiry Date
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _passportExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (date != null) {
                setState(() {
                  _passportExpiryDate = date;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Passport Expiry Date *',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _passportExpiryDate != null
                    ? DateFormat('dd/MM/yyyy').format(_passportExpiryDate!)
                    : 'Select passport expiry date',
                style: TextStyle(
                  color: _passportExpiryDate != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Current Address
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Current Address *',
              hintText: 'Enter your current address',
              prefixIcon: Icon(Icons.home),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your current address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Gender Dropdown
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Gender *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: _genderOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _gender = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select your gender' : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // Step 2: Educational Background Form
  Widget _buildEducationStep() {
    return Form(
      key: _educationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Educational Background',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please provide information about your educational background',
            style: TextStyle(
              color: AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Highest Education Level
          DropdownButtonFormField<String>(
            value: _highestEducation,
            decoration: const InputDecoration(
              labelText: 'Highest Education Level *',
              prefixIcon: Icon(Icons.school),
            ),
            items: _educationOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _highestEducation = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select your highest education level' : null,
          ),
          const SizedBox(height: 16),
          
          // Previous Institution
          TextFormField(
            controller: _institutionController,
            decoration: const InputDecoration(
              labelText: 'Previous Institution *',
              hintText: 'Enter your previous school/university name',
              prefixIcon: Icon(Icons.account_balance),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your previous institution';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Field of Study
          TextFormField(
            controller: _fieldOfStudyController,
            decoration: const InputDecoration(
              labelText: 'Field of Study *',
              hintText: 'Enter your field of study',
              prefixIcon: Icon(Icons.subject),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your field of study';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // GPA
          TextFormField(
            controller: _gpaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'GPA/Grade Average *',
              hintText: 'Enter your GPA or grade average',
              prefixIcon: Icon(Icons.grade),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your GPA';
              }
              final double? gpa = double.tryParse(value);
              if (gpa == null || gpa < 0 || gpa > 4.0) {
                return 'Please enter a valid GPA between 0.0 and 4.0';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Year of Completion
          TextFormField(
            controller: _yearOfCompletionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Year of Completion *',
              hintText: 'Enter the year you completed your studies',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your year of completion';
              }
              final int? year = int.tryParse(value);
              final int currentYear = DateTime.now().year;
              if (year == null || year < currentYear - 50 || year > currentYear) {
                return 'Please enter a valid year';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // Step 3: Program Selection Form
  Widget _buildProgramStep() {
    return Form(
      key: _programFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Program Selection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please select your preferred program and university',
            style: TextStyle(
              color: AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Desired Program
          DropdownButtonFormField<String>(
            value: _desiredProgram,
            decoration: const InputDecoration(
              labelText: 'Desired Program *',
              prefixIcon: Icon(Icons.school),
            ),
            items: _programOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _desiredProgram = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select your desired program' : null,
          ),
          const SizedBox(height: 16),
          
          // Desired University
          DropdownButtonFormField<String>(
            value: _desiredUniversity,
            decoration: const InputDecoration(
              labelText: 'Desired University *',
              prefixIcon: Icon(Icons.account_balance),
            ),
            items: _universityOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _desiredUniversity = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select your desired university' : null,
          ),
          const SizedBox(height: 16),
          
          // Study Level
          DropdownButtonFormField<String>(
            value: _studyLevel,
            decoration: const InputDecoration(
              labelText: 'Study Level *',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: _studyLevelOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _studyLevel = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select your study level' : null,
          ),
          const SizedBox(height: 16),
          
          // Preferred Start Date
          DropdownButtonFormField<String>(
            value: _preferredStartDate,
            decoration: const InputDecoration(
              labelText: 'Preferred Start Date *',
              prefixIcon: Icon(Icons.date_range),
            ),
            items: _startDateOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _preferredStartDate = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select your preferred start date' : null,
          ),
          const SizedBox(height: 16),
          
          // Accommodation Needs
          SwitchListTile(
            title: const Text('Need Accommodation Assistance'),
            subtitle: const Text('Do you need help finding accommodation in Cyprus?'),
            value: _needsAccommodation,
            onChanged: (bool value) {
              setState(() {
                _needsAccommodation = value;
              });
            },
            secondary: const Icon(Icons.home_outlined),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // Step 4: Financial Information Form
  Widget _buildFinancialStep() {
    return Form(
      key: _financialFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please provide information about your financial situation',
            style: TextStyle(
              color: AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Funding Source
          DropdownButtonFormField<String>(
            value: _fundingSource,
            decoration: const InputDecoration(
              labelText: 'Funding Source *',
              prefixIcon: Icon(Icons.account_balance_wallet),
            ),
            items: _fundingSourceOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _fundingSource = newValue;
              });
            },
            validator: (value) => value == null ? 'Please select your funding source' : null,
          ),
          const SizedBox(height: 16),
          
          // Available Funds
          TextFormField(
            controller: _availableFundsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Available Funds (EUR) *',
              hintText: 'Enter the amount of funds available',
              prefixIcon: Icon(Icons.euro),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your available funds';
              }
              final double? funds = double.tryParse(value);
              if (funds == null || funds < 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Financial Documents
          SwitchListTile(
            title: const Text('Financial Documents Available'),
            subtitle: const Text('Do you have bank statements or other financial documents?'),
            value: _hasFinancialDocuments,
            onChanged: (bool value) {
              setState(() {
                _hasFinancialDocuments = value;
              });
            },
            secondary: const Icon(Icons.description_outlined),
          ),
          const SizedBox(height: 16),
          
          // Sponsor Information (if applicable)
          if (_fundingSource == 'Family Support' || _fundingSource == 'Employer Sponsored')
            Column(
              children: [
                TextFormField(
                  controller: _sponsorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Sponsor Name *',
                    hintText: 'Enter the name of your sponsor',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (_fundingSource == 'Family Support' || _fundingSource == 'Employer Sponsored') {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your sponsor\'s name';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sponsorRelationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship to Sponsor *',
                    hintText: 'E.g., Parent, Employer, etc.',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  validator: (value) {
                    if (_fundingSource == 'Family Support' || _fundingSource == 'Employer Sponsored') {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your relationship to the sponsor';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // Step 5: Document Uploads Form
  Widget _buildDocumentsStep() {
    return Form(
      key: _documentsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Uploads',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please upload the required documents',
            style: TextStyle(
              color: AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Passport Scan
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Passport Scan *'),
            subtitle: Text(_passportScanUrl != null ? 'Uploaded' : 'Not uploaded'),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implement document upload
                ToastUtil.showToast(
                  context: context,
                  message: 'Document upload will be available in the next update',
                );
              },
              child: Text(_passportScanUrl != null ? 'Replace' : 'Upload'),
            ),
          ),
          const Divider(),
          
          // Photo
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Recent Photo *'),
            subtitle: Text(_photoUrl != null ? 'Uploaded' : 'Not uploaded'),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implement document upload
                ToastUtil.showToast(
                  context: context,
                  message: 'Document upload will be available in the next update',
                );
              },
              child: Text(_photoUrl != null ? 'Replace' : 'Upload'),
            ),
          ),
          const Divider(),
          
          // Academic Transcripts
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Academic Transcripts *'),
            subtitle: Text(_transcriptsUrl != null ? 'Uploaded' : 'Not uploaded'),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implement document upload
                ToastUtil.showToast(
                  context: context,
                  message: 'Document upload will be available in the next update',
                );
              },
              child: Text(_transcriptsUrl != null ? 'Replace' : 'Upload'),
            ),
          ),
          const Divider(),
          
          // Certificates
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text('Certificates'),
            subtitle: Text(_certificatesUrl != null ? 'Uploaded' : 'Not uploaded'),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implement document upload
                ToastUtil.showToast(
                  context: context,
                  message: 'Document upload will be available in the next update',
                );
              },
              child: Text(_certificatesUrl != null ? 'Replace' : 'Upload'),
            ),
          ),
          const Divider(),
          
          // Financial Documents
          if (_hasFinancialDocuments)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Financial Documents *'),
              subtitle: Text(_financialDocumentsUrl != null ? 'Uploaded' : 'Not uploaded'),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Implement document upload
                  ToastUtil.showToast(
                    context: context,
                    message: 'Document upload will be available in the next update',
                  );
                },
                child: Text(_financialDocumentsUrl != null ? 'Replace' : 'Upload'),
              ),
            ),
          if (_hasFinancialDocuments)
            const Divider(),
          
          // Motivation Letter
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Motivation Letter'),
            subtitle: Text(_motivationLetterUrl != null ? 'Uploaded' : 'Not uploaded'),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implement document upload
                ToastUtil.showToast(
                  context: context,
                  message: 'Document upload will be available in the next update',
                );
              },
              child: Text(_motivationLetterUrl != null ? 'Replace' : 'Upload'),
            ),
          ),
          const Divider(),
          
          // Recommendation Letters
          ListTile(
            leading: const Icon(Icons.recommend),
            title: const Text('Recommendation Letters'),
            subtitle: Text(_recommendationLettersUrl != null ? 'Uploaded' : 'Not uploaded'),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implement document upload
                ToastUtil.showToast(
                  context: context,
                  message: 'Document upload will be available in the next update',
                );
              },
              child: Text(_recommendationLettersUrl != null ? 'Replace' : 'Upload'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Form'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: _nextStep,
              onStepCancel: _previousStep,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Previous'),
                          ),
                        ),
                      if (_currentStep > 0)
                        const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentStep < 4 ? details.onStepContinue : _submitApplication,
                          child: Text(_currentStep < 4 ? 'Next' : 'Submit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saveDraft,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                          ),
                          child: const Text('Save Draft'),
                        ),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Personal Information
                Step(
                  title: const Text('Personal'),
                  content: _buildPersonalInfoStep(),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                // Step 2: Educational Background
                Step(
                  title: const Text('Education'),
                  content: _buildEducationStep(),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                // Step 3: Program Selection
                Step(
                  title: const Text('Program'),
                  content: _buildProgramStep(),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                ),
                // Step 4: Financial Information
                Step(
                  title: const Text('Financial'),
                  content: _buildFinancialStep(),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                ),
                // Step 5: Document Uploads
                Step(
                  title: const Text('Documents'),
                  content: _buildDocumentsStep(),
                  isActive: _currentStep >= 4,
                  state: _currentStep > 4 ? StepState.complete : StepState.indexed,
                ),
              ],
            ),
    );
  }
}
