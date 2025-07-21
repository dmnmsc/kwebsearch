# 📘 KWebSearch — Buscador gráfico personalizado para KDE

**Versión:** v1.0  
**Autor:** JP  
**Licencia:** [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html)  
**Entorno recomendado:** KDE Plasma con kdialog  
**Idioma:** Español

---

## 🎯 ¿Qué es?

KWebSearch es un script Bash con interfaz visual en `kdialog` que te permite realizar búsquedas web rápidas usando alias personalizables. Está diseñado para usuarios KDE que buscan un acceso instantáneo a servicios online como Google, Wikipedia, YouTube, GitHub, AUR, diccionarios y muchos más, todo desde su escritorio.

Incluye soporte para bangs de DuckDuckGo, edición de alias, historial, backup automático y restauración gráfica.

---

## ⚙️ Características

- 🔎 Alias personalizados para búsquedas específicas
- 🧠 Alias por defecto configurable
- 📘 Menú visual interactivo (`_config`)
- ✏️ Edición rápida del archivo de alias
- 🧹 Limpieza de historial desde interfaz
- 📤 Exportación de configuración e historial con fecha
- 📥 Restauración del último backup disponible
- 🔄 Reset de alias por defecto a DuckDuckGo
- 🧾 Ayuda integrada accesible con `_help`
- 🌐 Compatible con bangs de DuckDuckGo

---

## 📦 Requisitos

- KDE Plasma / Entorno con soporte de `kdialog`
- Bash 4.x o superior
- `xdg-open` instalado
- Navegador web configurado como predeterminado

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

## 🔧 Alias incluidos

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
| .c    | SoftCatalà           | Sinònims en catalán      |
| e     | WordReference (EN)   | Definiciones inglés      |
| .e    | WordReference        | Sinónimos inglés         |
| aur   | AUR (Arch Linux)     | Paquetes comunitarios    |
| gh    | GitHub               | Repositorios             |
| trans | Google Translate     | Traducción automática    |

---

## 🛠️ Comandos especiales

| Comando         | Función                                 |
|-----------------|------------------------------------------|
| `_config`       | Menú principal con todas las opciones    |
| `_alias`        | Selector de alias visual                 |
| `_edit`         | Editar el archivo de alias manualmente   |
| `_clear`        | Borrar historial completo                |
| `_default`      | Definir alias por defecto                |
| `_resetalias`   | Restablecer alias por defecto a DuckDuckGo |
| `_exportconfig` | Crear backup con historial incluido      |
| `_importconfig` | Restaurar el último backup disponible    |
| `_help`         | Ver ayuda rápida                         |
| `_exit`         | Salir del script                         |

---

## 📂 Estructura de archivos

- `~/kwebsearch/`
  - `kwebsearch.conf` → Archivo principal de alias
  - `kwebsearch_backup_YYYY-MM-DD_HH-MM-SS/` → Carpeta de cada backup
- `~/.kwebsearch_history` → Historial de consultas realizadas

## 🛡️ Licencia

Este proyecto está licenciado bajo la **GNU General Public License v3.0**

Puedes ver el texto completo en [`LICENSE.md`](./LICENSE.md) o visitar el sitio oficial:  
🔗 https://www.gnu.org/licenses/gpl-3.0.html

> El código fuente, así como cualquier versión modificada o distribuida, debe mantenerse como código abierto bajo esta misma licencia.

