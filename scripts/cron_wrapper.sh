#!/bin/bash
# ==============================================================================
# Script Wrapper de Cron para Sincronización Nocturna
# Fase 3: Ejecución desatendida y Rotación de logs
# ==============================================================================

# Forzar ejecución desde el directorio raíz del proyecto
# Esto asegura que si cron llama el script desde otro directorio, 
# todas las rutas relativas (como config.env y logs/) sigan funcionando.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR" || { echo "Error: No se pudo cambiar al directorio $DIR"; exit 1; }

LOG_DIR="./logs"
DAYS_TO_KEEP=30

echo "Iniciando ejecución nocturna desatendida..."

# 1. Rotación de Logs (Mantenimiento)
# Busca y elimina archivos en la carpeta de logs que tengan más de $DAYS_TO_KEEP días
if [ -d "$LOG_DIR" ]; then
    echo "Limpiando logs con más de $DAYS_TO_KEEP días de antigüedad..."
    find "$LOG_DIR" -type f -name "sync_*.log" -mtime +$DAYS_TO_KEEP -exec rm {} \;
fi

# 2. Ejecutar el proceso de sincronización principal
# Al invocar sync_gam.sh se generará automáticamente su propio archivo log
echo "Lanzando sync_gam.sh..."
./scripts/sync_gam.sh

# Capturar el código de salida
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "Ejecución nocturna finalizada exitosamente."
else
    echo "Ejecución nocturna finalizada con errores (Código: $exit_code)."
    # Aquí se podría agregar, por ejemplo, el envío de un correo de alerta usando mailutils o ssmtp
fi

exit $exit_code
