import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart'; // Disabled for web compatibility
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../services/firebase_attendance_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_class_service.dart';
import '../models/class_model.dart';
import '../theme/app_theme.dart';

class QRAttendanceScreen extends StatefulWidget {
  final bool isTeacher;
  
  const QRAttendanceScreen({
    super.key,
    this.isTeacher = false,
  });

  @override
  State<QRAttendanceScreen> createState() => _QRAttendanceScreenState();
}

class _QRAttendanceScreenState extends State<QRAttendanceScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  // QRViewController? controller; // Disabled for web compatibility
  bool _isScanning = false;
  bool _isGenerating = false;
  String? _generatedQRData;
  List<ClassModel> _teacherClasses = [];
  ClassModel? _selectedClass;
  String _selectedSubject = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.isTeacher) {
      _loadTeacherClasses();
    }
  }

  @override
  void dispose() {
    // controller?.dispose(); // Disabled for web compatibility
    super.dispose();
  }

  Future<void> _loadTeacherClasses() async {
    try {
      final teacherId = FirebaseAuthService.currentUserId!;
      final classes = await FirebaseClassService.getClassesByTeacher(teacherId);
      
      setState(() {
        _teacherClasses = classes;
        if (classes.isNotEmpty) {
          _selectedClass = classes.first;
          _selectedSubject = classes.first.subject;
        }
      });
    } catch (e) {
      _showErrorSnackBar('Error loading classes: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTeacher ? 'Generate QR Code' : 'Scan QR Code'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: widget.isTeacher ? _buildTeacherView() : _buildStudentView(),
    );
  }

  Widget _buildTeacherView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Generate a QR code for students to scan for quick attendance marking.',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Class Selection
          const Text(
            'Select Class',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ClassModel>(
            value: _selectedClass,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _teacherClasses.map((classModel) {
              return DropdownMenuItem(
                value: classModel,
                child: Text('${classModel.name} - ${classModel.subject}'),
              );
            }).toList(),
            onChanged: (ClassModel? newClass) {
              setState(() {
                _selectedClass = newClass;
                _selectedSubject = newClass?.subject ?? '';
              });
            },
          ),
          const SizedBox(height: 16),

          // Subject Field
          const Text(
            'Subject',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _selectedSubject,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) => _selectedSubject = value,
          ),
          const SizedBox(height: 16),

          // Date Selection
          const Text(
            'Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 7)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 12),
                  Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Generate QR Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedClass != null && _selectedSubject.isNotEmpty
                  ? _generateQRCode
                  : null,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code),
              label: Text(_isGenerating ? 'Generating...' : 'Generate QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // QR Code Display
          if (_generatedQRData != null) _buildQRCodeDisplay(),
        ],
      ),
    );
  }

  Widget _buildStudentView() {
    return Column(
      children: [
        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Point your camera at the QR code displayed by your teacher to mark attendance.',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),

        // Scanner or Start Button
        Expanded(
          child: _isScanning ? _buildQRScanner() : _buildScannerStart(),
        ),
      ],
    );
  }

  Widget _buildQRScanner() {
    // Web-compatible QR scanner placeholder
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Colors.white54,
            ),
            const SizedBox(height: 20),
            const Text(
              'QR Scanner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Camera scanning not available on web.\nUse mobile app for QR scanning.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simulate QR scan for demo
                _processQRCode('demo_class_123_2024-01-15_Mathematics');
              },
              child: const Text('Demo Scan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerStart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to scan QR code',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = true),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeDisplay() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'QR Code for Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: _generatedQRData!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // QR Code Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class: ${_selectedClass?.name}'),
                  Text('Subject: $_selectedSubject'),
                  Text('Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Students can scan this QR code to mark their attendance.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyQRData(),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Data'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareQRCode(),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateQRCode() {
    if (_selectedClass == null || _selectedSubject.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      // Format: classId_date_subject
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final qrData = '${_selectedClass!.id}_${dateStr}_$_selectedSubject';
      
      setState(() {
        _generatedQRData = qrData;
        _isGenerating = false;
      });

      _showSuccessSnackBar('QR Code generated successfully!');
    } catch (e) {
      setState(() => _isGenerating = false);
      _showErrorSnackBar('Error generating QR code: $e');
    }
  }

  // void _onQRViewCreated(QRViewController controller) {
  //   this.controller = controller;
  //   controller.scannedDataStream.listen((scanData) {
  //     if (scanData.code != null) {
  //       _processQRCode(scanData.code!);
  //     }
  //   });
  // }

  Future<void> _processQRCode(String qrData) async {
    try {
      // Stop scanning (disabled for web)
      // await controller?.pauseCamera();
      
      final studentId = FirebaseAuthService.currentUserId!;
      
      // Process QR code for attendance
      await FirebaseAttendanceService.checkInWithQR(
        studentId: studentId,
        qrData: qrData,
        checkInTime: DateTime.now(),
      );

      if (mounted) {
        _showSuccessSnackBar('✅ Attendance marked successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error marking attendance: $e');
        // Resume scanning (disabled for web)
        // await controller?.resumeCamera();
      }
    }
  }

  void _copyQRData() {
    if (_generatedQRData != null) {
      Clipboard.setData(ClipboardData(text: _generatedQRData!));
      _showSuccessSnackBar('QR data copied to clipboard');
    }
  }

  void _shareQRCode() {
    // Implementation for sharing QR code
    // This would typically use the share_plus package
    _showSuccessSnackBar('Share functionality would be implemented here');
  }
}
