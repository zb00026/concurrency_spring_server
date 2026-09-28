@echo off
REM Builds the project fully OFFLINE using the vendored Gradle home.
REM Requirement: only a JDK (17/21/25). No internet, no Maven, no system Gradle.
setlocal
set "GRADLE_USER_HOME=%~dp0gradle-offline-home"
set "JAVA_CMD="

REM 1) JAVA_HOME if set and valid
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" set "JAVA_CMD=%JAVA_HOME%\bin\java.exe"

REM 2) java on PATH
if "%JAVA_CMD%"=="" (
    where java >nul 2>nul && set "JAVA_CMD=java"
)

REM 3) Auto-detect common JDK install locations
REM    (alphabetically last = newest: jdk-25 > jdk-21 > jdk-17)
if "%ProgramFiles%"=="" set "ProgramFiles=C:\Program Files"
if "%SystemDrive%"=="" set "SystemDrive=C:"
if "%JAVA_CMD%"=="" (
    for /d %%J in ("%ProgramFiles%\Java\jdk*") do set "JAVA_CMD=%%J\bin\java.exe"
)
if "%JAVA_CMD%"=="" (
    for /d %%J in ("%ProgramFiles%\Eclipse Adoptium\jdk*") do set "JAVA_CMD=%%J\bin\java.exe"
)
if "%JAVA_CMD%"=="" (
    for /d %%J in ("%USERPROFILE%\.jdks\*") do if exist "%%J\bin\java.exe" set "JAVA_CMD=%%J\bin\java.exe"
)

if "%JAVA_CMD%"=="" (
    echo [ERROR] Java not found. Install JDK 17+ or set JAVA_HOME.
    exit /b 1
)
echo Using JDK: %JAVA_CMD%
"%JAVA_CMD%" -version 2>&1 | findstr /i "version"
if /i not "%JAVA_CMD%"=="java" set "JAVA_HOME=%JAVA_CMD:\bin\java.exe=%"

call "%~dp0gradlew.bat" --offline --no-daemon bootJar
if %errorlevel% neq 0 exit /b %errorlevel%
copy /y "%~dp0build\libs\highreq-api-1.0.0.jar" "%~dp0dist\" >nul
echo.
echo [OK] Built offline: dist\highreq-api-1.0.0.jar
