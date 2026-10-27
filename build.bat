@echo off
setlocal

where ml64 >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ml64.exe が見つかりません。
    echo Visual Studio の "x64 Native Tools Command Prompt" から実行してください。
    exit /b 1
)

ml64 /c /Fo fcontext_win.obj fcontext_win.asm
if errorlevel 1 exit /b 1

cl /nologo /W4 /O2 /std:c11 main.c fcontext_win.obj /Fe:test.exe
if errorlevel 1 exit /b 1

echo.
echo === build ok: test.exe ===