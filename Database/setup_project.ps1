# 🚀 AUTOMATED SETUP SCRIPT FOR M-CARS-FOOD
# Run this script to initialize the project after cloning.

Write-Host "--- 1. INITIALIZING DATABASE ---" -ForegroundColor Cyan
Write-Host "Please ensure you have executed 'Database/supabase_schema.sql' in your PostgreSQL instance." -ForegroundColor Yellow

Write-Host "`n--- 2. SETTING UP BACKEND (.NET 9) ---" -ForegroundColor Cyan
Set-Location "$PSScriptRoot\..\Backend\API"
dotnet restore
Write-Host "Backend ready. Run 'dotnet run' in Backend/API to start." -ForegroundColor Green

Write-Host "`n--- 3. SETTING UP AI SERVICE (PYTHON) ---" -ForegroundColor Cyan
Set-Location "$PSScriptRoot\..\Backend\AIService"
python -m pip install -r requirements.txt
python -m pip install torch torchvision torchaudio Pillow pandas scikit-learn
Write-Host "AI Service ready. Run 'python main.py' in Backend/AIService to start." -ForegroundColor Green

Write-Host "`n--- 4. SETTING UP FRONTEND (FLUTTER) ---" -ForegroundColor Cyan
Set-Location "$PSScriptRoot\..\Frontend\flutter"
flutter pub get
Write-Host "Frontend ready. Run 'flutter run' in Frontend/flutter to start." -ForegroundColor Green

Write-Host "`n===============================================" -ForegroundColor Magenta
Write-Host "🎉 ALL SYSTEMS CONFIGURED SUCCESSFULLY!" -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "Check 'Database/QUY_TRINH_TRIEN_KHAI.md' for more details." -ForegroundColor White
