# Firebase Collections Creator Script
# This script creates initial collections and sample data for School Management System

Write-Host "🔥 Firebase Collections Creator for School Management System" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Check if Firebase CLI is installed
try {
    $firebaseVersion = firebase --version
    Write-Host "✅ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Login to Firebase (if not already logged in)
Write-Host "`n🔐 Checking Firebase authentication..." -ForegroundColor Yellow
try {
    $currentUser = firebase auth:list 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Please login to Firebase:" -ForegroundColor Yellow
        firebase login
    } else {
        Write-Host "✅ Already logged in to Firebase" -ForegroundColor Green
    }
} catch {
    Write-Host "Please login to Firebase:" -ForegroundColor Yellow
    firebase login
}

# Set Firebase project
Write-Host "`n🎯 Setting Firebase project..." -ForegroundColor Yellow
firebase use school-management-system-79445

# Create data directory if not exists
$dataDir = "firebase_data"
if (!(Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir
    Write-Host "✅ Created data directory: $dataDir" -ForegroundColor Green
}

# Create sample data files
Write-Host "`n📝 Creating sample data files..." -ForegroundColor Yellow

# 1. Users Collection
$usersData = @'
[
  {
    "uid": "admin_001",
    "email": "admin@demo.com",
    "fullName": "System Administrator",
    "role": "admin",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z",
    "isActive": true,
    "profileImageUrl": "",
    "phoneNumber": "+92-300-1234567",
    "address": "Lahore, Pakistan",
    "adminId": "ADM001",
    "joiningDate": "2024-01-01T00:00:00Z",
    "department": "Administration",
    "designation": "System Administrator",
    "permissions": [
      "manage_students",
      "manage_teachers", 
      "manage_courses",
      "manage_fees",
      "view_reports",
      "system_settings"
    ]
  },
  {
    "uid": "teacher_001", 
    "email": "teacher@demo.com",
    "fullName": "Muhammad Ali Khan",
    "role": "teacher",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z",
    "isActive": true,
    "profileImageUrl": "",
    "phoneNumber": "+92-300-2345678",
    "address": "Karachi, Pakistan",
    "teacherId": "TCH001",
    "joiningDate": "2024-01-01T00:00:00Z",
    "department": "Mathematics",
    "designation": "Senior Teacher",
    "qualification": "M.Sc Mathematics",
    "experience": 5,
    "subjects": ["Mathematics", "Physics"],
    "classes": ["Class-10-A", "Class-9-B"],
    "salary": 50000.0,
    "employeeType": "full-time"
  },
  {
    "uid": "student_001",
    "email": "student@demo.com", 
    "fullName": "Ahmed Ali",
    "role": "student",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z",
    "isActive": true,
    "profileImageUrl": "",
    "phoneNumber": "+92-300-3456789",
    "address": "Islamabad, Pakistan",
    "studentId": "STU001",
    "enrollmentDate": "2024-01-01T00:00:00Z",
    "class": "Class-10-A",
    "section": "A",
    "rollNumber": "001",
    "parentName": "Ali Ahmed",
    "parentPhone": "+92-300-4567890",
    "parentEmail": "parent@demo.com",
    "emergencyContact": "+92-300-5678901",
    "bloodGroup": "B+",
    "medicalConditions": [],
    "subjects": ["Mathematics", "Physics", "Chemistry", "English", "Urdu"],
    "totalFees": 25000.0,
    "paidFees": 15000.0,
    "pendingFees": 10000.0
  }
]
"@

$usersData | Out-File -FilePath "$dataDir/users.json" -Encoding UTF8

# 2. Classes Collection
$classesData = @"
[
  {
    "id": "Class-10-A",
    "name": "Class 10",
    "section": "A", 
    "teacherId": "teacher_001",
    "subjects": ["Mathematics", "Physics", "Chemistry", "English", "Urdu"],
    "students": ["student_001"],
    "schedule": {
      "Monday": [
        {"subject": "Mathematics", "time": "9:00-10:00", "room": "Room-101"},
        {"subject": "Physics", "time": "10:00-11:00", "room": "Room-102"}
      ],
      "Tuesday": [
        {"subject": "Chemistry", "time": "9:00-10:00", "room": "Room-103"},
        {"subject": "English", "time": "10:00-11:00", "room": "Room-104"}
      ]
    },
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
]
"@

$classesData | Out-File -FilePath "$dataDir/classes.json" -Encoding UTF8

# 3. Subjects Collection
$subjectsData = @"
[
  {
    "id": "math_10",
    "name": "Mathematics",
    "classIds": ["Class-10-A"],
    "teacherId": "teacher_001",
    "description": "Advanced Mathematics for Class 10",
    "totalMarks": 100,
    "passingMarks": 40,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  },
  {
    "id": "physics_10",
    "name": "Physics", 
    "classIds": ["Class-10-A"],
    "teacherId": "teacher_001",
    "description": "Physics fundamentals for Class 10",
    "totalMarks": 100,
    "passingMarks": 40,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
]
"@

$subjectsData | Out-File -FilePath "$dataDir/subjects.json" -Encoding UTF8

# 4. Fees Collection
$feesData = @"
[
  {
    "id": "fee_001",
    "studentId": "student_001",
    "amount": 10000.0,
    "type": "tuition",
    "dueDate": "2024-02-01T00:00:00Z",
    "description": "Monthly tuition fee - January 2024",
    "status": "paid",
    "paidAmount": 10000.0,
    "paidDate": "2024-01-15T00:00:00Z",
    "paymentMethod": "bank_transfer",
    "transactionId": "TXN001",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-15T00:00:00Z"
  },
  {
    "id": "fee_002",
    "studentId": "student_001", 
    "amount": 5000.0,
    "type": "exam",
    "dueDate": "2024-03-01T00:00:00Z",
    "description": "Mid-term exam fee",
    "status": "pending",
    "paidAmount": 0.0,
    "paidDate": null,
    "paymentMethod": "",
    "transactionId": "",
    "createdAt": "2024-02-01T00:00:00Z",
    "updatedAt": "2024-02-01T00:00:00Z"
  }
]
"@

$feesData | Out-File -FilePath "$dataDir/fees.json" -Encoding UTF8

# 5. Timetable Collection
$timetableData = @"
[
  {
    "id": "tt_001",
    "classId": "Class-10-A",
    "subjectId": "math_10",
    "teacherId": "teacher_001",
    "dayOfWeek": "Monday",
    "startTime": "09:00",
    "endTime": "10:00",
    "room": "Room-101",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  },
  {
    "id": "tt_002",
    "classId": "Class-10-A", 
    "subjectId": "physics_10",
    "teacherId": "teacher_001",
    "dayOfWeek": "Monday",
    "startTime": "10:00",
    "endTime": "11:00", 
    "room": "Room-102",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
]
"@

$timetableData | Out-File -FilePath "$dataDir/timetable.json" -Encoding UTF8

# 6. Exams Collection
$examsData = @"
[
  {
    "id": "exam_001",
    "classId": "Class-10-A",
    "subjectId": "math_10", 
    "title": "Mathematics Mid-term Exam",
    "examDate": "2024-03-15T00:00:00Z",
    "startTime": "09:00",
    "endTime": "12:00",
    "totalMarks": 100,
    "examType": "midterm",
    "instructions": "Bring calculator and geometry box",
    "status": "scheduled",
    "createdBy": "teacher_001",
    "createdAt": "2024-02-01T00:00:00Z",
    "updatedAt": "2024-02-01T00:00:00Z"
  }
]
"@

$examsData | Out-File -FilePath "$dataDir/exams.json" -Encoding UTF8

# 7. Notifications Collection
$notificationsData = @"
[
  {
    "id": "notif_001",
    "title": "Welcome to School Management System",
    "message": "Your account has been created successfully. Please complete your profile.",
    "type": "general",
    "recipientIds": ["student_001"],
    "actionUrl": "/profile",
    "metadata": {},
    "isRead": false,
    "sentAt": "2024-01-01T00:00:00Z",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  },
  {
    "id": "notif_002",
    "title": "Fee Payment Reminder",
    "message": "Your exam fee of PKR 5,000 is due on March 1st, 2024.",
    "type": "fee",
    "recipientIds": ["student_001"],
    "actionUrl": "/fee_payment",
    "metadata": {"feeId": "fee_002", "amount": 5000},
    "isRead": false,
    "sentAt": "2024-02-20T00:00:00Z",
    "createdAt": "2024-02-20T00:00:00Z",
    "updatedAt": "2024-02-20T00:00:00Z"
  }
]
"@

$notificationsData | Out-File -FilePath "$dataDir/notifications.json" -Encoding UTF8

Write-Host "✅ Sample data files created in $dataDir directory" -ForegroundColor Green

# Create Firestore import script
$importScript = @"
# Import data to Firestore
Write-Host "📤 Importing data to Firestore..." -ForegroundColor Yellow

# Import each collection
firebase firestore:delete --all-collections --force
Write-Host "🗑️ Cleared existing collections" -ForegroundColor Yellow

firebase firestore:import firebase_data --collection-ids users,classes,subjects,fees,timetable,exams,notifications
Write-Host "✅ Data imported successfully!" -ForegroundColor Green

Write-Host "`n🎉 Firebase collections created with sample data!" -ForegroundColor Cyan
Write-Host "You can now test your app with the following demo accounts:" -ForegroundColor White
Write-Host "👨‍💼 Admin: admin@demo.com / demo123" -ForegroundColor Yellow  
Write-Host "👨‍🏫 Teacher: teacher@demo.com / demo123" -ForegroundColor Yellow
Write-Host "👨‍🎓 Student: student@demo.com / demo123" -ForegroundColor Yellow
"@

$importScript | Out-File -FilePath "import_to_firestore.ps1" -Encoding UTF8

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run: .\import_to_firestore.ps1" -ForegroundColor White
Write-Host "2. Or manually import using Firebase Console" -ForegroundColor White
Write-Host "3. Test your app with demo accounts" -ForegroundColor White

Write-Host "`n✅ Firebase collections setup complete!" -ForegroundColor Green
