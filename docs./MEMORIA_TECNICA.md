# Memoria Técnica —  Mantenimiento del Sistema Linux en Bash

**Materia:** Sistemas Operativos

**Instituto:** Instituto Superior IDRA — Tecnicatura Superior en Desarrollo de Software

**Integrantes:** Nicolas Olivarez, Rodrigo Curcuy y Jeremias Maglione

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
| Sistema operativo | Linux (Raspberry Pi OS en VirtualBox; también funciona en Debian) |
| Intérprete | Bash |
| Herramientas | `tar`, `gzip`, `find`, `sort`, `head`, `awk`, `df`, `du`, `free`, `numfmt`, `tee` |
| Permisos | Usuario común (no requiere `sudo`) |
| Dependencias a instalar | Ninguna: todas vienen con el sistema |

Ejecución:

```bash
git clone https://github.com/nicolasolivarez10-gif/TPFinal.git
cd TPFinal
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

⚙️ 3.3 — Carga de la configuración
Objetivo: Encontrar la carpeta del programa y cargar la configuración.

DIR_SCRIPT="$(cd "$(dirname "$0")" && pwd)"
source "$DIR_SCRIPT/config.conf"

Comando	¿Qué hace?
$0	Indica cómo se ejecutó el script.
dirname	Obtiene la carpeta del script.
source	Carga las variables de configuración.

  <row align="center" gap={2}>
    <icon name="check-circle" color="success"/>
    <text size="sm">**Resultado:** El programa utiliza los valores configurados.</text>
  </row>
  <divider/>
  <title size="xl">📦 3.5 — Tarea 1: Respaldo</title>
  <row align="center" gap={2}>
    <icon name="info" color="info"/>
    **Objetivo:** Crear una copia de seguridad comprimida.
  </row>
  <grid columns={3} gap={2}>
    {#each [{n:"1",t:"Seleccionar",i:"folder"},{n:"2",t:"Verificar",i:"shield-check"},{n:"3",t:"Comprimir",i:"archive"}] as s}
      <grid-item>
        <box background="surface-secondary" radius="md" padding={2} align="center" gap={1}>
          <icon name={s.i} color="secondary" size="lg"/>
          <text weight="medium" size="xs">{s.n}. {s.t}</text>
        </box>
      </grid-item>
    {/each}
  </grid>
  <caption>El resto de las secciones sigue el mismo estilo, con tablas, comandos, pasos y resultados.</caption>
</box>
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
- 
![Menu del programa](VirtualBox_Nicolas_08_11_2026_18_48_34.png)
---

## 4. Pruebas y validación

### Validación del menú

Ingresar `x`, `9` y una entrada vacía. Resultado esperado:

```
[ERROR] Opción inválida: 'x'. Ingrese un número del 0 al 3.
```
![Validacion del menu](VirtualBox_Nicolas_08_11_2026_19_04_17.png)
![Validacion del menu](VirtualBox_Nicolas_08_11_2026_19_04_45.png)
### Opción 1 — Respaldo

Directorio: `~/prueba/datos`. Resultado obtenido:

![Respaldo de directorio:](VirtualBox_Nicolas_08_11_2026_20_51_33.png)

Con un directorio inexistente se muestra `[ERROR] El directorio '...' no existe.`

![No existe directorio](VirtualBox_Nicolas_08_11_2026_21_22_54.png)


### Opción 2 — Informe de recursos

Se verifica que el informe quedó guardado: `cat logs/informe_recursos.log`. 

![Informe de recursos](VirtualBox_Nicolas_08_11_2026_20_50_39.png)

### Opción 3 — Archivos grandes

![Archivos grandes](VirtualBox_Nicolas_08_11_2026_20_51_15.png)

Con mínimo `abc` se muestra `[ERROR] El tamaño debe ser un número entero positivo`. Con un mínimo mayor al archivo más grande, informa que no se encontraron archivos.

![Error archivos grandes](VirtualBox_Nicolas_08_11_2026_20_52_39.png)

### Opción 0 — Salir

Muestra "Hasta luego." y termina el script. El log `logs/mantenimiento.log` queda con el registro de todo lo realizado:

![Salir](VirtualBox_Nicolas_08_11_2026_21_07_00.png)

---

## 5. Reflexiones finales

### Conclusión

El trabajo permitió aplicar en un caso concreto conceptos de la cursada: comandos de archivos y procesos, redirecciones y tuberías, compresión con `tar`, búsqueda con `find`, lectura de `/proc` y scripting en Bash. Un script modular, con funciones y archivo de configuración, es fácil de entender y de ampliar.

---

## 6. Referencias

- `man bash`, `man find`, `man tar`, `man df`, `man free`
- Apuntes de la cátedra: *Linux Bash Shell Cheat Sheet* y *Markdown Cheat Sheet* (opensource.com)

---

## 7. Dificultades encontradas
.Instalacion de virtualbox por mal configuramiento

.Problemas en los script por error en el codigo

