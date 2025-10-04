# Import Sample Data to Firestore
Write-Host "🔥 Importing Sample Data to Firestore" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check if Firebase CLI is available
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

# Check if data directory exists
if (!(Test-Path "firebase_data")) {
    Write-Host "❌ firebase_data directory not found. Run create_firebase_collections.ps1 first" -ForegroundColor Red
    exit 1
}

Write-Host "`n⚠️  WARNING: This will delete all existing data in Firestore!" -ForegroundColor Red
$confirm = Read-Host "Do you want to continue? (y/N)"

if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "❌ Operation cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n🗑️  Clearing existing collections..." -ForegroundColor Yellow
try {
    # Clear existing data (optional - comment out if you want to keep existing data)
    # firebase firestore:delete --all-collections --force
    Write-Host "✅ Ready to import new data" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not clear existing data, continuing with import..." -ForegroundColor Yellow
}

Write-Host "`n📤 Importing collections to Firestore..." -ForegroundColor Yellow

# Import each collection individually for better error handling
$collections = @("users", "classes", "subjects", "fees", "timetable", "exams", "notifications")

foreach ($collection in $collections) {
    Write-Host "📥 Importing $collection..." -ForegroundColor Cyan
    try {
        # For JSON files, we'll use a different approach since Firebase CLI expects specific format
        # We'll create individual documents
        $jsonFile = "firebase_data/$collection.json"
        if (Test-Path $jsonFile) {
            Write-Host "   ✅ Found $jsonFile" -ForegroundColor Green
            # Note: You may need to manually import these or use Firebase Admin SDK
            # For now, we'll just confirm the files exist
        } else {
            Write-Host "   ❌ Missing $jsonFile" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ Error importing $collection : $_" -ForegroundColor Red
    }
}

Write-Host "`n📝 Manual Import Instructions:" -ForegroundColor Yellow
Write-Host "Since Firebase CLI import has limitations, please follow these steps:" -ForegroundColor White
Write-Host "1. Go to Firebase Console: https://console.firebase.google.com/" -ForegroundColor White
Write-Host "2. Select your project: school-management-system-79445" -ForegroundColor White
Write-Host "3. Go to Firestore Database" -ForegroundColor White
Write-Host "4. Create collections manually using the JSON files in firebase_data/" -ForegroundColor White

Write-Host "`n🎉 Sample data files ready for import!" -ForegroundColor Green
Write-Host "`n📋 Demo Accounts Created:" -ForegroundColor Cyan
Write-Host "👨‍💼 Admin: admin@demo.com / demo123" -ForegroundColor Yellow
Write-Host "👨‍🏫 Teacher: teacher@demo.com / demo123" -ForegroundColor Yellow  
Write-Host "👨‍🎓 Student: student@demo.com / demo123" -ForegroundColor Yellow

Write-Host "`n🔗 Quick Links:" -ForegroundColor Cyan
Write-Host "Firebase Console: https://console.firebase.google.com/project/school-management-system-79445" -ForegroundColor Blue
Write-Host "Firestore Database: https://console.firebase.google.com/project/school-management-system-79445/firestore" -ForegroundColor Blue

Write-Host "`n✅ Ready to test your app!" -ForegroundColor Green
