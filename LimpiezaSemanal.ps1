# ============================================================
# LIMPIEZA SEMANAL AUTOMATICA DE TEMPORALES
# Autor: NAVAJA-SUIZA
# Programado para ejecutarse automaticamente cada lunes a las 03:00
# ============================================================

# ---- Configuracion ----
$logFolder = "C:\Logs\LimpiezaSemanal"
$logFile   = "$logFolder\Limpieza_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$diasLog   = 30   # dias que se conservan los logs de limpieza anteriores

# Crear carpeta de logs si no existe
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

# Funcion para escribir en log y en consola a la vez
function Write-Log {
    param([string]$Mensaje, [string]$Color = "White")
    $linea = "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')  $Mensaje"
    Add-Content -Path $logFile -Value $linea -Encoding UTF8
    Write-Host $linea -ForegroundColor $Color
}

# ============================================================
Write-Log "=========================================================="
Write-Log "   INICIO DE LIMPIEZA SEMANAL AUTOMATICA"
Write-Log "   Equipo : $env:COMPUTERNAME"
Write-Log "   Usuario: $env:USERNAME"
Write-Log "=========================================================="
Write-Log ""

$totalLiberado = 0

# ---- Carpetas a limpiar (Sistema y Logs) ----
$objetivos = @(
    @{ Ruta = "C:\Windows\Temp";                          Desc = "Temp del sistema"           }
    @{ Ruta = "C:\Windows\Prefetch";                      Desc = "Prefetch de Windows"        }
    @{ Ruta = "C:\Windows\SoftwareDistribution\Download"; Desc = "Cache de Windows Update"    }
    @{ Ruta = "C:\Windows\Logs\CBS";                      Desc = "Logs CBS (actualizaciones)" }
    @{ Ruta = "C:\Windows\Logs\DISM";                     Desc = "Logs DISM"                  }
    @{ Ruta = "C:\inetpub\logs\LogFiles";                 Desc = "Logs de IIS"                }
)

# ---- Añadir dinámicamente las carpetas Temp de todos los usuarios ----
# Esto es necesario porque al correr como SYSTEM, $env:TEMP no apunta a los usuarios
$perfiles = Get-ChildItem "C:\Users" -Directory
foreach ($perfil in $perfiles) {
    $rutaTempUsuario = "$($perfil.FullName)\AppData\Local\Temp"
    if (Test-Path $rutaTempUsuario) {
        $objetivos += @{ Ruta = $rutaTempUsuario; Desc = "Temp Usuario: $($perfil.Name)" }
    }
}

foreach ($obj in $objetivos) {
    if (-not (Test-Path $obj.Ruta)) {
        Write-Log "  [OMITIDO]  $($obj.Desc) - Ruta no existe" "DarkGray"
        continue
    }

    $tamAntes = (Get-ChildItem $obj.Ruta -Recurse -Force -ErrorAction SilentlyContinue |
                 Measure-Object Length -Sum).Sum
    if ($null -eq $tamAntes) { $tamAntes = 0 }

    try {
        Get-ChildItem $obj.Ruta -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction Stop

        $tamDespues = (Get-ChildItem $obj.Ruta -Recurse -Force -ErrorAction SilentlyContinue |
                       Measure-Object Length -Sum).Sum
        if ($null -eq $tamDespues) { $tamDespues = 0 }

        $liberado = $tamAntes - $tamDespues
        $totalLiberado += $liberado
        Write-Log "  [OK]       $($obj.Desc) - Liberado: $([math]::Round($liberado/1MB,2)) MB" "Green"
    } catch {
        Write-Log "  [PARCIAL]  $($obj.Desc) - Algunos archivos en uso no se pudieron borrar" "Yellow"
    }
}

# ---- Papelera de reciclaje ----
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Log "  [OK]       Papelera de reciclaje vaciada" "Green"
} catch {
    Write-Log "  [OMITIDO]  Papelera ya estaba vacia" "DarkGray"
}

# ---- Borrar logs de limpieza antiguos (mas de X dias) ----
Write-Log ""
Write-Log "  Eliminando logs de limpieza con mas de $diasLog dias..."
$logsAntiguos = Get-ChildItem $logFolder -Filter "Limpieza_*.log" |
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$diasLog) }
foreach ($log in $logsAntiguos) {
    Remove-Item $log.FullName -Force -ErrorAction SilentlyContinue
    Write-Log "  [BORRADO]  Log antiguo: $($log.Name)" "DarkGray"
}

# ---- Resumen final ----
Write-Log ""
Write-Log "=========================================================="
Write-Log "   LIMPIEZA COMPLETADA"
Write-Log "   Espacio total liberado : $([math]::Round($totalLiberado/1MB,2)) MB  ($([math]::Round($totalLiberado/1GB,2)) GB)"
Write-Log "   Log guardado en        : $logFile"
Write-Log "=========================================================="
