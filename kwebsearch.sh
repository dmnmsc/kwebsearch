#!/bin/bash
VERSION="1.3"

# ✅ Comprobar si kdialog está instalado
if ! command -v kdialog &> /dev/null; then
  echo "❌ Error: kdialog no está instalado. Este script requiere KDE o kdialog."
  exit 1
fi

# 📁 Rutas
CONF="$HOME/kwebsearch/kwebsearch.conf"
HIST="$HOME/.kwebsearch_history"
BACKUP_DIR="$HOME/kwebsearch"
mkdir -p "$BACKUP_DIR"
touch "$HIST"

# 📝 Alias inicial
if [[ ! -f "$CONF" ]]; then
cat <<EOF > "$CONF"
# 🧠 Alias por defecto (si deja vacío, se usará DuckDuckGo - powered by !bangs)
default_alias=""

# 🚀 Prefijo para abrir directamente URLs  (ej: >github.com)
cmd_prefix=">"  # Puedes cambiarlo por ~, @, ^, ::, >, etc.

# 🔎 Alias personalizados
g)xdg-open "https://www.google.com/search?q=\$query";;#Google
.g)xdg-open "https://www.google.com/search?tbm=shop&q=\$query";;#Google Shopping
i)xdg-open "https://www.google.com/search?tbm=isch&q=\$query";;#Imágenes
y)firefoxpwa site launch 01JVWMP5WE7BC62BSPRT02MPF2 --url "https://www.youtube.com/results?search_query=\$query";;#YouTube
w)xdg-open "https://es.wikipedia.org/wiki/Special:Search?search=\$query";;#Wikipedia (ES)
.w)xdg-open "https://en.wikipedia.org/wiki/Special:Search?search=\$query";;#Wikipedia (EN)
k)xdg-open "https://www.kimovil.com/es/comparar-moviles/name.\$query";;#Kimovil
.k)xdg-open "https://www.gsmarena.com/res.php3?sSearch=\$query";;#GSMArena
a)xdg-open "https://www.amazon.es/s?k=\$query";;#Amazon
.a)chromium --incognito "https://www.amazon.es/s?k=\$query";;#Amazon (Incógnito)
d)xdg-open "https://dle.rae.es/?w=\$query";;#RAE
.d)xdg-open "https://www.wordreference.com/sinonimos/\$query";;#Sinónimos español
c)xdg-open "https://dlc.iec.cat/results.asp?txtEntrada=\$query";;#DIEC
.c)xdg-open "https://www.softcatala.org/diccionari-de-sinonims/paraula/\$query";;#Sinònims catalán
e)xdg-open "https://www.wordreference.com/definition/\$query";;#Diccionario inglés
.e)xdg-open "https://www.wordreference.com/synonyms/\$query";;#Sinónimos inglés
aur)xdg-open "https://aur.archlinux.org/packages?K=\$query";;#AUR
gh)xdg-open "https://github.com/search?q=\$query";;#GitHub
trans)xdg-open "https://translate.google.com/?sl=auto&tl=es&text=\$query";;#Traductor
EOF

  kdialog --msgbox "✅ Archivo de alias creado en:\n$CONF"
fi

# 📥 Cargar configuraciones dinámicas del archivo
source "$CONF"

# 🧠 Alias por defecto
DEFAULT_ALIAS=$(grep -E '^default_alias=' "$CONF" | cut -d= -f2 | tr -d '"')

  # 🔧 Funciones
