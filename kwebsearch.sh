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
mostrar_alias() {
  OPCIONES=()
  while read -r line; do
    [[ "$line" =~ ^([a-zA-Z0-9_.@,+-]*)\)[^#]*#[[:space:]]*(.*)$ ]] || continue
    alias="${BASH_REMATCH[1]}"
    descripcion="${BASH_REMATCH[2]}"
    [[ "$alias" == "$DEFAULT_ALIAS" ]] && descripcion="${descripcion} 🟢 (por defecto)"
    OPCIONES+=("$alias:$descripcion")
  done < "$CONF"

  OPCIONES+=("reset:🧹 Restablecer alias por defecto (DuckDuckGo)")

  alias_seleccionado=$(kdialog --title "Alias disponibles" --combobox "Selecciona un alias:" "${OPCIONES[@]}")
  [[ -z "$alias_seleccionado" ]] && exit
  key="${alias_seleccionado%%:*}"

  if [[ "$key" == "reset" ]]; then
    restablecer_alias
  else
    descripcion=$(grep -E "^$key\)" "$CONF" | sed -E 's/.*#(.*)$/\1/')
    texto=$(kdialog --title "$descripcion" --inputbox "Escribe tu consulta:")
    [[ -z "$texto" ]] && exit
    procesar_busqueda "$key:$texto"
  fi
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
  OPCIONES=()
  while read -r line; do
    [[ "$line" =~ ^([a-zA-Z0-9_.@,+-]*)\)[^#]*#[[:space:]]*(.*)$ ]] || continue
    alias="${BASH_REMATCH[1]}"
    descripcion="${BASH_REMATCH[2]}"
    OPCIONES+=("$alias:$descripcion")
  done < "$CONF"
  alias_default=$(kdialog --title "Alias por defecto" --combobox "Selecciona un alias por defecto:" "${OPCIONES[@]}")
  [[ -z "$alias_default" ]] && exit
  new_default="${alias_default%%:*}"
  sed -i "s/^default_alias=.*/default_alias=\"$new_default\"/" "$CONF"
  kdialog --msgbox "✅ Alias por defecto actualizado: ${new_default:-DuckDuckGo}"
  exit
}

restablecer_alias() {
  sed -i 's/^default_alias=.*/default_alias=""/' "$CONF"
  kdialog --msgbox "🔄 Alias por defecto restablecido a DuckDuckGo"
  exit
}

# backup_config(): antes exportar_config()
backup_config() {
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  DEST="$BACKUP_DIR/kwebsearch_backup_$TIMESTAMP"
  mkdir -p "$DEST"
  cp "$CONF" "$DEST/kwebsearch.conf"
  cp "$HIST" "$DEST/kwebsearch_history"
  kdialog --msgbox "✅ Configuración exportada en:\n$DEST"
  exit
}

# restore_config(): antes importar_config()
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
  kdialog --msgbox "🧾 Comandos especiales disponibles:

_config    → Menú general
_alias     → Selector de alias
_edit      → Editar alias manualmente
_clear     → Borrar historial
_default   → Establecer alias por defecto
_resetalias→ Restablecer alias por defecto (DuckDuckGo)
_backup    → Crear backup (configuración e historial)
_restore   → Restaurar backup existente
_help      → Ver esta ayuda
_exit      → Salir del script"
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
  _backup)      backup_config ;;
  _restore)     restore_config ;;
  _config)
    OPCION=$(kdialog --title "Opciones" --menu "¿Qué deseas hacer?" \
      1 "📘 Selector de alias" \
      2 "✏️ Editar alias" \
      3 "🧹 Limpiar historial" \
      4 "🟢 Establecer alias por defecto" \
      5 "📖 Ver ayuda" \
      6 "❌ Salir" \
      7 "🔄 Restablecer alias por defecto (DuckDuckGo)" \
      8 "📤 Crear backup (configuración e historial)" \
      9 "📥 Restaurar backup existente")
    case "$OPCION" in
      1) mostrar_alias   ;;
      2) editar_alias    ;;
      3) borrar_historial;;
      4) establecer_default ;;
      5) mostrar_ayuda   ;;
      6|"") exit         ;;
      7) restablecer_alias ;;
      8) backup_config   ;;
      9) restore_config  ;;
    esac
    ;;
  *) procesar_busqueda "$input" ;;
esac
