# 📘 KWebSearch — Buscador gráfico personalizado para KDE

**Versión:** v1.1  
**Autor:** dmnmsc  
**Licencia:** [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html)  
**Entorno recomendado:** KDE Plasma con kdialog  
**Idioma:** Español

---

## 🎯 ¿Qué es?

KWebSearch es un script Bash con interfaz visual en `kdialog` que te permite realizar búsquedas web rápidas usando alias personalizables. Está diseñado para usuarios KDE que buscan un acceso instantáneo a servicios online como Google, Wikipedia, YouTube, GitHub, AUR, diccionarios y muchos más, todo desde su escritorio.

Incluye soporte para bangs de DuckDuckGo, creación de alias nuevos desde interfaz gráfica, historial con selector visual, backup automático y restauración gráfica.

---

## ⚙️ Características

- 🔎 Alias personalizados para búsquedas específicas, ahora también se pueden crear alias nuevos desde la interfaz  
- 🧠 Alias por defecto configurable  
- 📘 Menú visual interactivo (`_config`)  
- ✏️ Edición rápida del archivo de alias
- 🕘 Visualización del historial reciente con selección interactiva
- 🧹 Limpieza de historial desde interfaz  
- 📤 Exportación de configuración e historial con fecha  
- 📥 Restauración del último backup disponible  
- 🔄 Reset de alias por defecto a DuckDuckGo  
- 🆕 Creación de alias nuevos con `_newalias` desde interfaz gráfica  
- 🧾 Ayuda integrada accesible con `_help`  
- 🌐 Compatible con bangs de DuckDuckGo

---

## 🚀 Instalación

```bash
git clone https://github.com/dmnmsc/kwebsearch.git
cd kwebsearch
chmod +x kwebsearch.sh
./kwebsearch.sh
```
 📝 El script creará automáticamente el archivo `kwebsearch.conf` con todos los alias por defecto.

---

## 💡 Sugerencia: Asigna un atajo de teclado

Para invocar KWebSearch con mayor rapidez, se recomienda asignar un **atajo de teclado personalizado** que ejecute el script desde cualquier parte del sistema.

### En KDE Plasma:

1. Abre la app **Preferencias del sistema** → sección **Accesos rápidos**.  
2. Ve a **Accesos rápidos personalizados** → selecciona "Editar".  
3. Crea una nueva acción:  
   - **Nombre:** `KWebSearch`  
   - **Acción/Comando:** `/ruta/completa/a/kwebsearch.sh`  
   - **Acceso rápido:** elige una combinación libre, como `Meta + W` 🔁  
4. Guarda y prueba el acceso rápido.

Esto convierte tu script en una herramienta instantánea, accesible desde cualquier ventana o escritorio, sin necesidad de abrir una terminal.

> 🧠 También puedes vincularlo a un botón físico si usas dispositivos como StreamDeck, teclados programables o gestos en tu panel táctil.

---

## 🔧 Alias incluidos

Al iniciar `kwebsearch.sh` por primera vez, se crea un archivo de configuración (`kwebsearch.conf`) con una selección de alias listos para búsquedas rápidas en servicios populares.  

Cada alias es un identificador corto que puedes escribir antes de tu búsqueda para dirigir la consulta al sitio correspondiente.

| Alias | Servicio             | Descripción              |
|-------|----------------------|--------------------------|
| g     | Google               | Búsqueda clásica         |
| .g    | Google Shopping      | Productos                |
| i     | Google Imágenes      | Búsqueda visual          |
| y     | YouTube (PWA)        | Vídeos                   |
| w     | Wikipedia (ES)       | Español                  |
| .w    | Wikipedia (EN)       | Inglés                   |
| k     | Kimovil              | Comparar móviles         |
| .k    | GSMArena             | Fichas técnicas          |
| a     | Amazon               | Productos en España      |
| .a    | Amazon (Incógnito)   | Navegador Chromium       |
| d     | RAE                  | Diccionario español      |
| .d    | WordReference        | Sinónimos en español     |
| c     | DIEC (IEC)           | Diccionario catalán      |
| .c    | SoftCatalà           | Sinónimos en catalán     |
| e     | WordReference (EN)   | Definiciones inglés      |
| .e    | WordReference        | Sinónimos inglés         |
| aur   | AUR (Arch Linux)     | Paquetes comunitarios    |
| gh    | GitHub               | Repositorios             |
| trans | Google Translate     | Traducción automática    |

> **ℹ️ Puedes consultar la lista completa de alias con el comando especial `_alias` o revisando el archivo `kwebsearch.conf`.**
> 
## ⚙️ Personalización avanzada de alias

Puedes adaptar `kwebsearch.sh` a tus necesidades agregando, modificando o eliminando alias **desde la interfaz gráfica** del propio script, sin editar archivos manualmente.  

Cada alias tiene tres componentes: **nombre**, **descripción** y **URL de búsqueda** (donde `$query` será reemplazado por lo que busques).

### ➕ ¿Cómo crear o editar alias?

1. **Usa el comando especial:**  
   Escribe `_newalias` para crear uno nuevo, o `_edit` para modificar uno existente, desde la ventana de búsqueda.

2. **Completa los campos en el diálogo gráfico:**  
   - **Alias**: palabra corta (ejemplo: `eco`)
   - **Descripción**: indica a qué sitio corresponde (`Ecosia`)
   - **URL**: dirección de búsqueda, usando `$query` como marcador  
     Ejemplo para Ecosia:  
     ```
     https://www.ecosia.org/search?q=$query
     ```

3. **Guarda y prueba el nuevo alias:**  
   Por ejemplo, si creaste un alias `eco` para Ecosia, escribe `eco:github` en la ventana principal.
---

## 🛠️ Comandos especiales

| Comando         | Función                                  |
|-----------------|------------------------------------------|
| `_config`       | Menú principal con todas las opciones    |
| `_alias`        | Selector de alias visual                 |
| `_newalias`     | Crear un alias nuevo desde interfaz      |
| `_edit`         | Editar el archivo de alias manualmente   |
| `_default`      | Definir alias por defecto                |
| `_resetalias`   | Restablecer alias por defecto a DuckDuckGo |
| `_history`      | Ver historial reciente de búsquedas      |
| `_clear`        | Borrar historial completo                |
| `_backup`       | Crear backup con historial incluido      |
| `_restore`      | Restaurar backup                         |
| `_help`         | Ver ayuda rápida                         |
| `_exit`         | Salir del script                         |

---

## 📂 Estructura de archivos

- `~/kwebsearch/`  
  - `kwebsearch.conf` → Archivo principal de alias  
  - `kwebsearch_backup_YYYY-MM-DD_HH-MM-SS/` → Carpeta de cada backup  
- `~/.kwebsearch_history` → Historial de consultas realizadas

---

## 🛡️ Licencia

Este proyecto está licenciado bajo la **GNU General Public License v3.0**

Puedes ver el texto completo en [`LICENSE.md`](./LICENSE.md) o visitar el sitio oficial:  
🔗 https://www.gnu.org/licenses/gpl-3.0.html

> El código fuente, así como cualquier versión modificada o distribuida, debe mantenerse como código abierto bajo esta misma licencia.