about_info() {
  kdialog --title "Acerca de kwebsearch" --msgbox "
Herramienta personal para realizar búsquedas web mediante alias personalizados.

📦 FUNCIONES PRINCIPALES:
• Configuración rápida mediante alias
• Historial de búsquedas guardado localmente
• Backup y restauración selectiva de configuración

📁 UBICACIÓN DE CONFIGURACIÓN:
• Alias: $CONF
• Historial: $HIST

🛠️ Autor: dmnmsc
📦 Versión: $VERSION
📅 Última actualización: $(date +\"%Y-%m-%d\")
"

  kdialog --title "Repositorio en GitHub" \
          --yesno "¿Quieres abrir el repositorio del proyecto en tu navegador?\n\n🔗 https://github.com/dmnmsc/kwebsearch"

  if [ $? -eq 0 ]; then
    xdg-open "https://github.com/dmnmsc/kwebsearch"
  fi

  exec "$0"  # ← Reejecuta el script desde el principio
}

ver_historial() {
  if [[ ! -s "$HIST" ]]; then
    kdialog --msgbox "ℹ️ No hay historial disponible todavía."
    exit
  fi

  mapfile -t ITEMS < <(tac "$HIST")
  sel=$(kdialog --title "🕘 Historial de búsquedas" \
    --combobox "Selecciona una búsqueda anterior:" "${ITEMS[@]}") || exit

  [[ -n "$sel" ]] && procesar_busqueda "$sel"
}

crear_alias() {
  local key="" desc="" tmpl=""

  # 1) Clave del alias
  while true; do
    key=$(kdialog --inputbox "🔑 Clave del alias (sin espacios ni paréntesis):" "$key") || return
    key="${key//[^a-zA-Z0-9_.@,+-]/}"

    if [[ -z "$key" ]]; then
      kdialog --error "❌ La clave está vacía o contiene caracteres no permitidos."
      continue
    fi

    if grep -qE "^${key}\)" "$CONF"; then
      kdialog --error "❌ La clave '$key' ya existe en el archivo de alias."
      continue
    fi
    break
  done

  # 2) Descripción del alias
  while true; do
    desc=$(kdialog --inputbox "📘 Descripción para '$key':" "$desc") || return

    if [[ -z "$desc" ]]; then
      kdialog --error "❌ La descripción no puede estar vacía."
      continue
    fi
    break
  done

  # 3) Plantilla de comando
  while true; do
    tmpl=$(kdialog --inputbox \
      "⚙️ Comando con \$query:\nEjemplo: xdg-open \"https://ejemplo.com?q=\$query\"" "$tmpl") || return

    if [[ -z "$tmpl" ]]; then
      kdialog --error "❌ La plantilla no puede estar vacía."
      continue
    fi

    if ! grep -q "\$query" <<< "$tmpl"; then
      kdialog --error "❌ Falta el placeholder \$query en el comando."
      continue
    fi

    local quote_count=$(grep -o '"' <<< "$tmpl" | wc -l)
    if (( quote_count % 2 != 0 )); then
      kdialog --error "❌ Las comillas dobles están desbalanceadas. Deben ir en pares."
      continue
    fi

    if ! grep -q '"[^"]*\$query[^"]*"' <<< "$tmpl"; then
      kdialog --error "❌ El placeholder \$query debe estar dentro de comillas dobles correctamente cerradas."
      continue
    fi

    break
  done

  # 4) Confirmación final
  if kdialog --yesno "🔍 Vista previa:\n\n${key}) ${tmpl} ;;#${desc}\n\n¿Guardar este alias?"; then
    printf '%s)%s;;#%s\n' "$key" "$tmpl" "$desc" >> "$CONF"
    kdialog --msgbox "✅ Alias guardado correctamente: $key"
  else
    kdialog --msgbox "❌ Alias cancelado. No se ha guardado."
  fi

  exec bash "$0"
}

mostrar_alias() {
  local keys=() descs=() options=() sel key desc query

  # 0) Opción DuckDuckGo (alias vacío)
  keys+=("")
  descs+=("DuckDuckGo")
  if [[ -z "$DEFAULT_ALIAS" ]]; then
    options+=( "DuckDuckGo 🟢 (predeterminado)" )
  else
    options+=( "DuckDuckGo (predeterminado)" )
  fi

  # 1) Leer CONF y rellenar arrays con tus alias habituales
  while IFS= read -r line; do
    [[ "$line" =~ ^([a-zA-Z0-9_.@,+-]*)\)[^#]*#[[:space:]]*(.*)$ ]] || continue
    key="${BASH_REMATCH[1]}"
    desc="${BASH_REMATCH[2]}"
    [[ "$key" == "$DEFAULT_ALIAS" ]] && desc+=" 🟢 (por defecto)"
    keys+=("$key")
    descs+=("$desc")
    options+=( "${desc} (${key})" )
  done < "$CONF"

  # 2) Mostrar combobox SIN reset
  sel=$(kdialog \
    --title "Alias disponibles" \
    --combobox "Selecciona un alias:" \
    "${options[@]}" ) || exit
  [[ -z "$sel" ]] && exit

  # 3) Encontrar índice para recuperar key y desc
  for i in "${!options[@]}"; do
    [[ "${options[i]}" == "$sel" ]] && key="${keys[i]}" desc="${descs[i]}" && break
  done

  # 4) Si el alias elegido es vacío → DuckDuckGo directo
  if [[ -z "$key" ]]; then
    query=$(kdialog \
      --title "DuckDuckGo" \
      --inputbox "Escribe tu consulta:") || exit
    [[ -z "$query" ]] && exit
    xdg-open "https://duckduckgo.com/?q=$(echo "$query" | sed 's/ /+/g')"
    exit
  fi

  # 5) Para cualquier otro alias, pedimos su consulta habitual
  query=$(kdialog \
    --title "$desc" \
    --inputbox "Escribe tu consulta:") || exit
  [[ -z "$query" ]] && exit

  procesar_busqueda "$key:$query"
}

editar_alias() {
  xdg-open "$CONF"
  exit
}

borrar_historial() {
  kdialog --yesno "¿Seguro que deseas borrar el historial?"
  [[ $? -eq 0 ]] && > "$HIST" && kdialog --msgbox "✅ Historial borrado correctamente." && bash "$0" &
  exit
}

establecer_default() {
    local keys=() descs=() options=() sel key desc new_default

    # 1) Leer CONF y rellenar arrays
    while IFS= read -r line; do
      [[ "$line" =~ ^([a-zA-Z0-9_.@,+-]*)\)[^#]*#[[:space:]]*(.*)$ ]] || continue
      key="${BASH_REMATCH[1]}"
      desc="${BASH_REMATCH[2]}"
      # Marcar el actual default
      [[ "$key" == "$DEFAULT_ALIAS" ]] && desc+=" 🟢 (actual)"
      keys+=("$key")
      descs+=("$desc")
      options+=( "${desc} (${key})" )
    done < "$CONF"

    # 2) Añadir opción reset
    keys+=("reset")
    descs+=("🧹 Restablecer alias por defecto (DuckDuckGo)")
    options+=( "🧹 Restablecer alias por defecto (reset)" )

    # 3) Mostrar combobox
    sel=$(kdialog \
      --title "Alias por defecto" \
      --combobox "Selecciona un alias por defecto:" \
      "${options[@]}" ) || exit
    [[ -z "$sel" ]] && exit

    # 4) Encontrar índice de la selección
    for i in "${!options[@]}"; do
      if [[ "${options[i]}" == "$sel" ]]; then
        key="${keys[i]}"
        desc="${descs[i]}"
        break
      fi
    done

    # 5) Si reset, llamar a restablecer_alias
    if [[ "$key" == "reset" ]]; then
      restablecer_alias
      exit
    fi

    # 6) Actualizar default_alias en el CONF
    new_default="$key"
    sed -i "s/^default_alias=.*/default_alias=\"$new_default\"/" "$CONF"
    kdialog --msgbox "✅ Alias por defecto actualizado: $desc"

    exit
  }

restablecer_alias() {
  sed -i 's/^default_alias=.*/default_alias=""/' "$CONF"
  kdialog --msgbox "🔄 Alias por defecto restablecido a DuckDuckGo"
  exit
}

# backup_config
backup_config() {
  opcion=$(kdialog --title "Exportar configuración" \
    --radiolist "¿Qué deseas exportar?" \
    1 "⚙️ Alias (kwebsearch.conf)" on \
    2 "🕘 Historial (kwebsearch_history)" off \
    3 "📦 Ambos" off) || return

  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

  case "$opcion" in
    1)
      DEST="$BACKUP_DIR/${TIMESTAMP}_kwebsearch_backup_conf"
      mkdir -p "$DEST"
      cp "$CONF" "$DEST/kwebsearch.conf"
      kdialog --msgbox "✅ Alias exportados en:\n$DEST"
      ;;
    2)
      DEST="$BACKUP_DIR/${TIMESTAMP}_kwebsearch_backup_hist"
      mkdir -p "$DEST"
      cp "$HIST" "$DEST/kwebsearch_history"
      kdialog --msgbox "✅ Historial exportado en:\n$DEST"
      ;;
    3)
      DEST="$BACKUP_DIR/${TIMESTAMP}_kwebsearch_backup_conf_hist"
      mkdir -p "$DEST"
      cp "$CONF" "$DEST/kwebsearch.conf"
      cp "$HIST" "$DEST/kwebsearch_history"
      kdialog --msgbox "✅ Alias e historial exportados en:\n$DEST"
      ;;
    *)
      kdialog --error "❌ Opción no válida"
      ;;
  esac
}

# restore_config
restore_config() {
  while true; do
    BACKUPS=($(ls -d "$BACKUP_DIR"/[0-9]*_kwebsearch_backup_* 2>/dev/null | sort -r))
    [[ ${#BACKUPS[@]} -eq 0 ]] && {
      kdialog --error "❌ No se encontraron backups en $BACKUP_DIR"
      return
    }

    SELECTED_BACKUP=$(kdialog --title "Restaurar configuración" \
      --combobox "Selecciona el backup a restaurar:" \
      $(for dir in "${BACKUPS[@]}"; do echo "$(basename "$dir")"; done)) || return

    FULL_PATH="$BACKUP_DIR/$SELECTED_BACKUP"

    HAS_CONF=false
    HAS_HIST=false
    [[ -f "$FULL_PATH/kwebsearch.conf" ]] && HAS_CONF=true
    [[ -f "$FULL_PATH/kwebsearch_history" ]] && HAS_HIST=true

    if ! $HAS_CONF && ! $HAS_HIST; then
      kdialog --error "❌ El backup seleccionado no contiene archivos válidos.\nIntenta con otro."
      continue  # Vuelve al selector
    fi

    # Decide qué restaurar
    if $HAS_CONF && $HAS_HIST; then
      RESTORE_OPTION=$(kdialog --title "Contenido detectado" \
        --radiolist "Elige qué restaurar del backup:" \
        1 "⚙️ Alias (kwebsearch.conf)" on \
        2 "🕘 Historial (kwebsearch_history)" off \
        3 "📦 Ambos" off) || continue
    elif $HAS_CONF; then
      RESTORE_OPTION=1
    elif $HAS_HIST; then
      RESTORE_OPTION=2
    fi

    case "$RESTORE_OPTION" in
      1)
        cp "$FULL_PATH/kwebsearch.conf" "$CONF"
        kdialog --msgbox "✅ Alias restaurados correctamente"
        ;;
      2)
        cp "$FULL_PATH/kwebsearch_history" "$HIST"
        kdialog --msgbox "✅ Historial restaurado correctamente"
        ;;
      3)
        cp "$FULL_PATH/kwebsearch.conf" "$CONF"
        cp "$FULL_PATH/kwebsearch_history" "$HIST"
        kdialog --msgbox "✅ Alias e historial restaurados correctamente"
        ;;
    esac
    break  # Restauración exitosa, salimos del bucle
  done
}

