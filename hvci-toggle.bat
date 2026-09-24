@echo off
rem HVCI Toggle - batch version.
rem Does exactly what the .exe does: flips the Memory Integrity (HVCI) registry value
rem and the hypervisor launch type. Open this file in Notepad to read every step.
setlocal

set "KEY=HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"

rem --- Require administrator ---
net session >nul 2>&1
if errorlevel 1 (
  echo Please right-click this file and choose "Run as administrator".
  pause
  exit /b 1
)

:menu
cls
set "STATE=OFF"
reg query "%KEY%" /v Enabled 2>nul | find "0x1" >nul && set "STATE=ON"
echo.
echo   HVCI Toggle
echo   -----------
echo   Memory Integrity (HVCI) is currently: %STATE%
echo.
echo   [1] Turn HVCI OFF
echo   [2] Turn HVCI ON
echo   [3] Restart now
echo   [4] Exit
echo.
choice /c 1234 /n /m "  Choose 1-4: "
if errorlevel 4 exit /b 0
if errorlevel 3 goto restart
if errorlevel 2 goto enable
goto disable

:disable
reg add "%KEY%" /v Enabled /t REG_DWORD /d 0 /f >nul
bcdedit /set hypervisorlaunchtype off >nul
echo   HVCI turned OFF. Restart to apply.
pause
goto menu

:enable
reg add "%KEY%" /v Enabled /t REG_DWORD /d 1 /f >nul
bcdedit /set hypervisorlaunchtype auto >nul
echo   HVCI turned ON. Restart to apply.
pause
goto menu

:restart
choice /c yn /m "  Restart right now? Save your work first"
if errorlevel 2 goto menu
shutdown /r /t 0
