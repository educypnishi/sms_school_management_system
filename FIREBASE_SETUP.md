# 🔥 Firebase Integration Setup Guide

## 📋 **Prerequisites**

1. **Firebase Account**: Create a free account at [Firebase Console](https://console.firebase.google.com/)
2. **Flutter CLI**: Ensure you have Flutter installed and updated
3. **Firebase CLI**: Install Firebase CLI tools

## 🚀 **Step-by-Step Setup**

### **1. Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `school-management-system-pk`
4. Enable Google Analytics (optional)
5. Click "Create project"

### **2. Enable Firebase Services**

#### **Authentication**
1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Enable **Email/Password** authentication
3. Optionally enable **Google Sign-in** for enhanced security

#### **Firestore Database**
1. Go to **Firestore Database** > **Create database**
2. Choose **Start in test mode** (for development)
3. Select your preferred location (closest to Pakistan: `asia-south1`)

#### **Storage**
1. Go to **Storage** > **Get started**
2. Choose **Start in test mode**
3. Select same location as Firestore

### **3. Add Apps to Firebase Project**

#### **Android App**
1. Click **Add app** > **Android**
2. Android package name: `com.example.schoolms`
3. App nickname: `School Management System`
4. Download `google-services.json`
5. Place file in: `android/app/google-services.json`

#### **iOS App** (if targeting iOS)
1. Click **Add app** > **iOS**
2. iOS bundle ID: `com.example.schoolms`
3. App nickname: `School Management System`
4. Download `GoogleService-Info.plist`
5. Place file in: `ios/Runner/GoogleService-Info.plist`

#### **Web App** (if targeting web)
1. Click **Add app** > **Web**
2. App nickname: `School Management System`
3. Copy the configuration object

### **4. Update Firebase Configuration**

#### **Update firebase_options.dart**
Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
// Replace these with your actual Firebase configuration
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_MESSAGING_SENDER_ID',
  projectId: 'school-management-system-pk', // Your actual project ID
  storageBucket: 'school-management-system-pk.appspot.com',
);
```

### **5. Configure Android**

#### **Update android/build.gradle**
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

#### **Update android/app/build.gradle**
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Firebase requires minimum SDK 21
        targetSdkVersion 34
        multiDexEnabled true
    }
}

dependencies {
    implementation 'com.android.support:multidex:1.0.3'
}
```

### **6. Configure iOS** (if targeting iOS)

#### **Update ios/Runner/Info.plist**
```xml
<!-- Add before closing </dict> tag -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### **7. Set Up Firestore Security Rules**

In Firebase Console > Firestore Database > Rules, replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Students can read their own data
    match /students/{studentId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == studentId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin']);
    }
    
    // Teachers can read/write class-related data
    match /classes/{classId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
    }
    
    // Admins have full access
    match /{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### **8. Set Up Storage Security Rules**

In Firebase Console > Storage > Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### **9. Create Demo Users**

Run the app and create demo accounts using the Firebase signup screen:

1. **Admin Account**:
   - Email: `admin@demo.com`
   - Password: `demo123`
   - Role: Administrator

2. **Teacher Account**:
   - Email: `teacher@demo.com`
   - Password: `demo123`
   - Role: Teacher

3. **Student Account**:
   - Email: `student@demo.com`
   - Password: `demo123`
   - Role: Student

### **10. Test Firebase Integration**

1. Run the app: `flutter run`
2. Try signing up with a new account
3. Try signing in with existing accounts
4. Check Firebase Console to see:
   - Authentication > Users (new users appear)
   - Firestore Database > Data (user documents created)

## 🔧 **Troubleshooting**

### **Common Issues**

#### **"Default FirebaseApp is not initialized"**
- Ensure Firebase is initialized in `main.dart`
- Check that `firebase_options.dart` has correct configuration

#### **"Permission denied" in Firestore**
- Check Firestore security rules
- Ensure user is authenticated
- Verify user role in user document

#### **Android build fails**
- Ensure `google-services.json` is in correct location
- Check `minSdkVersion` is at least 21
- Verify Google Services plugin is applied

#### **iOS build fails**
- Ensure `GoogleService-Info.plist` is added to Xcode project
- Check bundle ID matches Firebase configuration

## 📊 **Database Structure**

### **Users Collection**
```
users/{userId}
├── uid: string
├── email: string
├── fullName: string
├── role: 'student' | 'teacher' | 'admin'
├── createdAt: timestamp
├── updatedAt: timestamp
├── isActive: boolean
├── profileImageUrl: string
├── phoneNumber: string
└── roleSpecificData: object
```

### **Classes Collection**
```
classes/{classId}
├── name: string
├── section: string
├── teacherId: string
├── subjects: array
├── students: array
└── schedule: object
```

### **Assignments Collection**
```
assignments/{assignmentId}
├── teacherId: string
├── classId: string
├── title: string
├── description: string
├── dueDate: timestamp
├── totalMarks: number
└── attachments: array
```

## 🚀 **Next Steps**

1. **Production Setup**: Change Firestore rules to production mode
2. **Backup Strategy**: Set up automated backups
3. **Monitoring**: Enable Firebase Performance Monitoring
4. **Analytics**: Set up Firebase Analytics for user insights
5. **Crashlytics**: Add Firebase Crashlytics for error tracking

## 📞 **Support**

If you encounter issues:
1. Check Firebase Console logs
2. Review Flutter Firebase documentation
3. Check app logs for detailed error messages
4. Ensure all dependencies are up to date

---

**🎉 Congratulations! Your School Management System is now integrated with Firebase for real-time data management, authentication, and cloud storage.**
