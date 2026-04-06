@echo off
TITLE Instalador Navaja Suiza
SETLOCAL

:: --- CONFIGURACIÓN ---
:: Cambia estas URLs por las direcciones "Raw" de tus archivos en GitHub
SET "URL_INSTALADOR=https://raw.githubusercontent.com/TU_USUARIO/NAVAJA-SUIZA/main/Instalar-LimpiezaSemanal.ps1"
SET "PATH_TEMPORAL=%TEMP%\Instalar-LimpiezaSemanal.ps1"

:: --- COMPROBAR ADMINISTRADOR ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Este script requiere permisos de administrador.
    echo [!] Intentando elevar privilegios...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: --- DESCARGAR Y EJECUTAR ---
echo [*] Descargando script de instalacion desde GitHub...
powershell -Command "(New-Object Net.WebClient).DownloadFile('%URL_INSTALADOR%', '%PATH_TEMPORAL%')"

if exist "%PATH_TEMPORAL%" (
    echo [*] Ejecutando instalador de PowerShell...
    :: Bypass de la politica de ejecucion solo para este proceso
    powershell -ExecutionPolicy Bypass -File "%PATH_TEMPORAL%"
    
    echo [*] Limpiando archivos temporales...
    del "%PATH_TEMPORAL%"
) else (
    echo [!] Error: No se pudo descargar el instalador. Revisa la conexion o la URL.
    pause
)

echo.
echo [+] Proceso finalizado.
pause
exit