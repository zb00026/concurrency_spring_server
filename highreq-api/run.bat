@echo off
REM Offline runner: needs only a JDK (17/21/25) on the machine. No internet required.
setlocal
set "JAR=%~dp0dist\highreq-api-1.0.0.jar"
set "JAVA_CMD="

REM 1) JAVA_HOME if set and valid
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" set "JAVA_CMD=%JAVA_HOME%\bin\java.exe"

REM 2) java on PATH
if "%JAVA_CMD%"=="" (
    where java >nul 2>nul && set "JAVA_CMD=java"
)

REM 3) Auto-detect common JDK install locations
if "%ProgramFiles%"=="" set "ProgramFiles=C:\Program Files"
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
echo Starting highreq-api with %JAVA_CMD%
start "highreq-api" "%JAVA_CMD%" -jar "%JAR%"
echo API: http://localhost:8080/api/v1/users/health