prefix() {
  nuevo_prefijo=$(kdialog --inputbox "Símbolo actual: $cmd_prefix\n\nIntroduce nuevo prefijo para abrir URLs directamente:" "$cmd_prefix")

  if [[ -z "$nuevo_prefijo" || "$nuevo_prefijo" =~ [[:space:]] ]]; then
    kdialog --error "Prefijo inválido. No se realizaron cambios."
    exit 1
  fi

  # Sustituir línea cmd_prefix en kwebsearch.conf
  sed -i "s/^cmd_prefix=.*$/cmd_prefix=\"$nuevo_prefijo\"/" "$CONF"
  kdialog --msgbox "✅ Prefijo actualizado a: $nuevo_prefijo"
  bash "$0" &
  exit
}

mostrar_ayuda() {
  kdialog --msgbox "🧾 Comandos disponibles
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝  ALIAS
   _alias         → Seleccionar alias
   _newalias  → Crear alias
   _edit           → Editar alias manualmente
   _default     → Establecer alias por defecto
   _resetalias → Restablecer alias por defecto

🗄️  HISTORIAL
   _history      → Ver historial reciente
   _clear          → Borrar historial

💾  MENÚ & BACKUP
   _menu       → Menú general
   _backup     → Crear backup (configuración e historial)
   _restore     → Restaurar backup existente

🌐  ABRIR URL
   >                  → Abre directamente el sitio web (ej: >github.com)
   _prefix        → Establecer el símbolo para abrir URLs

ℹ️  VARIOS
   _about       → Créditos y versión
   _help          → Ver esta ayuda
   _exit            → Salir del script
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$0" &
  exit
}

