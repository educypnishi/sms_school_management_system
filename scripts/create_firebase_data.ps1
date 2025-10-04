# Simple Firebase Data Creator
Write-Host "🔥 Creating Firebase Sample Data" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Create data directory
$dataDir = "firebase_data"
if (!(Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
    Write-Host "✅ Created data directory: $dataDir" -ForegroundColor Green
}

Write-Host "`n📝 Creating JSON data files..." -ForegroundColor Yellow

# 1. Users Collection
Write-Host "Creating users.json..." -ForegroundColor Cyan
$users = '[
  {
    "uid": "admin_001",
    "email": "admin@demo.com",
    "fullName": "System Administrator",
    "role": "admin",
    "isActive": true,
    "phoneNumber": "+92-300-1234567",
    "adminId": "ADM001",
    "department": "Administration"
  },
  {
    "uid": "teacher_001",
    "email": "teacher@demo.com", 
    "fullName": "Muhammad Ali Khan",
    "role": "teacher",
    "isActive": true,
    "phoneNumber": "+92-300-2345678",
    "teacherId": "TCH001",
    "department": "Mathematics"
  },
  {
    "uid": "student_001",
    "email": "student@demo.com",
    "fullName": "Ahmed Ali", 
    "role": "student",
    "isActive": true,
    "phoneNumber": "+92-300-3456789",
    "studentId": "STU001",
    "class": "Class-10-A"
  }
]'

$users | Out-File -FilePath "$dataDir\users.json" -Encoding UTF8

# 2. Classes Collection
Write-Host "Creating classes.json..." -ForegroundColor Cyan
$classes = '[
  {
    "id": "Class-10-A",
    "name": "Class 10",
    "section": "A",
    "teacherId": "teacher_001",
    "subjects": ["Mathematics", "Physics", "Chemistry"],
    "students": ["student_001"]
  }
]'

$classes | Out-File -FilePath "$dataDir\classes.json" -Encoding UTF8

# 3. Fees Collection
Write-Host "Creating fees.json..." -ForegroundColor Cyan
$fees = '[
  {
    "studentId": "student_001",
    "amount": 10000,
    "type": "tuition",
    "status": "paid",
    "description": "Monthly tuition fee"
  },
  {
    "studentId": "student_001",
    "amount": 5000,
    "type": "exam", 
    "status": "pending",
    "description": "Mid-term exam fee"
  }
]'

$fees | Out-File -FilePath "$dataDir\fees.json" -Encoding UTF8

# 4. Notifications Collection
Write-Host "Creating notifications.json..." -ForegroundColor Cyan
$notifications = '[
  {
    "title": "Welcome to School Management System",
    "message": "Your account has been created successfully.",
    "type": "general",
    "recipientIds": ["student_001"],
    "isRead": false
  },
  {
    "title": "Fee Payment Reminder", 
    "message": "Your exam fee of PKR 5,000 is due soon.",
    "type": "fee",
    "recipientIds": ["student_001"],
    "isRead": false
  }
]'

$notifications | Out-File -FilePath "$dataDir\notifications.json" -Encoding UTF8

Write-Host "`n✅ Sample data files created successfully!" -ForegroundColor Green
Write-Host "`nFiles created in $dataDir directory:" -ForegroundColor White
Write-Host "- users.json" -ForegroundColor Gray
Write-Host "- classes.json" -ForegroundColor Gray  
Write-Host "- fees.json" -ForegroundColor Gray
Write-Host "- notifications.json" -ForegroundColor Gray

Write-Host "`n📋 Demo Accounts:" -ForegroundColor Cyan
Write-Host "👨‍💼 Admin: admin@demo.com / demo123" -ForegroundColor Yellow
Write-Host "👨‍🏫 Teacher: teacher@demo.com / demo123" -ForegroundColor Yellow
Write-Host "👨‍🎓 Student: student@demo.com / demo123" -ForegroundColor Yellow

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Go to Firebase Console: https://console.firebase.google.com/project/school-management-system-79445" -ForegroundColor White
Write-Host "2. Enable Authentication > Email/Password" -ForegroundColor White
Write-Host "3. Create Firestore Database" -ForegroundColor White
Write-Host "4. Manually import the JSON files to Firestore" -ForegroundColor White
Write-Host "5. Test your app with demo accounts" -ForegroundColor White

Write-Host "`n✅ Firebase data preparation complete!" -ForegroundColor Green
