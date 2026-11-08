# Memoria Técnica — Herramienta de Mantenimiento del Sistema en Bash

**Materia:** Sistemas Operativos
**Instituto:** Instituto Superior IDRA — Tecnicatura Superior en Desarrollo de Software
**Integrantes:** _(completar)_
**Fecha:** Noviembre de 2026

---

## 1. Introducción

### 1.1 Descripción del proyecto

El proyecto es un script en Bash (`mantenimiento.sh`) que presenta un **menú interactivo** para ejecutar tareas de mantenimiento en un sistema Linux. Evita que el administrador tenga que escribir a mano comandos largos y deja un registro (log) de lo que se hizo.

Se desarrolló y probó en una máquina virtual (VirtualBox) con Raspberry Pi OS, una distribución basada en Debian.

### 1.2 Tareas automatizadas

| Opción | Tarea | Función en el script |
|:------:|-------|----------------------|
| 1 | Respaldo de un directorio en un archivo comprimido y eliminación de backups antiguos | `tarea_backup` |
| 2 | Informe del uso de CPU, memoria y disco guardado en un archivo log | `tarea_informe` |
| 3 | Detección de archivos grandes con informe ordenado por tamaño | `tarea_grandes` |

### 1.3 Extras opcionales implementados

- **Validación de entrada:** el menú solo acepta 0, 1, 2 o 3, y cada dato que se ingresa se verifica.
- **Archivo de configuración** (`config.conf`) para cambiar rutas y parámetros sin editar el código.

---

## 2. Requisitos técnicos

| Requisito | Detalle |
|-----------|---------|
| Sistema operativo | Linux (Raspberry Pi OS en VirtualBox; también funciona en Debian/Ubuntu) |
| Intérprete | Bash |
| Herramientas | `tar`, `gzip`, `find`, `sort`, `head`, `awk`, `df`, `du`, `free`, `numfmt`, `tee` |
| Permisos | Usuario común (no requiere `sudo`) |
| Dependencias a instalar | Ninguna: todas vienen con el sistema |

Ejecución:

```bash
git clone https://github.com/<usuario>/trabajo-final-so.git
cd trabajo-final-so
chmod +x mantenimiento.sh
./mantenimiento.sh
```

---

## 3. Desarrollo (explicación del código)

### 3.1 Estructura del script

1. Colores.
2. Carga de la configuración.
3. Funciones auxiliares (`registrar`, mensajes, `pausar`, validación).
4. Las tres tareas (una función cada una).
5. El menú principal (un bucle `while`).

### 3.2 Colores

```bash
ROJO='\e[1;31m'
VERDE='\e[1;32m'
RESET='\e[0m'
echo -e "${VERDE}[OK] ...${RESET}"
```

Son códigos de escape ANSI: la terminal los interpreta como cambios de color. `echo -e` habilita la interpretación de `\e`. Se usa `RESET` para volver al color normal. Verde indica éxito, rojo error y amarillo información.

### 3.3 Carga de la configuración

```bash
DIR_SCRIPT="$(cd "$(dirname "$0")" && pwd)"
source "$DIR_SCRIPT/config.conf"
```

- `$0` es el nombre con el que se ejecutó el script y `dirname` obtiene su carpeta. Así el script encuentra `config.conf` y la carpeta `logs/` sin importar desde dónde se lo ejecute.
- `source` lee `config.conf` y define sus variables (`ORIGEN_BACKUP`, `DIAS_BACKUP`, etc.) como si estuvieran escritas dentro del script.
- Si el archivo no existe, se muestra un error y se sale con `exit 1`.

### 3.4 Funciones auxiliares

- **`registrar`**: agrega una línea con fecha y hora al log usando `>>` (redirección que **agrega** al final sin borrar lo anterior).
- **`mensaje_ok`, `mensaje_error`, `mensaje_info`**: muestran un mensaje con color; los dos primeros además lo guardan en el log.
- **`pausar`**: usa `read` para esperar un Enter antes de volver al menú, así el usuario alcanza a leer el resultado.
- **`es_numero_positivo`**: comprueba con una expresión regular `^[0-9]+$` que el texto sean solo dígitos, y con `-gt 0` que sea mayor que cero.

### 3.5 Tarea 1 — Respaldo

1. Se pregunta el directorio con `read`. `${origen:-$ORIGEN_BACKUP}` significa "si está vacío, usar el valor de la configuración".
2. Se valida con `[ ! -d "$origen" ]` que el directorio exista.
3. `readlink -f` convierte las rutas a absolutas y se verifica que la carpeta de backups no esté dentro de la carpeta a respaldar (si no, el backup se incluiría a sí mismo).
4. Se arma el nombre `backup_<carpeta>_AAAAMMDD_HHMMSS.tar.gz` con `date`.
5. Se crea el archivo:
   ```bash
   tar -czf "$archivo" -C "$(dirname "$origen")" "$nombre"
   ```
   - `-c` crear, `-z` comprimir con gzip, `-f` nombre del archivo.
   - `-C` cambia de carpeta antes de archivar, para que dentro del `.tar.gz` las rutas sean relativas.
6. Si `tar` falla, se borra el archivo incompleto.
7. Se eliminan los backups viejos:
   ```bash
   find "$destino" -maxdepth 1 -type f -name "backup_${nombre}_*.tar.gz" \
        -mtime +"$DIAS_BACKUP" -print -delete
   ```
   - `-mtime +7` selecciona los archivos modificados hace **más de 7 días**.
   - `-name` limita el borrado a los backups de esa carpeta, para no eliminar archivos ajenos.
   - `-print -delete` muestra cada archivo y lo borra.

### 3.6 Tarea 2 — Informe de CPU, memoria y disco

