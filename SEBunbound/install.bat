@echo off
title SEB Assistant Installer
color 0A

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This installer requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    pause
    exit /b 1
)

echo ====================================================
echo             SEB Assistant Installer
echo ====================================================
echo.

:: Create installation directory
set INSTALL_DIR=%LOCALAPPDATA%\SEB_Assistant
echo Creating installation directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\Answer-Key" mkdir "%INSTALL_DIR%\Answer-Key"

:: Check if Python is installed
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Python not detected. Installing Python...
    
    :: Download Python installer
    echo Downloading Python installer...
    powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe' -OutFile '%TEMP%\python_installer.exe'"
    
    if %errorLevel% neq 0 (
        echo Failed to download Python installer.
        pause
        exit /b 1
    )
    
    :: Run Python installer silently with necessary options
    echo Installing Python...
    %TEMP%\python_installer.exe /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
    
    if %errorLevel% neq 0 (
        echo Python installation failed.
        pause
        exit /b 1
    )
    
    echo Python installed successfully.
    
    :: Clean up
    del %TEMP%\python_installer.exe
) else (
    echo Python is already installed.
)

:: Copy application files
echo.
echo Copying application files...
copy "%~dp0main.py" "%INSTALL_DIR%"
copy "%~dp0json2dict.py" "%INSTALL_DIR%"
copy "%~dp0requirements.txt" "%INSTALL_DIR%"
copy "%~dp0README.md" "%INSTALL_DIR%"

:: Check if app_config.cfg exists, if not create it with default values
if not exist "%~dp0app_config.cfg" (
    echo Creating default configuration file...
    echo {"gemini_key": "", "last_mode": 1} > "%INSTALL_DIR%\app_config.cfg"
) else (
    copy "%~dp0app_config.cfg" "%INSTALL_DIR%"
)

:: Create example answer key file if it doesn't exist
if not exist "%INSTALL_DIR%\Answer-Key\example.json" (
    echo Creating example answer key...
    (
        echo {
        echo     "What is the capital of France?": "The capital of France is Paris.",
        echo     "Who wrote Romeo and Juliet?": "William Shakespeare wrote Romeo and Juliet.",
        echo     "What is the chemical symbol for gold?": "The chemical symbol for gold is Au.",
        echo     "What is the formula for water?": "The chemical formula for water is H2O.",
        echo     "Define photosynthesis.": "Photosynthesis is the process by which green plants and some other organisms use sunlight to synthesize foods with carbon dioxide and water, generating oxygen as a byproduct."
        echo }
    ) > "%INSTALL_DIR%\Answer-Key\example.json"
)

:: Create launcher batch file
echo Creating launcher script...
(
    echo @echo off
    echo :: SEB Assistant Launcher
    echo :: This script launches the SEB Assistant Python program
    echo.
    echo :: Change to the installation directory
    echo cd /d "%%LOCALAPPDATA%%\SEB_Assistant"
    echo.
    echo :: Launch the Python script
    echo start pythonw "%%LOCALAPPDATA%%\SEB_Assistant\main.py"
    echo.
    echo :: Exit the batch file
    echo exit
) > "%INSTALL_DIR%\launch_seb_assistant.bat"

:: Install dependencies
echo.
echo Installing dependencies...
cd /d "%INSTALL_DIR%"
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

if %errorLevel% neq 0 (
    echo Failed to install dependencies.
    pause
    exit /b 1
)

:: Create shortcuts using our dedicated script
echo.
echo Creating shortcuts...
set DESKTOP_SHORTCUT="%USERPROFILE%\Desktop\SEB Assistant.lnk"
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP_SHORTCUT%'); $Shortcut.TargetPath = '%INSTALL_DIR%\launch_seb_assistant.bat'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.IconLocation = 'shell32.dll,44'; $Shortcut.Save()"

set START_MENU_DIR="%APPDATA%\Microsoft\Windows\Start Menu\Programs"
if not exist %START_MENU_DIR% mkdir %START_MENU_DIR%
set START_MENU_SHORTCUT="%APPDATA%\Microsoft\Windows\Start Menu\Programs\SEB Assistant.lnk"
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%START_MENU_SHORTCUT%'); $Shortcut.TargetPath = '%INSTALL_DIR%\launch_seb_assistant.bat'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.IconLocation = 'shell32.dll,44'; $Shortcut.Save()"

:: Create uninstaller
echo.
echo Creating uninstaller...
(
    echo @echo off
    echo title SEB Assistant Uninstaller
    echo color 0C
    echo.
    echo echo ====================================================
    echo echo             SEB Assistant Uninstaller
    echo echo ====================================================
    echo echo.
    echo.
    echo set INSTALL_DIR=%INSTALL_DIR%
    echo.
    echo echo Removing desktop shortcut...
    echo if exist "%USERPROFILE%\Desktop\SEB Assistant.lnk" del "%USERPROFILE%\Desktop\SEB Assistant.lnk"
    echo.
    echo echo Removing start menu shortcut...
    echo if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\SEB Assistant.lnk" del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\SEB Assistant.lnk"
    echo.
    echo echo Removing installed files...
    echo if exist "%%INSTALL_DIR%%" rd /s /q "%%INSTALL_DIR%%"
    echo.
    echo echo NOTE: Thanks for downloading SEBunbound.
    echo echo ====================================================
    echo echo Uninstallation complete!
    echo echo ====================================================
    echo echo.
    echo pause
    echo exit /b 0
) > "%INSTALL_DIR%\uninstall.bat"
