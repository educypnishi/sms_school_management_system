import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';
import '../models/real_attendance_model.dart';
import '../models/real_grade_model.dart';
import '../models/real_fee_model.dart';
import '../models/real_class_model.dart';

class DataSeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Seed all sample data
  Future<void> seedAllData() async {
    try {
      print('🌱 Starting data seeding...');
      
      // Create sample users and students
      final studentIds = await _seedStudents();
      
      // Create sample class schedules
      await _seedClassSchedules();
      
      // Create sample fee structures
      await _seedFeeStructures();
      
      // For each student, create sample data
      for (final studentId in studentIds) {
        await _seedStudentData(studentId);
      }
      
      print('✅ Data seeding completed successfully!');
    } catch (e) {
      print('❌ Error seeding data: $e');
      rethrow;
    }
  }

  // Create sample students
  Future<List<String>> _seedStudents() async {
    print('👥 Seeding students...');
    
    final students = [
      {
        'name': 'Ahmed Ali Khan',
        'email': 'ahmed.ali@school.edu.pk',
        'phone': '+92-300-1234567',
        'dateOfBirth': '2005-03-15',
        'gender': 'Male',
        'address': 'House 123, Block A, Gulshan-e-Iqbal, Karachi',
        'guardianName': 'Muhammad Ali Khan',
        'guardianRelationship': 'Father',
        'guardianPhone': '+92-321-1234567',
        'guardianEmail': 'ali.khan@email.com',
        'currentGrade': '10',
        'currentClass': 'Class 10-A',
        'admissionNumber': 'STD001',
        'admissionDate': '2020-04-01',
        'status': 'active',
      },
      {
        'name': 'Fatima Sheikh',
        'email': 'fatima.sheikh@school.edu.pk',
        'phone': '+92-300-2345678',
        'dateOfBirth': '2005-07-22',
        'gender': 'Female',
        'address': 'Flat 45, Tower B, Clifton, Karachi',
        'guardianName': 'Dr. Omar Sheikh',
        'guardianRelationship': 'Father',
        'guardianPhone': '+92-321-2345678',
        'guardianEmail': 'omar.sheikh@email.com',
        'currentGrade': '10',
        'currentClass': 'Class 10-A',
        'admissionNumber': 'STD002',
        'admissionDate': '2020-04-01',
        'status': 'active',
      },
      {
        'name': 'Hassan Malik',
        'email': 'hassan.malik@school.edu.pk',
        'phone': '+92-300-3456789',
        'dateOfBirth': '2005-11-08',
        'gender': 'Male',
        'address': 'House 67, Phase 2, DHA, Karachi',
        'guardianName': 'Sadia Malik',
        'guardianRelationship': 'Mother',
        'guardianPhone': '+92-321-3456789',
        'guardianEmail': 'sadia.malik@email.com',
        'currentGrade': '10',
        'currentClass': 'Class 10-B',
        'admissionNumber': 'STD003',
        'admissionDate': '2020-04-01',
        'status': 'active',
      },
    ];

    final studentIds = <String>[];

    for (final studentData in students) {
      // Create Firebase Auth user (for demo purposes, using a simple password)
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: studentData['email'] as String,
          password: 'student123', // Demo password
        );

        // Create user document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': studentData['name'],
          'email': studentData['email'],
          'role': 'student',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create student document
        final studentModel = StudentModel(
          id: '', // Will be set by Firestore
          userId: userCredential.user!.uid,
          name: studentData['name'] as String,
          email: studentData['email'] as String,
          phone: studentData['phone'] as String?,
          dateOfBirth: DateTime.parse(studentData['dateOfBirth'] as String),
          gender: studentData['gender'] as String?,
          address: studentData['address'] as String?,
          guardianName: studentData['guardianName'] as String?,
          guardianRelationship: studentData['guardianRelationship'] as String?,
          guardianPhone: studentData['guardianPhone'] as String?,
          guardianEmail: studentData['guardianEmail'] as String?,
          currentGrade: studentData['currentGrade'] as String?,
          currentClass: studentData['currentClass'] as String?,
          admissionNumber: studentData['admissionNumber'] as String?,
          admissionDate: DateTime.parse(studentData['admissionDate'] as String),
          status: studentData['status'] as String,
          createdAt: DateTime.now(),
        );

        final studentDoc = await _firestore.collection('students').add(studentModel.toMap());
        studentIds.add(studentDoc.id);

        // Create class enrollment
        await _firestore.collection('class_enrollments').add({
          'studentId': studentDoc.id,
          'classId': studentData['currentClass'] == 'Class 10-A' ? 'class_10a' : 'class_10b',
          'className': studentData['currentClass'],
          'grade': studentData['currentGrade'],
          'section': studentData['currentClass'] == 'Class 10-A' ? 'A' : 'B',
          'academicYear': '2024-2025',
          'enrollmentDate': DateTime.parse(studentData['admissionDate'] as String).toIso8601String(),
          'status': 'active',
          'createdAt': DateTime.now().toIso8601String(),
        });

        print('✅ Created student: ${studentData['name']}');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('⚠️ Student ${studentData['name']} already exists, skipping...');
          // Try to find existing student
          final existingQuery = await _firestore
              .collection('students')
              .where('email', isEqualTo: studentData['email'])
              .limit(1)
              .get();
          
          if (existingQuery.docs.isNotEmpty) {
            studentIds.add(existingQuery.docs.first.id);
          }
        } else {
          print('❌ Error creating student ${studentData['name']}: $e');
        }
      }
    }

    return studentIds;
  }

  // Create sample class schedules
  Future<void> _seedClassSchedules() async {
    print('📅 Seeding class schedules...');

    final schedules = [
      // Class 10-A Schedule
      {
        'classId': 'class_10a',
        'className': 'Class 10-A',
        'subjectId': 'math_10',
        'subjectName': 'Mathematics',
        'teacherId': 'teacher_001',
        'teacherName': 'Mr. Khan',
        'roomNumber': 'Room 101',
        'dayOfWeek': 'monday',
        'startTime': '09:00',
        'endTime': '10:00',
      },
      {
        'classId': 'class_10a',
        'className': 'Class 10-A',
        'subjectId': 'physics_10',
        'subjectName': 'Physics',
        'teacherId': 'teacher_002',
        'teacherName': 'Dr. Ahmed',
        'roomNumber': 'Lab 1',
        'dayOfWeek': 'monday',
        'startTime': '11:00',
        'endTime': '12:00',
      },
      {
        'classId': 'class_10a',
        'className': 'Class 10-A',
        'subjectId': 'english_10',
        'subjectName': 'English',
        'teacherId': 'teacher_003',
        'teacherName': 'Ms. Fatima',
        'roomNumber': 'Room 205',
        'dayOfWeek': 'monday',
        'startTime': '14:00',
        'endTime': '15:00',
      },
      // Add more schedules for other days and subjects...
    ];

    for (final schedule in schedules) {
      final startTime = DateTime.parse('2024-01-01 ${schedule['startTime']}:00');
      final endTime = DateTime.parse('2024-01-01 ${schedule['endTime']}:00');

      await _firestore.collection('class_schedules').add({
        'classId': schedule['classId'],
        'className': schedule['className'],
        'subjectId': schedule['subjectId'],
        'subjectName': schedule['subjectName'],
        'teacherId': schedule['teacherId'],
        'teacherName': schedule['teacherName'],
        'roomNumber': schedule['roomNumber'],
        'dayOfWeek': schedule['dayOfWeek'],
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // Create sample fee structures
  Future<void> _seedFeeStructures() async {
    print('💰 Seeding fee structures...');

    final feeStructures = [
      {
        'name': 'Monthly Tuition Fee',
        'description': 'Regular monthly tuition fee for Grade 10',
        'amount': 15000.0,
        'feeType': 'tuition',
        'frequency': 'monthly',
        'applicableGrade': '10',
        'isMandatory': true,
        'lateFee': 500.0,
        'gracePeriodDays': 5,
      },
      {
        'name': 'Library Fee',
        'description': 'Annual library and resource fee',
        'amount': 2000.0,
        'feeType': 'library',
        'frequency': 'annual',
        'applicableGrade': '10',
        'isMandatory': true,
        'lateFee': 100.0,
        'gracePeriodDays': 10,
      },
      {
        'name': 'Lab Fee',
        'description': 'Science laboratory fee per semester',
        'amount': 3000.0,
        'feeType': 'lab',
        'frequency': 'semester',
        'applicableGrade': '10',
        'isMandatory': true,
        'lateFee': 200.0,
        'gracePeriodDays': 7,
      },
    ];

    for (final fee in feeStructures) {
      await _firestore.collection('fee_structures').add({
        ...fee,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // Create sample data for a specific student
  Future<void> _seedStudentData(String studentId) async {
    print('📊 Seeding data for student: $studentId');

    // Create attendance records
    await _seedAttendanceRecords(studentId);
    
    // Create grade records
    await _seedGradeRecords(studentId);
    
    // Create fee records
    await _seedFeeRecords(studentId);
    
    // Create assignments
    await _seedAssignments(studentId);
    
    // Create exams
    await _seedExams(studentId);
  }

  Future<void> _seedAttendanceRecords(String studentId) async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));

    for (int i = 0; i < 30; i++) {
      final date = startDate.add(Duration(days: i));
      
      // Skip weekends
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }

      // Random attendance (90% present)
      final isPresent = DateTime.now().millisecond % 10 != 0;
      
      await _firestore.collection('attendance').add({
        'studentId': studentId,
        'classId': 'class_10a',
        'subjectId': 'math_10',
        'date': date.toIso8601String(),
        'status': isPresent ? 'present' : 'absent',
        'teacherId': 'teacher_001',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _seedGradeRecords(String studentId) async {
    final subjects = [
      {'id': 'math_10', 'name': 'Mathematics'},
      {'id': 'physics_10', 'name': 'Physics'},
      {'id': 'chemistry_10', 'name': 'Chemistry'},
      {'id': 'english_10', 'name': 'English'},
    ];

    final assessmentTypes = ['quiz', 'assignment', 'midterm', 'project'];

    for (final subject in subjects) {
      for (final assessmentType in assessmentTypes) {
        final marksObtained = 70.0 + (DateTime.now().millisecond % 30);
        final totalMarks = 100.0;
        final percentage = (marksObtained / totalMarks) * 100;
        final letterGrade = RealGradeModel.calculateLetterGrade(percentage);
        final gradePoints = RealGradeModel.calculateGradePoints(letterGrade);

        await _firestore.collection('grades').add({
          'studentId': studentId,
          'subjectId': subject['id'],
          'subjectName': subject['name'],
          'assessmentType': assessmentType,
          'assessmentName': '${subject['name']} $assessmentType',
          'marksObtained': marksObtained,
          'totalMarks': totalMarks,
          'percentage': percentage,
          'letterGrade': letterGrade,
          'gradePoints': gradePoints,
          'teacherId': 'teacher_001',
          'assessmentDate': DateTime.now().subtract(Duration(days: DateTime.now().day % 30)).toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<void> _seedFeeRecords(String studentId) async {
    // Get fee structures
    final feeStructuresQuery = await _firestore.collection('fee_structures').get();
    
    for (final feeDoc in feeStructuresQuery.docs) {
      final feeStructure = feeDoc.data();
      final originalAmount = feeStructure['amount'] as double;
      final discountAmount = 0.0; // No discount for now
      final finalAmount = originalAmount - discountAmount;
      final paidAmount = finalAmount * 0.6; // 60% paid
      final pendingAmount = finalAmount - paidAmount;

      await _firestore.collection('student_fees').add({
        'studentId': studentId,
        'feeStructureId': feeDoc.id,
        'feeName': feeStructure['name'],
        'originalAmount': originalAmount,
        'discountAmount': discountAmount,
        'finalAmount': finalAmount,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'dueDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'status': pendingAmount > 0 ? 'partial' : 'paid',
        'payments': [],
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _seedAssignments(String studentId) async {
    final assignments = [
      {
        'title': 'Quadratic Equations Practice',
        'subject': 'Mathematics',
        'description': 'Solve the given quadratic equations using different methods.',
        'dueDate': DateTime.now().add(const Duration(days: 7)),
        'maxMarks': 50,
      },
      {
        'title': 'Physics Lab Report',
        'subject': 'Physics',
        'description': 'Write a detailed report on the pendulum experiment.',
        'dueDate': DateTime.now().add(const Duration(days: 10)),
        'maxMarks': 30,
      },
    ];

    for (final assignment in assignments) {
      await _firestore.collection('assignments').add({
        ...assignment,
        'studentIds': [studentId],
        'teacherId': 'teacher_001',
        'createdAt': DateTime.now().toIso8601String(),
        'dueDate': (assignment['dueDate'] as DateTime).toIso8601String(),
      });
    }
  }

  Future<void> _seedExams(String studentId) async {
    final exams = [
      {
        'subject': 'Mathematics',
        'examType': 'Mid Term',
        'examDate': DateTime.now().add(const Duration(days: 15)),
        'duration': 120, // minutes
        'totalMarks': 100,
      },
      {
        'subject': 'Physics',
        'examType': 'Quiz',
        'examDate': DateTime.now().add(const Duration(days: 5)),
        'duration': 60,
        'totalMarks': 50,
      },
    ];

    for (final exam in exams) {
      await _firestore.collection('exams').add({
        ...exam,
        'studentIds': [studentId],
        'teacherId': 'teacher_001',
        'createdAt': DateTime.now().toIso8601String(),
        'examDate': (exam['examDate'] as DateTime).toIso8601String(),
      });
    }
  }

  // Check if data already exists
  Future<bool> isDataSeeded() async {
    final studentsQuery = await _firestore.collection('students').limit(1).get();
    return studentsQuery.docs.isNotEmpty;
  }

  // Clear all seeded data (for testing)
  Future<void> clearAllData() async {
    print('🗑️ Clearing all seeded data...');
    
    final collections = [
      'students',
      'users',
      'class_enrollments',
      'class_schedules',
      'fee_structures',
      'attendance',
      'grades',
      'student_fees',
      'assignments',
      'exams',
    ];

    for (final collection in collections) {
      final query = await _firestore.collection(collection).get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    }

    print('✅ All data cleared!');
  }
}
