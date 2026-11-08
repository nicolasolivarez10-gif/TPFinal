#!/bin/bash
#==============================================================================
# mantenimiento.sh - Trabajo Final de Sistemas Operativos (IDRA)
#
# Menú interactivo con 3 tareas:
#   1) Respaldo de un directorio (tar.gz) + borrado de backups antiguos
#   2) Informe de uso de CPU, memoria y disco (se guarda en un log)
#   3) Detección de archivos grandes (informe ordenado por tamaño)
#
# Uso:  ./mantenimiento.sh
#==============================================================================

#------------------------------------------------------------------------------
# 1. COLORES (códigos ANSI para la terminal)
#------------------------------------------------------------------------------
ROJO='\e[1;31m'
VERDE='\e[1;32m'
AMARILLO='\e[1;33m'
CIAN='\e[1;36m'
RESET='\e[0m'

#------------------------------------------------------------------------------
# 2. CONFIGURACIÓN (se lee del archivo config.conf)
#------------------------------------------------------------------------------
# Carpeta donde está este script (sirve para ubicar config.conf y los logs)
DIR_SCRIPT="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "$DIR_SCRIPT/config.conf" ]; then
    echo -e "${ROJO}Error: no se encuentra config.conf en $DIR_SCRIPT${RESET}"
    exit 1
fi
source "$DIR_SCRIPT/config.conf"      # carga las variables del archivo

mkdir -p "$DIR_LOGS"
LOG="$DIR_LOGS/mantenimiento.log"

#------------------------------------------------------------------------------
# 3. FUNCIONES AUXILIARES
#------------------------------------------------------------------------------

# Escribe una línea con fecha y hora en el log
registrar() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG"
}

# Mensajes con colores (también quedan en el log)
mensaje_ok() {
    echo -e "${VERDE}[OK] $1${RESET}"
    registrar "OK: $1"
}
mensaje_error() {
    echo -e "${ROJO}[ERROR] $1${RESET}"
    registrar "ERROR: $1"
}
mensaje_info() {
    echo -e "${AMARILLO}[i] $1${RESET}"
}

pausar() {
    echo
    read -r -p "Presione Enter para volver al menú..."
}

# Devuelve verdadero (0) si el texto es un número entero mayor que 0
es_numero_positivo() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ]
}

