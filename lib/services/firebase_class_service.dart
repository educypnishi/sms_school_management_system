import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/class_model.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

class FirebaseClassService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new class
  static Future<String> createClass({
    required String name,
    required String grade,
    required String subject,
    required String teacherId,
    required String teacherName,
    required String room,
    required String schedule,
    required int capacity,
    String? description,
  }) async {
    try {
      final classData = {
        'name': name,
        'grade': grade,
        'subject': subject,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'room': room,
        'schedule': schedule,
        'capacity': capacity,
        'currentStudents': 0,
        'description': description ?? '',
        'isActive': true,
        'createdBy': FirebaseAuthService.currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('classes').add(classData);
      debugPrint('✅ Class created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating class: $e');
      rethrow;
    }
  }

  // Get all classes
  static Future<List<ClassModel>> getAllClasses() async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ClassModel(
          id: doc.id,
          name: data['name'] ?? '',
          grade: data['grade'] ?? '',
          subject: data['subject'] ?? '',
          teacherName: data['teacherName'] ?? '',
          room: data['room'] ?? '',
          schedule: data['schedule'] ?? '',
          capacity: data['capacity'] ?? 0,
          currentStudents: data['currentStudents'] ?? 0,
          averageGrade: (data['averageGrade'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting classes: $e');
      return [];
    }
  }

  // Get classes by teacher
  static Future<List<ClassModel>> getClassesByTeacher(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ClassModel(
          id: doc.id,
          name: data['name'] ?? '',
          grade: data['grade'] ?? '',
          subject: data['subject'] ?? '',
          teacherName: data['teacherName'] ?? '',
          room: data['room'] ?? '',
          schedule: data['schedule'] ?? '',
          capacity: data['capacity'] ?? 0,
          currentStudents: data['currentStudents'] ?? 0,
          averageGrade: (data['averageGrade'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting teacher classes: $e');
      return [];
    }
  }

  // Get class by ID
  static Future<ClassModel?> getClassById(String classId) async {
    try {
      final doc = await _firestore.collection('classes').doc(classId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return ClassModel(
        id: doc.id,
        name: data['name'] ?? '',
        grade: data['grade'] ?? '',
        subject: data['subject'] ?? '',
        teacherName: data['teacherName'] ?? '',
        room: data['room'] ?? '',
        schedule: data['schedule'] ?? '',
        capacity: data['capacity'] ?? 0,
        currentStudents: data['currentStudents'] ?? 0,
        averageGrade: (data['averageGrade'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('❌ Error getting class: $e');
      return null;
    }
  }

  // Update class
  static Future<void> updateClass({
    required String classId,
    String? name,
    String? grade,
    String? subject,
    String? room,
    String? schedule,
    int? capacity,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (grade != null) updateData['grade'] = grade;
      if (subject != null) updateData['subject'] = subject;
      if (room != null) updateData['room'] = room;
      if (schedule != null) updateData['schedule'] = schedule;
      if (capacity != null) updateData['capacity'] = capacity;
      if (description != null) updateData['description'] = description;

      await _firestore.collection('classes').doc(classId).update(updateData);
      debugPrint('✅ Class updated successfully: $classId');
    } catch (e) {
      debugPrint('❌ Error updating class: $e');
      rethrow;
    }
  }

  // Add student to class
  static Future<void> addStudentToClass({
    required String classId,
    required String studentId,
    required String studentName,
  }) async {
    try {
      // Add student to class subcollection
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .set({
        'studentId': studentId,
        'studentName': studentName,
        'enrolledAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Update student count
      await _firestore.collection('classes').doc(classId).update({
        'currentStudents': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update student's class in users collection
      await _firestore.collection('users').doc(studentId).update({
        'class': classId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Student added to class successfully');
    } catch (e) {
      debugPrint('❌ Error adding student to class: $e');
      rethrow;
    }
  }

  // Remove student from class
  static Future<void> removeStudentFromClass({
    required String classId,
    required String studentId,
  }) async {
    try {
      // Remove student from class subcollection
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .delete();

      // Update student count
      await _firestore.collection('classes').doc(classId).update({
        'currentStudents': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove class from student's user document
      await _firestore.collection('users').doc(studentId).update({
        'class': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Student removed from class successfully');
    } catch (e) {
      debugPrint('❌ Error removing student from class: $e');
      rethrow;
    }
  }

  // Get students in class
  static Future<List<Map<String, dynamic>>> getClassStudents(String classId) async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .where('isActive', isEqualTo: true)
          .orderBy('studentName')
          .get();

      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting class students: $e');
      return [];
    }
  }

  // Delete class (soft delete)
  static Future<void> deleteClass(String classId) async {
    try {
      await _firestore.collection('classes').doc(classId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Class deleted successfully: $classId');
    } catch (e) {
      debugPrint('❌ Error deleting class: $e');
      rethrow;
    }
  }

  // Stream classes for real-time updates
  static Stream<List<ClassModel>> streamClasses() {
    return _firestore
        .collection('classes')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ClassModel(
          id: doc.id,
          name: data['name'] ?? '',
          grade: data['grade'] ?? '',
          subject: data['subject'] ?? '',
          teacherName: data['teacherName'] ?? '',
          room: data['room'] ?? '',
          schedule: data['schedule'] ?? '',
          capacity: data['capacity'] ?? 0,
          currentStudents: data['currentStudents'] ?? 0,
          averageGrade: (data['averageGrade'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    });
  }

  // Stream teacher's classes
  static Stream<List<ClassModel>> streamTeacherClasses(String teacherId) {
    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ClassModel(
          id: doc.id,
          name: data['name'] ?? '',
          grade: data['grade'] ?? '',
          subject: data['subject'] ?? '',
          teacherName: data['teacherName'] ?? '',
          room: data['room'] ?? '',
          schedule: data['schedule'] ?? '',
          capacity: data['capacity'] ?? 0,
          currentStudents: data['currentStudents'] ?? 0,
          averageGrade: (data['averageGrade'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    });
  }
}
