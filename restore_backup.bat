@echo off
echo ============================================
echo   RESTORE BACKUP AQUAFEED - TUGAS AKHIR
echo ============================================
echo.
echo Script ini akan mengembalikan project ke kondisi
echo backup awal (commit pertama).
echo.
echo PERINGATAN: Semua perubahan yang belum di-commit
echo akan HILANG!
echo.
set /p confirm="Lanjutkan restore? (y/n): "
if "%confirm%"=="y" (
    echo.
    echo Mereset ke backup awal...
    git reset --hard 60ba2b5
    echo.
    echo Berhasil! Project sudah kembali ke kondisi backup awal.
) else (
    echo.
    echo Restore dibatalkan.
)
pause
