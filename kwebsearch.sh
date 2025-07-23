#!/bin/bash

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
default_alias=""

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

# 🧠 Alias por defecto
DEFAULT_ALIAS=$(grep -E '^default_alias=' "$CONF" | cut -d= -f2 | tr -d '"')

  # 🔧 Funciones
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
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  DEST="$BACKUP_DIR/kwebsearch_backup_$TIMESTAMP"
  mkdir -p "$DEST"
  cp "$CONF" "$DEST/kwebsearch.conf"
  cp "$HIST" "$DEST/kwebsearch_history"
  kdialog --msgbox "✅ Configuración exportada en:\n$DEST"
  exit
}

# restore_config
restore_config() {
  # Listar etiquetas de backups existentes
  mapfile -t LABELS < <(
    ls -1d "$BACKUP_DIR"/kwebsearch_backup_* 2>/dev/null \
      | sort \
      | sed -e 's#.*/kwebsearch_backup_##'
  )

  if (( ${#LABELS[@]} == 0 )); then
    kdialog --msgbox "❌ No se encontró ningún backup en $BACKUP_DIR"
    exit
  fi

  seleccion=$(kdialog --title "Importar backup" \
    --combobox "Elige el backup a restaurar:" \
    "${LABELS[@]}")
  [[ -z "$seleccion" ]] && exit

  backup_path="$BACKUP_DIR/kwebsearch_backup_$seleccion"
  cp "$backup_path/kwebsearch.conf" "$CONF"
  cp "$backup_path/kwebsearch_history" "$HIST"
  kdialog --msgbox "✅ Backup restaurado:\n$backup_path"

  exec bash "$0"
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
   _clear          → Borrar historial

💾  CONFIGURACIÓN & BACKUP
   _config       → Menú general
   _backup     → Crear backup (configuración e historial)
   _restore     → Restaurar backup existente

ℹ️  VARIOS
   _help          → Ver esta ayuda
   _exit           → Salir del script
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
  _resetalias)  restablecer_alias ;;
  _newalias)  crear_alias ;;
  _backup)      backup_config ;;
  _restore)     restore_config ;;
  _config)
  OPCION=$(kdialog --title "Opciones" --menu "¿Qué deseas hacer?" \
    1 "📘 Seleccionar alias" \
    2 "🆕 Crear alias" \
    3 "✏️ Editar alias" \
    4 "🟢 Establecer alias por defecto" \
    5 "🔄 Restablecer alias por defecto" \
    6 "🧹 Limpiar historial" \
    7 "📤 Crear backup (configuración e historial)" \
    8 "📥 Restaurar backup existente" \
    9 "📖 Ver ayuda" \
    10 "❌ Salir")
  case "$OPCION" in
    1) mostrar_alias      ;;
    2) crear_alias        ;;
    3) editar_alias       ;;
    4) establecer_default ;;
    5) restablecer_alias  ;;
    6) borrar_historial   ;;
    7) backup_config      ;;
    8) restore_config     ;;
    9) mostrar_ayuda      ;;
    10) exit              ;;
  esac
  ;;

  *) procesar_busqueda "$input" ;;
esac
