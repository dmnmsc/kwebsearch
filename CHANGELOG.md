# 📦 kwebsearch - Registro de cambios

## v1.6.1 – 2025-08-21

### 🛠️ Mejoras
- **Modo CLI mejorado**: el prefijo para abrir URLs directamente (`>`, `~`, etc.) funciona correctamente en la terminal.
```bash
kwebsearch '>github.com'
```
- **Fallback más inteligente**: si se usa un alias inexistente, se recurre automáticamente al `DEFAULT_ALIAS` antes de abrir DuckDuckGo.

## v1.6 – 2025-08-21

## ✨ Novedades
- **Modo CLI**: ahora puedes buscar usando tus `alias` o  `bangs` directamente desde la terminal (DuckDuckGo por defecto).  

```bash
kwebsearch 'tu búsqueda'
```

## v1.5 – 2025-08-07

### 🛠️ Mejoras
- Mejorada la detección de URLs mediante prefijo.

## v1.4 – 2025-07-26

### ✨ Novedades
- Añadida opción para realizar búsquedas con Perplexity AI.
- Entrada en el menú principal para abrir URLs directamente.

### 🛠️ Mejoras
- Refactorización general del código para mejorar mantenimiento y legibilidad.
- Ejemplos ampliados para los bang (`!`) en las búsquedas.
- Modificada la frase inicial que aparece al abrir el script.

## v1.3 – 2025-07-25

### ✨ Novedades
- Soporte para abrir URLs directamente con un prefijo personalizado (por ejemplo, `>github.com` abre la web de github).
- Añadida función `_prefix` para que el usuario pueda cambiar el prefijo para abrir URLs directamente desde el script.
- Archivo de configuración `kwebsearch.conf` actualizado con explicaciones más claras y ejemplos para facilitar su uso.

### 🛠️ Mejoras
- Mejoras menores en la interfaz y el comportamiento general del script.

## v1.2 – 2025-07-24

### ✨ Novedades
- Se añade el comando `_about` para mostrar información sobre la herramienta.
- Renombrado el comando `_config` a `_menu`.

### 🛠️ Mejoras
- Sistema de copias de seguridad mejorado

### ✅ Otros
- Texto de ayuda actualizado para reflejar los nuevos comandos.

## v1.1 – 2025-07-23

### ✨ Novedades
- Añadida función `crear_alias()` para generar alias personalizados mediante interfaz gráfica guiada.
- Validaciones incluidas para clave, descripción y plantilla, asegurando el uso correcto de `$query`.
- Opción para previsualizar el alias antes de guardarlo.

### 🛠️ Mejoras
- DuckDuckGo añadido como alias vacío destacado si es el predeterminado.
- Opción para restablecer DuckDuckGo directamente desde el menú de alias.
- El menú `mostrar_alias` se refactorizó para incluir selección directa, diseño más claro y mensajes mejorados.
- Validaciones más explícitas al crear alias (clave inválida, ausencia de `$query`, comillas desbalanceadas).
- Manejo de alias mediante arrays para mejorar lógica y legibilidad.
- Uso consistente de `local` en variables internas para evitar interferencias.
- Cuadros de diálogo `kdialog` rediseñados con mejor presentación y opciones más claras.
- Comprobaciones añadidas para cancelar o salir si el usuario no ingresa datos.

### 🐞 Correcciones
- Validación mejorada para claves de alias, eliminando caracteres no permitidos y evitando duplicados.
- Refactorización del manejo del alias predeterminado y su restablecimiento, eliminando redundancias.
- Optimización en la lectura y creación del archivo de alias sin cambios funcionales relevantes.
