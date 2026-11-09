# 🛠️ Administracion de un sistema Linux

Trabajo Final de **Sistemas Operativos** — Tecnicatura Superior en Desarrollo de Software, Instituto Superior IDRA.

**Integrantes:** Nicolas Olivarez, Rodrigo Curcuy y Jeremias Maglione.

## Descripción

Script en Bash con un **menú interactivo** que automatiza tres tareas de administración de un sistema Linux:

| Opción | Tarea | Qué hace |
|:------:|-------|----------|
| 1 | Respaldo | Comprime un directorio en `.tar.gz` y elimina los backups más viejos que N días |
| 2 | Informe de recursos | Muestra y guarda en un log el uso de CPU, memoria y disco |
| 3 | Archivos grandes | Busca archivos que superen un tamaño configurable y los lista de mayor a menor con su ubicación |
| 0 | Salir | Detiene la ejecución del script |

Incluye validación de entradas y un archivo de configuración (`config.conf`).

## Estructura

```
trabajo-final-so/
├── mantenimiento.sh        # Script principal
├── config.conf             # Parámetros configurables
├── docs/MEMORIA_TECNICA.md # Memoria técnica
├── logs/                   # Logs generados al ejecutar
├── LICENSE
└── README.md
```

## Requisitos

- Linux con Bash (probado en Raspberry Pi OS / Debian)
- Herramientas estándar que ya vienen instaladas en linux: `tar`, `find`, `df`, `free`, `numfmt`
- tar: arma el archivo comprimido del backup (opción 1).
- find: busca archivos. Lo usa para borrar los backups viejos (opción 1) y para encontrar los archivos grandes (opción 3).
- df: muestra el espacio usado y libre de los discos (opción 2).
- free: muestra la memoria RAM usada y libre (opción 2).
- numfmt: convierte números grandes a un formato legible. Por ejemplo, 12582912 pasa a verse como 12M (opción 3).
- No requiere permisos de administrador

## Uso

```bash
git clone https://github.com/<usuario>/trabajo-final-so.git
cd trabajo-final-so
chmod +x mantenimiento.sh
./mantenimiento.sh
```

En cada pregunta se puede presionar **Enter** para usar el valor de `config.conf`.

## Configuración

Editar `config.conf` (no hace falta tocar el código):

```bash
ORIGEN_BACKUP="$HOME/Documents"   # carpeta a respaldar
DESTINO_BACKUP="$HOME/backups"    # dónde se guardan los backups
DIAS_BACKUP=7                     # antigüedad máxima de los backups
DIR_GRANDES="$HOME"               # carpeta a analizar
MB_GRANDES=100                    # tamaño mínimo (MB)
CANTIDAD_GRANDES=20               # máximo de archivos listados
```

## Logs (carpeta `logs/`)

- `mantenimiento.log`: registro general con fecha y hora de cada acción
- `informe_recursos.log`: informes de CPU, memoria y disco
- `archivos_grandes.log`: informes de archivos grandes

## Cómo colaborar
-Hacer un fork del repositorio.
-Crear una rama: git checkout -b feature/mi-mejora.
-Verificar la sintaxis con bash -n mantenimiento.sh.
-Hacer commit y subir la rama.
-Abrir un Pull Request explicando el cambio.
## Licencia

-Distribuido bajo la licencia MIT. Ver LICENSE.
