# 📘 KWebSearch — Buscador gráfico personalizado para KDE

**Versión:** 1.2  
**Autor:** dmnmsc  
**Licencia:** [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html)  
**Entorno recomendado:** KDE Plasma con kdialog  
**Idioma:** Español

---

## 🎯 ¿Qué es?

KWebSearch es un script Bash con interfaz visual en `kdialog` que te permite realizar búsquedas web rápidas usando alias personalizables. Está diseñado para usuarios KDE que buscan un acceso instantáneo a servicios online como Google, Wikipedia, YouTube, GitHub, AUR, diccionarios y muchos más, todo desde su escritorio.

Incluye soporte para bangs de DuckDuckGo, creación de alias nuevos desde interfaz gráfica, historial con selector visual, backups organizados por fecha, restauración gráfica, y una ayuda integrada.

---

## ⚙️ Características

- 🔎 Alias personalizados para búsquedas específicas, con interfaz para crearlos fácilmente
- 🧠 Alias por defecto configurable o reseteable (a DuckDuckGo)
- 🔄 **Menú visual principal (`_menu`) con todas las funciones**
- ✏️ Edición rápida del archivo de alias desde el script
- 🕘 Visualización del historial con selección interactiva
- 🧹 Limpieza de historial desde la interfaz
- 📤 Exportación de configuración e historial con fecha única
- 📥 Restauración de backups guardados desde selector gráfico
- 🆕 Comando `_newalias` para añadir alias sin tocar archivos
- 🧾 Ayuda rápida con `_help`
- 🧠 **Nuevo comando `_about` para ver información de versión**
- 🌐 Compatible con bangs de DuckDuckGo (`!g`, `!yt`, `!aur`, etc.)

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

| Alias | Servicio             | Descripción              | Ejemplo de uso                   |
|-------|----------------------|--------------------------|-----------------------------------|
| g     | Google               | Búsqueda clásica         | `g:inteligencia artificial`       |
| .g    | Google Shopping      | Productos                | `.g:smartwatch deporte`           |
| i     | Google Imágenes      | Búsqueda visual          | `i:noche estrellada`              |
| y     | YouTube (PWA)        | Vídeos                   | `y:linux tutorial español`        |
| w     | Wikipedia (ES)       | Español                  | `w:teoría cuántica`               |
| .w    | Wikipedia (EN)       | Inglés                   | `.w:quantum theory`               |
| k     | Kimovil              | Comparar móviles         | `k:xiaomi redmi note 12`          |
| .k    | GSMArena             | Fichas técnicas          | `.k:samsung galaxy s23 ultra`     |
| a     | Amazon               | Productos en España      | `a:disco duro ssd externo`        |
| .a    | Amazon (Incógnito)   | Navegador Chromium       | `.a:raspberry pi 5`               |
| d     | RAE                  | Diccionario español      | `d:resiliencia`                   |
| .d    | WordReference        | Sinónimos en español     | `.d:rápido`                       |
| c     | DIEC (IEC)           | Diccionario catalán      | `c:llibertat`                     |
| .c    | SoftCatalà           | Sinónimos en catalán     | `.c:bonic`                        |
| e     | WordReference (EN)   | Definiciones inglés      | `e:tired`                         |
| .e    | WordReference        | Sinónimos inglés         | `.e:fast`                         |
| aur   | AUR (Arch Linux)     | Paquetes comunitarios    | `aur:kdialog`                     |
| gh    | GitHub               | Repositorios             | `gh:mpv`                          |
| trans | Google Translate     | Traducción automática    | `trans:I won't give up`           |


> **ℹ️ Puedes consultar la lista completa de alias con el comando especial `_alias` o revisando el archivo `kwebsearch.conf`.**
> 
## ⚙️ Personalización avanzada de alias

Puedes adaptar `kwebsearch.sh` a tus necesidades agregando, modificando o eliminando alias **desde la interfaz gráfica** del propio script, sin editar archivos manualmente.  

Cada alias tiene tres componentes: **nombre**, **descripción** y **URL de búsqueda** (donde `$query` será reemplazado por lo que busques).

### ➕ ¿Cómo crear o editar alias?

1. **Usa el comando especial:**  
   Escribe `_newalias` para crear uno nuevo, o `_edit` para modificar uno existente.

2. **Completa los campos en el diálogo gráfico:**  
   - **Alias**: palabra corta (ejemplo: `eco`)
   - **Descripción**: indica a qué sitio corresponde (`Ecosia`)
   - **URL**: dirección de búsqueda, usando `$query` como marcador  

     Ejemplo para Ecosia:  
     ```
     https://www.ecosia.org/search?q=$query
     ```

3. **Guarda y prueba el nuevo alias:**  
   Escribe `eco:github` en la ventana principal.
---

## 🛠️ Comandos especiales

| Comando         | Función                                      |
|-----------------|----------------------------------------------|
| `_menu` 🔄      | **Nuevo nombre del menú principal**          |
| `_alias`        | Selector visual de alias                     |
| `_newalias`     | Crear alias desde interfaz                   |
| `_edit`         | Editar alias manualmente                     |
| `_default`      | Establecer alias por defecto                 |
| `_resetalias`   | Restablecer alias por defecto a DuckDuckGo  |
| `_history`      | Ver historial de búsquedas                   |
| `_clear`        | Borrar historial completo                    |
| `_backup`       | Crear copia de seguridad                     |
| `_restore`      | Restaurar una copia anterior                 |
| `_help`         | Mostrar ayuda integrada                      |
| `_about` 🆕     | Ver información de versión y autoría         |
| `_exit`         | Salir del script                             |

---

## 📂 Estructura de archivos

- `~/kwebsearch/`  
  - `kwebsearch.conf` → Archivo principal de alias  
  - `kwebsearch_backup_YYYY-MM-DD_HH-MM-SS/` → Copias de seguridad  
- `~/.kwebsearch_history` → Historial de consultas realizadas

---

## 🛡️ Licencia

Este proyecto está licenciado bajo la **GNU General Public License v3.0**

Puedes ver el texto completo en [`LICENSE.md`](./LICENSE.md) o visitar el sitio oficial:  
🔗 https://www.gnu.org/licenses/gpl-3.0.html

> El código fuente, así como cualquier versión modificada o distribuida, debe mantenerse como código abierto bajo esta misma licencia.
