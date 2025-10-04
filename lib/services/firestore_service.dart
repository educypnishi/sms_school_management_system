import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic CRUD operations
  
  // Create document
  static Future<void> createDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Document created: $collection/$docId');
    } catch (e) {
      debugPrint('❌ Error creating document: $e');
      rethrow;
    }
  }

  // Add document with auto-generated ID
  static Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection(collection).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Document added: $collection/${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding document: $e');
      rethrow;
    }
  }

  // Read document
  static Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(docId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting document: $e');
      rethrow;
    }
  }

  // Update document
  static Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Document updated: $collection/$docId');
    } catch (e) {
      debugPrint('❌ Error updating document: $e');
      rethrow;
    }
  }

  // Delete document
  static Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      debugPrint('✅ Document deleted: $collection/$docId');
    } catch (e) {
      debugPrint('❌ Error deleting document: $e');
      rethrow;
    }
  }

  // Get collection
  static Future<List<Map<String, dynamic>>> getCollection({
    required String collection,
    Query Function(Query)? queryBuilder,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting collection: $e');
      rethrow;
    }
  }

  // Stream collection
  static Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    Query Function(Query)? queryBuilder,
    int? limit,
  }) {
    try {
      Query query = _firestore.collection(collection);
      
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return query.snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }).toList()
      );
    } catch (e) {
      debugPrint('❌ Error streaming collection: $e');
      rethrow;
    }
  }

  // Stream document
  static Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String docId,
  }) {
    try {
      return _firestore.collection(collection).doc(docId).snapshots().map((doc) {
        if (doc.exists) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }
        return null;
      });
    } catch (e) {
      debugPrint('❌ Error streaming document: $e');
      rethrow;
    }
  }

  // School Management Specific Methods

  // Students
  static Future<List<Map<String, dynamic>>> getStudents({
    String? classId,
    String? section,
    bool? isActive,
  }) async {
    return getCollection(
      collection: 'users',
      queryBuilder: (query) {
        query = query.where('role', isEqualTo: 'student');
        if (classId != null) query = query.where('class', isEqualTo: classId);
        if (section != null) query = query.where('section', isEqualTo: section);
        if (isActive != null) query = query.where('isActive', isEqualTo: isActive);
        return query.orderBy('fullName');
      },
    );
  }

  // Teachers
  static Future<List<Map<String, dynamic>>> getTeachers({
    String? department,
    bool? isActive,
  }) async {
    return getCollection(
      collection: 'users',
      queryBuilder: (query) {
        query = query.where('role', isEqualTo: 'teacher');
        if (department != null) query = query.where('department', isEqualTo: department);
        if (isActive != null) query = query.where('isActive', isEqualTo: isActive);
        return query.orderBy('fullName');
      },
    );
  }

  // Classes
  static Future<List<Map<String, dynamic>>> getClasses() async {
    return getCollection(
      collection: 'classes',
      queryBuilder: (query) => query.orderBy('name'),
    );
  }

  // Subjects
  static Future<List<Map<String, dynamic>>> getSubjects({String? classId}) async {
    return getCollection(
      collection: 'subjects',
      queryBuilder: (query) {
        if (classId != null) {
          query = query.where('classIds', arrayContains: classId);
        }
        return query.orderBy('name');
      },
    );
  }

  // Attendance
  static Future<void> markAttendance({
    required String studentId,
    required String classId,
    required DateTime date,
    required String status, // 'present', 'absent', 'late'
    String? remarks,
  }) async {
    final attendanceId = '${studentId}_${classId}_${date.toIso8601String().split('T')[0]}';
    
    await createDocument(
      collection: 'attendance',
      docId: attendanceId,
      data: {
        'studentId': studentId,
        'classId': classId,
        'date': Timestamp.fromDate(date),
        'status': status,
        'remarks': remarks ?? '',
        'markedBy': '', // Will be filled with teacher ID
      },
    );
  }

  // Fees
  static Future<void> createFeeRecord({
    required String studentId,
    required double amount,
    required String type, // 'tuition', 'exam', 'library', etc.
    required DateTime dueDate,
    String? description,
  }) async {
    await addDocument(
      collection: 'fees',
      data: {
        'studentId': studentId,
        'amount': amount,
        'type': type,
        'dueDate': Timestamp.fromDate(dueDate),
        'description': description ?? '',
        'status': 'pending', // 'pending', 'paid', 'overdue'
        'paidAmount': 0.0,
        'paidDate': null,
        'paymentMethod': '',
        'transactionId': '',
      },
    );
  }

  // Assignments
  static Future<String> createAssignment({
    required String teacherId,
    required String classId,
    required String subjectId,
    required String title,
    required String description,
    required DateTime dueDate,
    required int totalMarks,
    List<String>? attachments,
  }) async {
    return addDocument(
      collection: 'assignments',
      data: {
        'teacherId': teacherId,
        'classId': classId,
        'subjectId': subjectId,
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'totalMarks': totalMarks,
        'attachments': attachments ?? [],
        'status': 'active', // 'active', 'closed', 'draft'
        'submissionCount': 0,
      },
    );
  }

  // Exams
  static Future<String> createExam({
    required String classId,
    required String subjectId,
    required String title,
    required DateTime examDate,
    required String startTime,
    required String endTime,
    required int totalMarks,
    required String examType, // 'quiz', 'midterm', 'final', 'test'
    String? instructions,
  }) async {
    return addDocument(
      collection: 'exams',
      data: {
        'classId': classId,
        'subjectId': subjectId,
        'title': title,
        'examDate': Timestamp.fromDate(examDate),
        'startTime': startTime,
        'endTime': endTime,
        'totalMarks': totalMarks,
        'examType': examType,
        'instructions': instructions ?? '',
        'status': 'scheduled', // 'scheduled', 'ongoing', 'completed', 'cancelled'
        'createdBy': '', // Will be filled with teacher/admin ID
      },
    );
  }

  // Notifications
  static Future<String> createNotification({
    required String title,
    required String message,
    required String type, // 'general', 'fee', 'exam', 'assignment', 'attendance'
    required List<String> recipientIds,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    return addDocument(
      collection: 'notifications',
      data: {
        'title': title,
        'message': message,
        'type': type,
        'recipientIds': recipientIds,
        'actionUrl': actionUrl,
        'metadata': metadata ?? {},
        'isRead': false,
        'sentAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // Get user notifications
  static Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return streamCollection(
      collection: 'notifications',
      queryBuilder: (query) => query
          .where('recipientIds', arrayContains: userId)
          .orderBy('sentAt', descending: true),
      limit: 50,
    );
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    await updateDocument(
      collection: 'notifications',
      docId: notificationId,
      data: {'isRead': true},
    );
  }

  // Batch operations
  static Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var operation in operations) {
        final type = operation['type']; // 'set', 'update', 'delete'
        final collection = operation['collection'];
        final docId = operation['docId'];
        final data = operation['data'];
        
        DocumentReference docRef = _firestore.collection(collection).doc(docId);
        
        switch (type) {
          case 'set':
            batch.set(docRef, {
              ...data,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            break;
          case 'update':
            batch.update(docRef, {
              ...data,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }
      
      await batch.commit();
      debugPrint('✅ Batch operation completed: ${operations.length} operations');
    } catch (e) {
      debugPrint('❌ Error in batch operation: $e');
      rethrow;
    }
  }
}