ejecutar_busqueda() {
  local key="$1"
  local query="$(echo "$2" | sed 's/ /+/g')"
  line=$(grep -E "^$key\)" "$CONF")
  command=$(echo "$line" | sed -E 's/^[^)]*\)[[:space:]]*(.*);;#.*$/\1/')
  eval "$command"
}

procesar_busqueda() {
  input="$1"
  # Abrir web directamente si input empieza por cmd_prefix y tiene forma de dominio
if [[ "$input" =~ ^$cmd_prefix([a-zA-Z0-9.-]+\.[a-z]{2,})(/.*)?$ ]]; then
  site="${BASH_REMATCH[1]}"
  path="${BASH_REMATCH[2]}"
  [[ -z "$path" ]] && path=""
  xdg-open "https://${site}${path}"
  exit
fi
  grep -qxF "$input" "$HIST" || echo "$input" >> "$HIST"

  if [[ "$input" =~ ^([a-zA-Z0-9_.@,+-]+):(.*) ]]; then
    key="${BASH_REMATCH[1]}"
    query="${BASH_REMATCH[2]}"
    if grep -Eq "^[[:space:]]*$key\)" "$CONF"; then
      ejecutar_busqueda "$key" "$query"
    elif [[ -n "$DEFAULT_ALIAS" ]]; then
      ejecutar_busqueda "$DEFAULT_ALIAS" "$input"
    else
      xdg-open "https://duckduckgo.com/?q=$(echo "$input" | sed 's/ /+/g')"
    fi
  else
    if [[ -n "$DEFAULT_ALIAS" ]]; then
      ejecutar_busqueda "$DEFAULT_ALIAS" "$input"
    else
      xdg-open "https://duckduckgo.com/?q=$(echo "$input" | sed 's/ /+/g')"
    fi
  fi
  exit
}

