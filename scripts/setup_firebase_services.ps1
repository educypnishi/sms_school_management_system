# Firebase Services Setup
Write-Host "🔥 Firebase Services Setup" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

# Project details
$projectId = "school-management-system-79445"
$consoleUrl = "https://console.firebase.google.com/project/$projectId"

Write-Host "`n🎯 Project: $projectId" -ForegroundColor Yellow

Write-Host "`n📋 Manual Setup Steps:" -ForegroundColor Cyan

Write-Host "`n1️⃣ Enable Authentication:" -ForegroundColor White
Write-Host "   • Go to: $consoleUrl/authentication/providers" -ForegroundColor Gray
Write-Host "   • Click 'Email/Password'" -ForegroundColor Gray
Write-Host "   • Enable 'Email/Password' (first option)" -ForegroundColor Gray
Write-Host "   • Click 'Save'" -ForegroundColor Gray

Write-Host "`n2️⃣ Create Firestore Database:" -ForegroundColor White
Write-Host "   • Go to: $consoleUrl/firestore" -ForegroundColor Gray
Write-Host "   • Click 'Create database'" -ForegroundColor Gray
Write-Host "   • Choose 'Start in test mode'" -ForegroundColor Gray
Write-Host "   • Select location: asia-south1 (Mumbai)" -ForegroundColor Gray

Write-Host "`n3️⃣ Enable Storage:" -ForegroundColor White
Write-Host "   • Go to: $consoleUrl/storage" -ForegroundColor Gray
Write-Host "   • Click 'Get started'" -ForegroundColor Gray
Write-Host "   • Choose 'Start in test mode'" -ForegroundColor Gray
Write-Host "   • Use same location as Firestore" -ForegroundColor Gray

Write-Host "`n4️⃣ Import Sample Data:" -ForegroundColor White
Write-Host "   • Go to: $consoleUrl/firestore/data" -ForegroundColor Gray
Write-Host "   • Create collections manually:" -ForegroundColor Gray
Write-Host "     - users" -ForegroundColor Gray
Write-Host "     - classes" -ForegroundColor Gray
Write-Host "     - fees" -ForegroundColor Gray
Write-Host "     - notifications" -ForegroundColor Gray
Write-Host "   • Use JSON files from firebase_data folder" -ForegroundColor Gray

Write-Host "`n📱 Test Your App:" -ForegroundColor Cyan
Write-Host "After setup, test with these accounts:" -ForegroundColor White
Write-Host "👨‍💼 Admin: admin@demo.com / demo123" -ForegroundColor Yellow
Write-Host "👨‍🏫 Teacher: teacher@demo.com / demo123" -ForegroundColor Yellow
Write-Host "👨‍🎓 Student: student@demo.com / demo123" -ForegroundColor Yellow

Write-Host "`n🔗 Quick Links:" -ForegroundColor Cyan
Write-Host "Firebase Console: $consoleUrl" -ForegroundColor Blue
Write-Host "Authentication: $consoleUrl/authentication" -ForegroundColor Blue
Write-Host "Firestore: $consoleUrl/firestore" -ForegroundColor Blue
Write-Host "Storage: $consoleUrl/storage" -ForegroundColor Blue

Write-Host "`n⚡ Run Your App:" -ForegroundColor Cyan
Write-Host "cd .." -ForegroundColor Gray
Write-Host "flutter clean" -ForegroundColor Gray
Write-Host "flutter pub get" -ForegroundColor Gray
Write-Host "flutter run" -ForegroundColor Gray

Write-Host "`n✅ Setup guide complete!" -ForegroundColor Green
Write-Host "Follow the manual steps above to complete Firebase setup." -ForegroundColor White
