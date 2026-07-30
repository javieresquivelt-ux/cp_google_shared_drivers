#!/bin/bash
# ==============================================================================
# Script de Copia Inicial / Sincronización GAMADV-XTD3
# Fase 2: Modos Completos, Subdirectorio y Elementos Individuales
# ==============================================================================

# Forzar ejecución desde el directorio raíz del proyecto
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR" || exit 1

# Cargar configuración global
if [ ! -f "config/config.env" ]; then
    echo "Error: No se encuentra config/config.env"
    exit 1
fi
source config/config.env

# Crear directorios si no existen
mkdir -p "$LOG_DIR" "$DATA_DIR"

timestamp=$(date +%Y%m%d_%H%M%S)
logfile="${LOG_DIR}/sync_${timestamp}.log"

# Función de Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$logfile"
}

# Determinar ruta de GAM
GAM_BIN=$(command -v gam)
if [ -z "$GAM_BIN" ]; then
    GAM_BIN="$HOME/bin/gam7/gam"
fi

# Wrapper para comandos GAM
run_gam_cmd() {
    local cmd="$1"
    # Reemplazar 'gam' por el binario real
    if [[ "$cmd" == gam\ * ]]; then
        cmd="${GAM_BIN} ${cmd#gam }"
    fi
    log "--------------------------------------------------------"
    log "Ejecutando: $cmd"
    eval "$cmd" 2>&1 | tee -a "$logfile"
    local status=${PIPESTATUS[0]}
    log "Código de salida: $status"
    log "--------------------------------------------------------"
    return $status
}

# Validación inicial de GAM
log "Iniciando validación de autenticación de GAM..."
"$GAM_BIN" info domain > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log "ERROR CRÍTICO: Fallo en la autenticación de GAM (gam info domain falló)."
    exit 1
else
    log "GAM validado correctamente."
fi

# ==============================================================================
# Funciones de Modos de Sincronización
# ==============================================================================

mode_full() {
    log "=== MODO: UNIDAD COMPLETA ==="
    if [[ -z "$SOURCE_DRIVE_ID" || -z "$TARGET_DRIVE_ID" || "$SOURCE_DRIVE_ID" == "ID_"* ]]; then
        log "Error: Faltan los IDs de Unidades en config.env"
        exit 1
    fi
    run_gam_cmd "gam user $ADMIN_USER copy drivefile $SOURCE_DRIVE_ID parentid $TARGET_DRIVE_ID recursive duplicatefiles overwriteolder"
}

mode_subdir() {
    log "=== MODO: SUBDIRECTORIO ESPECÍFICO ==="
    if [[ -z "$SOURCE_FOLDER_ID" || -z "$TARGET_FOLDER_ID" || "$SOURCE_FOLDER_ID" == "ID_"* ]]; then
        log "Error: Faltan los IDs de Subdirectorios en config.env"
        exit 1
    fi
    run_gam_cmd "gam user $ADMIN_USER copy drivefile $SOURCE_FOLDER_ID parentid $TARGET_FOLDER_ID recursive duplicatefiles overwriteolder"
}

mode_individual() {
    log "=== MODO: ELEMENTOS INDIVIDUALES ==="
    if [ ! -f "$ITEMS_CSV_PATH" ]; then
        log "Error: Archivo CSV no encontrado en $ITEMS_CSV_PATH"
        exit 1
    fi
    log "Iniciando procesamiento bulk con CSV..."
    run_gam_cmd "gam csv $ITEMS_CSV_PATH gam user $ADMIN_USER copy drivefile \"~Source_ID\" parentid \"~Target_Parent_ID\" duplicatefiles overwriteolder"
}

# ==============================================================================
# Lógica Principal
# ==============================================================================
log "Iniciando script de sincronización."
log "Modo seleccionado: $SYNC_MODE"

case "$SYNC_MODE" in
    "FULL")
        mode_full
        ;;
    "SUBDIR")
        mode_subdir
        ;;
    "INDIVIDUAL")
        mode_individual
        ;;
    *)
        log "Error: Modo $SYNC_MODE no soportado. Opciones: FULL, SUBDIR, INDIVIDUAL."
        exit 1
        ;;
esac

log "Ejecución finalizada con éxito."
exit 0