- **CPU (`uso_cpu`)**: el archivo `/proc/stat` guarda contadores del tiempo que la CPU estuvo trabajando o ociosa *desde el arranque*. Para saber el uso *actual*, se lee dos veces con `sleep 1` entre lecturas y se calcula:

  ```
  uso % = (Δtotal − Δocioso) × 100 / Δtotal
  ```
  Bash solo trabaja con enteros, por eso la división con decimales se hace con `awk`.
- **Carga promedio**: se lee de `/proc/loadavg`.
- **Memoria**: `free -m` muestra la memoria en MB y `awk` calcula el porcentaje usado. Se antepone `LC_ALL=C` para que `free` escriba en inglés (`Mem:`) aunque el sistema esté en español (`Mem.:`).
- **Disco**: `df -h` muestra el espacio de cada partición (se excluyen las virtuales `tmpfs`).
- **Guardado**: el informe se envía por una tubería (`|`) a `tee -a`, que lo muestra en pantalla y lo agrega al archivo `logs/informe_recursos.log`.

### 3.7 Tarea 3 — Archivos grandes

```bash
find "$dir" -type f -size +"${bytes}"c -printf '%s\t%p\n' 2>/dev/null \
    | sort -rn | head -n "$CANTIDAD_GRANDES"
```

- `find -type f -size +Nc`: busca archivos de más de N bytes. El tamaño se convierte de MB a bytes (`mb * 1024 * 1024`).
- `-printf '%s\t%p\n'`: imprime el tamaño y la ruta separados por una tabulación.
- `sort -rn`: ordena numéricamente (`-n`) de mayor a menor (`-r`).
- `head -n 20`: se queda con los primeros 20.
- `2>/dev/null`: descarta los errores de "permiso denegado".
- `numfmt --to=iec`: convierte bytes a un formato legible (K, M, G).

Se valida que el directorio exista y que el tamaño ingresado sea un número entero positivo. El informe se muestra y se guarda en `logs/archivos_grandes.log`.

### 3.8 Menú interactivo

```bash
while true; do
    mostrar_menu
    read -r -p "Seleccione una opción [0-3]: " opcion
    if [[ ! "$opcion" =~ ^[0-3]$ ]]; then ... continue; fi
    case "$opcion" in
        1) tarea_backup;  pausar ;;
        ...
        0) exit 0 ;;
    esac
done
```

- `while true` repite el menú hasta que el usuario elija salir.
- La **validación** usa una expresión regular: solo acepta un único dígito entre 0 y 3. Si no, muestra un error en rojo y vuelve a mostrar el menú (`continue`).
- `case` llama a la función de la tarea elegida.
- La opción `0` ejecuta `exit 0` y detiene el script.
![Menu del programa](docs/VirtualBox_Nicolas_08_11_2026_18_48_34.png)
---

## 4. Pruebas y validación

### Validación del menú

Ingresar `x`, `9` y una entrada vacía. Resultado esperado:

```
[ERROR] Opción inválida: 'x'. Ingrese un número del 0 al 3.
```

### Opción 1 — Respaldo

Directorio: `~/prueba/datos`. Resultado obtenido:

```
[i] Comprimiendo '/tmp/p/origen' ...
[OK] Backup creado: /tmp/p/bk/backup_origen_20261108_164847.tar.gz (16K)
[i] Buscando backups con más de 7 días...
[OK] Backups antiguos eliminados:
/tmp/p/bk/backup_origen_20200101_000000.tar.gz
```


Con un directorio inexistente se muestra `[ERROR] El directorio '...' no existe.`



### 4.4 Opción 2 — Informe de recursos

```
--- CPU ---
Uso actual de CPU : 0.0 %
Carga promedio    : 0.00 0.00 0.00  (1, 5 y 15 min)
--- MEMORIA ---
RAM: 199 MB usados de 3990 MB (5.0%)
--- DISCO ---
Filesystem  Size  Used Avail Use% Mounted on
/dev/vda    252G  8.0G   10G  45% /
```

Se verifica que el informe quedó guardado: `cat logs/informe_recursos.log`. 

📷 _Captura: informe en pantalla y contenido del archivo._

### Opción 3 — Archivos grandes

Con directorio `~/prueba/datos` y mínimo 10 MB:

```
TAMAÑO     UBICACIÓN
12M        /tmp/p/origen/grande.bin
[OK] Se listaron 1 archivo(s). Informe en /tmp/p/logs/archivos_grandes.log
```

Con mínimo `abc` se muestra `[ERROR] El tamaño debe ser un número entero positivo`. Con un mínimo mayor al archivo más grande, informa que no se encontraron archivos.

📷 _Captura: listado de archivos grandes._

### 4.6 Opción 0 — Salir

Muestra "Hasta luego." y termina el script. El log `logs/mantenimiento.log` queda con el registro de todo lo realizado:

```
2026-11-08 16:48:47 - OK: Backup creado: ...
2026-11-08 16:48:48 - ERROR: El tamaño debe ser un número entero positivo (ingresó 'abc').
2026-11-08 16:48:48 - Script finalizado
```

---

## 5. Reflexiones finales

### Conclusión

El trabajo permitió aplicar en un caso concreto conceptos de la cursada: comandos de archivos y procesos, redirecciones y tuberías, compresión con `tar`, búsqueda con `find`, lectura de `/proc` y scripting en Bash. Un script modular, con funciones y archivo de configuración, es fácil de entender y de ampliar.

---

## 6. Referencias

- `man bash`, `man find`, `man tar`, `man df`, `man free`
- Apuntes de la cátedra: *Linux Bash Shell Cheat Sheet* y *Markdown Cheat Sheet* (opensource.com)