#------------------------------------------------------------------------------
# 4. TAREA 1: RESPALDO DE UN DIRECTORIO
#------------------------------------------------------------------------------
tarea_backup() {
    echo -e "\n${CIAN}=== RESPALDO DE DIRECTORIO ===${RESET}"

    # Pedimos el directorio; si el usuario solo presiona Enter, usamos el de config.conf
    read -r -p "Directorio a respaldar [$ORIGEN_BACKUP]: " origen
    origen="${origen:-$ORIGEN_BACKUP}"
    origen="${origen/#\~/$HOME}"            # convierte ~ en /home/usuario

    # Validamos que exista
    if [ ! -d "$origen" ]; then
        mensaje_error "El directorio '$origen' no existe."
        return
    fi
    origen="$(readlink -f "$origen")"       # ruta absoluta completa

    mkdir -p "$DESTINO_BACKUP"
    destino="$(readlink -f "$DESTINO_BACKUP")"

    # El backup no puede guardarse dentro de la carpeta que se está respaldando
    case "$destino/" in
        "$origen"/*)
            mensaje_error "La carpeta de backups no puede estar dentro del origen."
            return ;;
    esac

    # Nombre del archivo: backup_<carpeta>_<fecha>_<hora>.tar.gz
    nombre="$(basename "$origen")"
    archivo="$destino/backup_${nombre}_$(date +%Y%m%d_%H%M%S).tar.gz"

    mensaje_info "Comprimiendo '$origen' ..."
    if tar -czf "$archivo" -C "$(dirname "$origen")" "$nombre"; then
        mensaje_ok "Backup creado: $archivo ($(du -h "$archivo" | cut -f1))"
    else
        mensaje_error "No se pudo crear el backup."
        rm -f "$archivo"
        return
    fi

    # Borrar backups con más de DIAS_BACKUP días (solo los de esta carpeta)
    mensaje_info "Buscando backups con más de $DIAS_BACKUP días..."
    viejos="$(find "$destino" -maxdepth 1 -type f -name "backup_${nombre}_*.tar.gz" \
              -mtime +"$DIAS_BACKUP" -print -delete)"

    if [ -z "$viejos" ]; then
        mensaje_info "No había backups antiguos para borrar."
    else
        mensaje_ok "Backups antiguos eliminados:"
        echo "$viejos"
    fi
}

#------------------------------------------------------------------------------
# 5. TAREA 2: INFORME DE CPU, MEMORIA Y DISCO
#------------------------------------------------------------------------------

# Calcula el % de uso de CPU. /proc/stat tiene contadores acumulados desde el
# arranque, por eso se leen dos veces con 1 segundo de diferencia.
uso_cpu() {
    local u1 n1 s1 i1 w1 q1 sq1 st1 u2 n2 s2 i2 w2 q2 sq2 st2
    read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
    sleep 1
    read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat

    local total=$(( (u2+n2+s2+i2+w2+q2+sq2+st2) - (u1+n1+s1+i1+w1+q1+sq1+st1) ))
    local ocioso=$(( (i2+w2) - (i1+w1) ))

    # Bash no maneja decimales, por eso usamos awk para la división
    awk -v t="$total" -v o="$ocioso" 'BEGIN { if (t > 0) printf "%.1f", (t-o)*100/t; else print "0.0" }'
}

# Arma el informe y lo imprime (después se guarda con tee)
generar_informe() {
    echo "=============================================="
    echo " INFORME DE RECURSOS - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=============================================="
    echo "--- CPU ---"
    echo "Uso actual de CPU : $(uso_cpu) %"
    echo "Carga promedio    : $(cut -d' ' -f1-3 /proc/loadavg)  (1, 5 y 15 min)"
    echo
    echo "--- MEMORIA ---"
    # LC_ALL=C fuerza el idioma inglés para que free siempre escriba "Mem:"
    LC_ALL=C free -m | awk '/^Mem:/ { printf "RAM: %d MB usados de %d MB (%.1f%%)\n", $3, $2, $3*100/$2 }'
    echo
    echo "--- DISCO ---"
    df -h -x tmpfs -x devtmpfs
    echo
}

tarea_informe() {
    echo -e "\n${CIAN}=== INFORME DE CPU, MEMORIA Y DISCO ===${RESET}\n"
    # tee -a muestra el informe en pantalla Y lo agrega al archivo de log
    generar_informe | tee -a "$DIR_LOGS/informe_recursos.log"
    mensaje_ok "Informe guardado en $DIR_LOGS/informe_recursos.log"
}

#------------------------------------------------------------------------------
# 6. TAREA 3: DETECTAR ARCHIVOS GRANDES
#------------------------------------------------------------------------------
tarea_grandes() {
    echo -e "\n${CIAN}=== DETECTAR ARCHIVOS GRANDES ===${RESET}"

    read -r -p "Directorio a analizar [$DIR_GRANDES]: " dir
    dir="${dir:-$DIR_GRANDES}"
    dir="${dir/#\~/$HOME}"

    read -r -p "Tamaño mínimo en MB [$MB_GRANDES]: " mb
    mb="${mb:-$MB_GRANDES}"

    # Validaciones
    if [ ! -d "$dir" ]; then
        mensaje_error "El directorio '$dir' no existe."
        return
    fi
    if ! es_numero_positivo "$mb"; then
        mensaje_error "El tamaño debe ser un número entero positivo (ingresó '$mb')."
        return
    fi

    mensaje_info "Buscando archivos de más de $mb MB en '$dir' ..."
    local informe="$DIR_LOGS/archivos_grandes.log"
    local bytes=$(( mb * 1024 * 1024 ))
    local cantidad=0

    echo "Informe de archivos grandes - $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$informe"
    echo "Directorio: $dir | Mínimo: $mb MB" | tee -a "$informe"
    printf '%-10s %s\n' "TAMAÑO" "UBICACIÓN" | tee -a "$informe"

    # find imprime "tamaño<TAB>ruta"; sort -rn ordena de mayor a menor;
    # head deja solo los primeros N. 2>/dev/null oculta los "permiso denegado".
    while IFS=$'\t' read -r tam ruta; do
        printf '%-10s %s\n' "$(numfmt --to=iec "$tam")" "$ruta" | tee -a "$informe"
        cantidad=$((cantidad + 1))
    done < <(find "$dir" -type f -size +"${bytes}"c -printf '%s\t%p\n' 2>/dev/null \
             | sort -rn | head -n "$CANTIDAD_GRANDES")

    if [ "$cantidad" -eq 0 ]; then
        mensaje_info "No se encontraron archivos mayores a $mb MB."
    else
        mensaje_ok "Se listaron $cantidad archivo(s). Informe en $informe"
    fi
}

#------------------------------------------------------------------------------
# 7. MENÚ INTERACTIVO
#------------------------------------------------------------------------------
mostrar_menu() {
    clear
    echo -e "${CIAN}=====================================================${RESET}"
    echo -e "   HERRAMIENTA DE MANTENIMIENTO DEL SISTEMA"
    echo -e "${CIAN}=====================================================${RESET}"
    echo -e "  ${VERDE}1)${RESET} Respaldo de un directorio"
    echo -e "  ${VERDE}2)${RESET} Informe de CPU, memoria y disco"
    echo -e "  ${VERDE}3)${RESET} Detectar archivos grandes"
    echo -e "  ${ROJO}0)${RESET} Salir"
    echo -e "${CIAN}-----------------------------------------------------${RESET}"
}

registrar "Script iniciado por $(whoami)"

while true; do
    mostrar_menu
    read -r -p "Seleccione una opción [0-3]: " opcion

    # Validación de entrada: solo se aceptan los dígitos 0, 1, 2 o 3
    if [[ ! "$opcion" =~ ^[0-3]$ ]]; then
        mensaje_error "Opción inválida: '$opcion'. Ingrese un número del 0 al 3."
        sleep 2
        continue
    fi

    case "$opcion" in
        1) tarea_backup;  pausar ;;
        2) tarea_informe; pausar ;;
        3) tarea_grandes; pausar ;;
        0) echo -e "${VERDE}Hasta luego.${RESET}"
           registrar "Script finalizado"
           exit 0 ;;
    esac
done
