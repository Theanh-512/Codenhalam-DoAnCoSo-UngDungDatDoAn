@echo off
echo ========================================================
echo   🚀 TỰ ĐỘNG COMMIT VÀ PUSH MÃ NGUỒN LÊN GITHUB
echo ========================================================
echo.

:: Di chuyển vào thư mục dự án
cd /d "d:\DoAnCoSo\DOANCOSO\Codenhalam-DoAnCoSo-UngDungDatDoAn"

echo 🔍 Đang kiểm tra trạng thái Git...
git status
echo.

echo 📦 Đang thêm các file thay đổi vào staging...
git add -A
echo.

echo 📝 Đang tạo bản Commit...
git commit -m "feat: upgrade search accent-insensitive, display restaurant name, and robust checkout payment fix"
echo.

echo 📤 Đang đẩy mã nguồn lên GitHub...
git push origin main

echo.
echo ========================================================
echo   🎉 HOÀN THÀNH: Đã đẩy toàn bộ code mới lên GitHub!
echo ========================================================
pause
