# ============================================================
# INSTALADOR DE LA TAREA PROGRAMADA - LIMPIEZA SEMANAL
# Ejecutar este script UNA SOLA VEZ como Administrador
# ============================================================

# ---- Configuracion ----
$nombreTarea    = "NAVAJA-SUIZA - Limpieza Semanal"
$descripcion    = "Limpieza automatica de archivos temporales cada lunes a las 03:00"
$diaEjecucion   = "Monday"
$horaEjecucion  = "03:00"

# Ruta donde se guardara el script de limpieza permanentemente
$carpetaScript  = "C:\Scripts\NavajasSuiza"
$rutaScript     = "$carpetaScript\LimpiezaSemanal.ps1"

# ---- Comprobar que se ejecuta como Admin ----
$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    Write-Host ""
    Write-Host "  ERROR: Este instalador debe ejecutarse como Administrador." -ForegroundColor Red
    Write-Host "  Haz clic derecho sobre el archivo y selecciona 'Ejecutar como administrador'." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   Instalador - Limpieza Semanal Automatica               " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

# ---- Crear carpeta de scripts si no existe ----
if (-not (Test-Path $carpetaScript)) {
    New-Item -ItemType Directory -Path $carpetaScript -Force | Out-Null
    Write-Host "  [OK] Carpeta creada: $carpetaScript" -ForegroundColor Green
}

# ---- Descargar el script de limpieza desde GitHub ----
Write-Host "  Descargando script de limpieza desde GitHub..." -NoNewline
try {
# Forzar el uso de TLS 1.2 para la descarga
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $urlScript = "https://raw.githubusercontent.com/Ale-debug-29/Limpieza-semanal/refs/heads/main/LimpiezaSemanal.ps1"
    Invoke-WebRequest -Uri $urlScript -OutFile $rutaScript -UseBasicParsing -ErrorAction Stop
    Unblock-File -Path $rutaScript -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green
    Write-Host "  [OK] Script guardado en: $rutaScript" -ForegroundColor Green
} catch {
    Write-Host " FALLO" -ForegroundColor Red
    Write-Host "  No se pudo descargar desde GitHub." -ForegroundColor Red
    Write-Host "  Coloca manualmente LimpiezaSemanal.ps1 en: $rutaScript" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit
}

# ---- Eliminar tarea anterior si existia ----
$tareaExistente = Get-ScheduledTask -TaskName $nombreTarea -ErrorAction SilentlyContinue
if ($tareaExistente) {
    Unregister-ScheduledTask -TaskName $nombreTarea -Confirm:$false
    Write-Host "  [OK] Tarea anterior eliminada." -ForegroundColor DarkGray
}

# ---- Crear la tarea programada ----
Write-Host "  Creando tarea programada..." -NoNewline
try {
    $accion    = New-ScheduledTaskAction `
                    -Execute "powershell.exe" `
                    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$rutaScript`""

    $disparador = New-ScheduledTaskTrigger `
                    -Weekly `
                    -DaysOfWeek $diaEjecucion `
                    -At $horaEjecucion

    $opciones  = New-ScheduledTaskSettingsSet `
                    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
                    -RunOnlyIfNetworkAvailable $false `
                    -StartWhenAvailable `
                    -WakeToRun $false

    # Ejecutar como SYSTEM para tener permisos maximos sin necesitar usuario logueado
    $principal = New-ScheduledTaskPrincipal `
                    -UserId "SYSTEM" `
                    -LogonType ServiceAccount `
                    -RunLevel Highest

    Register-ScheduledTask `
        -TaskName   $nombreTarea `
        -Action     $accion `
        -Trigger    $disparador `
        -Settings   $opciones `
        -Principal  $principal `
        -Description $descripcion `
        -Force | Out-Null

    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FALLO" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit
}

# ---- Verificar que la tarea se creo bien ----
$tareaCreada = Get-ScheduledTask -TaskName $nombreTarea -ErrorAction SilentlyContinue
if ($tareaCreada) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "   INSTALACION COMPLETADA CON EXITO" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Tarea    : $nombreTarea"          -ForegroundColor Cyan
    Write-Host "  Se ejecuta: Cada $diaEjecucion a las $horaEjecucion" -ForegroundColor Cyan
    Write-Host "  Script   : $rutaScript"           -ForegroundColor Cyan
    Write-Host "  Logs en  : C:\Logs\LimpiezaSemanal\" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Puedes verificarla en: Programador de Tareas de Windows" -ForegroundColor DarkGray
    Write-Host ""

    # Preguntar si quiere ejecutar una prueba ahora
    $prueba = Read-Host "  Deseas ejecutar una prueba ahora mismo? (S/N)"
    if ($prueba -in @("S","s")) {
        Write-Host ""
        Write-Host "  Ejecutando limpieza de prueba..." -ForegroundColor Yellow
        Start-ScheduledTask -TaskName $nombreTarea
        Start-Sleep -Seconds 3
        Write-Host "  Prueba lanzada. Revisa el log en C:\Logs\LimpiezaSemanal\" -ForegroundColor Green
    }
} else {
    Write-Host "  No se pudo verificar la tarea. Revisa el Programador de Tareas." -ForegroundColor Red
}

Write-Host ""
pause