# 🌟 Ejemplo dinámico de bangs
EJEMPLOS_BANG=("!w energía solar" "!gh kwebsearch" "!aur neovim" "!yt rammstein" "!g teclado mecánico")
BANG_EJEMPLO=${EJEMPLOS_BANG[$RANDOM % ${#EJEMPLOS_BANG[@]}]}

# 🏷️ Título según alias por defecto
if [[ -n "$DEFAULT_ALIAS" ]]; then
  line=$(grep -E "^$DEFAULT_ALIAS\)" "$CONF")
  titulo=$(echo "$line" | sed -E 's/^.*#\s*(.*)$/\1/')
else
  titulo="KWebSearch"
fi

# 💬 Entrada principal
input=$(kdialog --title "$titulo" --inputbox \
"🟢 Usa !bangs de DuckDuckGo. Ejemplo: $BANG_EJEMPLO  ✏️ Escribe _help para ver más opciones:")
[[ $? -ne 0 || -z "$input" ]] && exit

# 🎯 Comandos y menú
case "$input" in
  _help)        mostrar_ayuda ;;
  _alias)       mostrar_alias ;;
  _edit)        editar_alias ;;
  _clear)       borrar_historial ;;
  _default)     establecer_default ;;
  _history)     ver_historial ;;
  _prefix)        prefix ;;
  _resetalias)  restablecer_alias ;;
  _newalias)  crear_alias ;;
  _backup)      backup_config ;;
  _restore)     restore_config ;;
  _about)     about_info ;;
  _menu)
  OPCION=$(kdialog --title "Opciones" --menu "¿Qué deseas hacer?" \
    1 "📘 Seleccionar alias" \
    2 "🆕 Crear alias" \
    3 "✏️ Editar alias" \
    4 "🟢 Establecer alias por defecto" \
    5 "🔄 Restablecer alias por defecto" \
    6 "🕘 Ver historial" \
    7 "🧹 Limpiar historial" \
    8 "🌐 Establecer símbolo para abrir URL" \
    9 "📤 Crear backup (configuración e historial)" \
    10 "📥 Restaurar backup existente" \
    11 "🧾 Ver ayuda" \
    12 "ℹ️ Acerca de" \
    13 "❌ Salir")
  case "$OPCION" in
    1) mostrar_alias      ;;
    2) crear_alias        ;;
    3) editar_alias       ;;
    4) establecer_default ;;
    5) restablecer_alias  ;;
    6) ver_historial  ;;
    7)borrar_historial   ;;
    8) prefix      ;;
    9) backup_config      ;;
    10) restore_config     ;;
    11) mostrar_ayuda      ;;
    12) about_info      ;;
    13) exit              ;;
  esac
  ;;

  *) procesar_busqueda "$input" ;;
esac
