# Firebase Setup Guide
Write-Host "Firebase Services Setup Guide" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

$projectId = "school-management-system-79445"
$consoleUrl = "https://console.firebase.google.com/project/$projectId"

Write-Host ""
Write-Host "Project: $projectId" -ForegroundColor Yellow
Write-Host ""

Write-Host "Manual Setup Steps:" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Enable Authentication:" -ForegroundColor White
Write-Host "   Go to: $consoleUrl/authentication/providers" -ForegroundColor Gray
Write-Host "   Click Email/Password and enable it" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Create Firestore Database:" -ForegroundColor White
Write-Host "   Go to: $consoleUrl/firestore" -ForegroundColor Gray
Write-Host "   Click Create database" -ForegroundColor Gray
Write-Host "   Choose Start in test mode" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Enable Storage:" -ForegroundColor White
Write-Host "   Go to: $consoleUrl/storage" -ForegroundColor Gray
Write-Host "   Click Get started" -ForegroundColor Gray
Write-Host "   Choose Start in test mode" -ForegroundColor Gray
Write-Host ""

Write-Host "4. Test Your App:" -ForegroundColor Cyan
Write-Host "   Demo accounts:" -ForegroundColor White
Write-Host "   Admin: admin@demo.com / demo123" -ForegroundColor Yellow
Write-Host "   Teacher: teacher@demo.com / demo123" -ForegroundColor Yellow
Write-Host "   Student: student@demo.com / demo123" -ForegroundColor Yellow
Write-Host ""

Write-Host "5. Run Your App:" -ForegroundColor Cyan
Write-Host "   cd .." -ForegroundColor Gray
Write-Host "   flutter clean" -ForegroundColor Gray
Write-Host "   flutter pub get" -ForegroundColor Gray
Write-Host "   flutter run" -ForegroundColor Gray
Write-Host ""

Write-Host "Quick Links:" -ForegroundColor Cyan
Write-Host "Firebase Console: $consoleUrl" -ForegroundColor Blue
Write-Host ""

Write-Host "Setup complete!" -ForegroundColor Green
