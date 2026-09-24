@echo off
rem Builds HVCI Toggle.exe using the C# compiler that ships with Windows (.NET Framework 4.x).
setlocal
set CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
if not exist "%CSC%" set CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe

if not exist "%~dp0bin" mkdir "%~dp0bin"

"%CSC%" /nologo /codepage:65001 /optimize+ /target:winexe ^
  /win32manifest:"%~dp0src\app.manifest" ^
  /win32icon:"%~dp0assets\logo.ico" ^
  /out:"%~dp0bin\HVCI Toggle.exe" ^
  "%~dp0src\HvciToggle.cs"

if errorlevel 1 (
  echo Build failed.
  exit /b 1
)
echo Built: bin\HVCI Toggle.exe
