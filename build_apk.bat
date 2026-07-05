@echo off
setlocal
echo ==========================================
echo   Verificando Requisitos del Sistema...
echo ==========================================

:: Verificar Git (necesario para que Flutter funcione bien)
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git no esta instalado o no esta en el PATH.
    echo Flutter requiere Git para funcionar. Por favor instalalo.
    pause
    exit /b 1
)
echo [OK] Git detectado.

:: Verificar si Flutter esta instalado
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter no esta instalado o no esta en el PATH.
    echo Por favor instala Flutter antes de continuar.
    pause
    exit /b 1
)
echo [OK] Flutter detectado.

:: Verificar si Java/JDK esta instalado
where java >nul 2>nul
if %errorlevel% neq 0 (
    echo [ADVERTENCIA] Java no esta en el PATH. 
    echo La compilacion de Android requerira Java (JDK). Si Android Studio ya lo incluye, puede que funcione.
) else (
    echo [OK] Java detectado.
)

:: Verificar Variables de Entorno de Android
if "%ANDROID_HOME%"=="" (
    if "%ANDROID_SDK_ROOT%"=="" (
        echo [ADVERTENCIA] No se encontro ANDROID_HOME ni ANDROID_SDK_ROOT.
        echo Asegurate de que el SDK de Android este configurado correctamente en Flutter.
    ) else (
        echo [OK] ANDROID_SDK_ROOT detectado.
    )
) else (
    echo [OK] ANDROID_HOME detectado.
)

echo.
echo ==========================================
echo   Ejecutando Flutter Doctor...
echo ==========================================
call flutter doctor
echo.
echo ==========================================
echo REVISAR: Por favor, asegurate de que "Flutter" y "Android toolchain" 
echo tengan un visto bueno (v) arriba.
echo Si "Android toolchain" te pide aceptar licencias, puedes hacerlo 
echo ejecutando "flutter doctor --android-licenses" en la terminal.
echo ==========================================
pause

echo.
echo ==========================================
echo   Preparando el Proyecto...
echo ==========================================

:: Borrar local.properties si existe (suele causar problemas al cambiar de PC)
if exist android\local.properties (
    echo Eliminando android\local.properties (Flutter lo recreara con las rutas de esta PC)...
    del android\local.properties
)

echo Limpiando archivos temporales y cache antigua...
call flutter clean

echo.
echo Obteniendo dependencias...
call flutter pub get

echo.
echo ==========================================
echo   Compilando el Proyecto (APK)...
echo ==========================================
call flutter build apk --release

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Hubo un problema al compilar la aplicacion. Revisa los mensajes de arriba.
    pause
    exit /b %errorlevel%
)

echo.
echo ==========================================
echo [EXITO] Compilacion finalizada correctamente.
echo El APK esta ubicado en: build\app\outputs\flutter-apk\app-release.apk
echo ==========================================
pause
