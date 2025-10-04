# Setup Firebase Authentication with Demo Users
Write-Host "🔐 Firebase Authentication Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Check Firebase CLI
try {
    firebase --version | Out-Null
    Write-Host "✅ Firebase CLI found" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found. Install with: npm install -g firebase-tools" -ForegroundColor Red
    exit 1
}

# Set project
Write-Host "`n🎯 Setting Firebase project..." -ForegroundColor Yellow
firebase use school-management-system-79445

Write-Host "`n🔧 Configuring Firebase Authentication..." -ForegroundColor Yellow

# Enable Email/Password authentication
Write-Host "📧 Enabling Email/Password authentication..." -ForegroundColor Cyan
Write-Host "Please follow these manual steps:" -ForegroundColor White
Write-Host "1. Go to Firebase Console: https://console.firebase.google.com/project/school-management-system-79445/authentication/providers" -ForegroundColor White
Write-Host "2. Click on 'Email/Password'" -ForegroundColor White
Write-Host "3. Enable 'Email/Password' (first option)" -ForegroundColor White
Write-Host "4. Click 'Save'" -ForegroundColor White

Read-Host "`nPress Enter when you've enabled Email/Password authentication..."

Write-Host "`n👥 Demo Users Information:" -ForegroundColor Yellow
Write-Host "These users will be created when you first run the app:" -ForegroundColor White

$demoUsers = @(
    @{
        Email = "admin@demo.com"
        Password = "demo123"
        Role = "Administrator"
        Name = "System Administrator"
        Description = "Full system access, can manage all users and settings"
    },
    @{
        Email = "teacher@demo.com" 
        Password = "demo123"
        Role = "Teacher"
        Name = "Muhammad Ali Khan"
        Description = "Can manage classes, students, assignments, and grades"
    },
    @{
        Email = "student@demo.com"
        Password = "demo123" 
        Role = "Student"
        Name = "Ahmed Ali"
        Description = "Can view grades, assignments, fees, and class schedule"
    }
)

foreach ($user in $demoUsers) {
    Write-Host "`n📋 $($user.Role) Account:" -ForegroundColor Cyan
    Write-Host "   Email: $($user.Email)" -ForegroundColor White
    Write-Host "   Password: $($user.Password)" -ForegroundColor White
    Write-Host "   Name: $($user.Name)" -ForegroundColor White
    Write-Host "   Access: $($user.Description)" -ForegroundColor Gray
}

Write-Host "`n🔒 Security Rules Setup:" -ForegroundColor Yellow
Write-Host "Setting up Firestore security rules..." -ForegroundColor White

# Create Firestore rules
$firestoreRules = @"
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
    
    // Fees - students can read their own, teachers/admins can read/write all
    match /fees/{feeId} {
      allow read: if request.auth != null && 
        (resource.data.studentId == request.auth.uid ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin']);
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
    }
    
    // Timetable - readable by all authenticated users
    match /timetable/{timetableId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
    }
    
    // Exams - readable by all authenticated users
    match /exams/{examId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
    }
    
    // Notifications - users can read their own notifications
    match /notifications/{notificationId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.recipientIds;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
    }
    
    // Subjects - readable by all authenticated users
    match /subjects/{subjectId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
    }
    
    // Assignments - students can read, teachers can read/write
    match /assignments/{assignmentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
    }
    
    // Admins have full access to everything
    match /{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
"@

$firestoreRules | Out-File -FilePath "firestore.rules" -Encoding UTF8
Write-Host "✅ Created firestore.rules file" -ForegroundColor Green

# Create Storage rules
$storageRules = @"
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can upload/download their own files
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Teachers and admins can access class materials
    match /classes/{classId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role in ['teacher', 'admin'];
    }
    
    // Public files (school documents, etc.)
    match /public/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Admins have full access
    match /{allPaths=**} {
      allow read, write: if request.auth != null && 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
"@

$storageRules | Out-File -FilePath "storage.rules" -Encoding UTF8
Write-Host "✅ Created storage.rules file" -ForegroundColor Green

Write-Host "`n📝 Manual Setup Required:" -ForegroundColor Yellow
Write-Host "1. Deploy Firestore rules:" -ForegroundColor White
Write-Host "   firebase deploy --only firestore:rules" -ForegroundColor Gray
Write-Host "2. Deploy Storage rules:" -ForegroundColor White  
Write-Host "   firebase deploy --only storage" -ForegroundColor Gray
Write-Host "3. Or copy rules manually to Firebase Console" -ForegroundColor White

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Deploy the security rules" -ForegroundColor White
Write-Host "2. Run your Flutter app: flutter run" -ForegroundColor White
Write-Host "3. Test signup/login with demo accounts" -ForegroundColor White
Write-Host "4. Check Firebase Console for created users" -ForegroundColor White

Write-Host "`n🔗 Firebase Console Links:" -ForegroundColor Cyan
Write-Host "Authentication: https://console.firebase.google.com/project/school-management-system-79445/authentication/users" -ForegroundColor Blue
Write-Host "Firestore Rules: https://console.firebase.google.com/project/school-management-system-79445/firestore/rules" -ForegroundColor Blue
Write-Host "Storage Rules: https://console.firebase.google.com/project/school-management-system-79445/storage/rules" -ForegroundColor Blue

Write-Host "`n✅ Firebase Authentication setup complete!" -ForegroundColor Green
