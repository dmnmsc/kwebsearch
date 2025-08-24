#!/usr/bin/env python3

import random
import sys
import os
import subprocess
import re
import webbrowser
from urllib.parse import quote_plus
from datetime import datetime

# PyQt6 imports
from PyQt6.QtWidgets import (
    QApplication, QInputDialog, QMessageBox, QComboBox, QMenu, QDialog,
    QVBoxLayout, QLabel, QRadioButton, QDialogButtonBox,
    QMainWindow, QLineEdit, QWidget, QSizePolicy
)
from PyQt6.QtGui import QAction
from PyQt6.QtCore import Qt

# Localization imports
import gettext

# ─────────────────── ⚙️ CONFIGURATION & SETUP ────────────────────
VERSION = "2.0"
VERBOSE = False

# Setup for gettext localization
base_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
localedir = os.path.join(base_dir, 'locales')

translation = gettext.translation('kwebsearch', localedir, fallback=True)
translation.install()
_ = translation.gettext

# ─────────────────── 🧱 UTILITY CLASSES ────────────────────

class Dialogs:
    """Class to handle all PyQt6 dialogs, consolidating repeated code."""
    def __init__(self, parent=None):
        self.parent = parent

    def show_message_box(self, text, title="KWebSearch", icon=QMessageBox.Icon.Information):
        """Displays a message box."""
        msg = QMessageBox(self.parent)
        msg.setIcon(icon)
        msg.setWindowTitle(title)
        msg.setText(text)
        msg.setStandardButtons(QMessageBox.StandardButton.Ok)
        msg.exec()

    def show_yes_no_box(self, text, title="KWebSearch"):
        """Displays a yes/no dialog."""
        reply = QMessageBox.question(self.parent, title, text, QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No, QMessageBox.StandardButton.No)
        return reply == QMessageBox.StandardButton.Yes

    def get_input(self, title, label, text=""):
        """Displays an input dialog."""
        input_dialog = QInputDialog(self.parent)
        input_dialog.setWindowFlags(input_dialog.windowFlags() & ~Qt.WindowType.WindowContextHelpButtonHint)
        input_dialog.setWindowTitle(title)
        input_dialog.setLabelText(label)
        input_dialog.setTextValue(text)
        if input_dialog.exec():
            return input_dialog.textValue()
        return None

    def show_list_dialog(self, title, label, items, radio=False):
        """Displays a combo or radio list dialog."""
        dialog = QDialog(self.parent)
        dialog.setWindowTitle(title)
        layout = QVBoxLayout()
        layout.addWidget(QLabel(label))

        if radio:
            radio_buttons = []
            for i, (text, checked) in enumerate(items):
                radio_button = QRadioButton(text)
                radio_button.setChecked(checked)
                layout.addWidget(radio_button)
                radio_buttons.append((str(i + 1), radio_button))
        else:
            combo = QComboBox()
            combo.addItems(items)
            layout.addWidget(combo)

        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(dialog.accept)
        buttons.rejected.connect(dialog.reject)
        layout.addWidget(buttons)
        dialog.setLayout(layout)

        if dialog.exec() == QDialog.DialogCode.Accepted:
            if radio:
                for val, button in radio_buttons:
                    if button.isChecked():
                        return val
            else:
                return combo.currentText()
        return None

# ─────────────────── ☑️ MAIN APPLICATION CODE ────────────────────
class KWebSearchApp:
    def __init__(self):
        self.cmd_prefix = ""
        self.default_alias = ""
        self.config_dir = os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.join(os.path.expanduser("~"), ".config")), "kwebsearch")
        self.data_dir = os.path.join(os.environ.get("XDG_DATA_HOME", os.path.join(os.path.expanduser("~"), ".local/share")), "kwebsearch")
        self.conf = os.path.join(self.config_dir, "kwebsearch.conf")
        self.hist = os.path.join(self.data_dir, "kwebsearch_history")
        self.backup_dir = os.path.join(self.data_dir, "backup")
        self.aliases = {}
        self.allowed_programs_regex = re.compile(r"^(xdg-open|firefox|firefoxpwa|chromium|google-chrome|brave|opera|lynx|w3m|links|google-chrome-.*)$")
        self.dialogs = Dialogs()

        self.setup_directories()
        self.load_config()

    def setup_directories(self):
        """Creates necessary directories and files."""
        os.makedirs(self.config_dir, exist_ok=True)
        os.makedirs(self.data_dir, exist_ok=True)
        os.makedirs(self.backup_dir, exist_ok=True)
        if not os.path.exists(self.hist):
            open(self.hist, 'a').close()

        if not os.path.exists(self.conf):
            self.create_default_config()

    def create_default_config(self):
        """Generates the default kwebsearch.conf file."""
        with open(self.conf, "w") as f:
            f.write(_("""# 🧠 Default alias (if left empty, DuckDuckGo via !bangs will be used)
default_alias=""

# 🚀 Prefix to open URLs directly (e.g., >github.com)
# You can change to ~, @, ^, ::, >, etc.
cmd_prefix=">"

# 🔎 Custom aliases in alias=URL-or-command format #comment
g="xdg-open https://www.google.com/search?q=$query" #Google
i="xdg-open https://www.google.com/search?tbm=isch&q=$query" #Google Images
y="xdg-open https://www.youtube.com/results?search_query=$query" #YouTube
w="xdg-open https://en.wikipedia.org/wiki/Special:Search?search=$query" #Wikipedia (EN)
p="xdg-open https://www.perplexity.ai/search?q=$query" #Perplexity.ai
d="xdg-open https://www.wordreference.com/definition/$query" #English dictionary
trans="xdg-open https://translate.google.com/?sl=auto&tl=es&text=$query" #Google Translate
gh="xdg-open https://github.com/search?q=$query&type=repositories" #GitHub
gl="xdg-open https://gitlab.com/search?search=$query" #GitLab
so="xdg-open https://stackoverflow.com/search?q=$query" #Stack Overflow
r="xdg-open https://www.reddit.com/search?q=$query" #Reddit
"""))
        self.dialogs.show_message_box(_("✅ Alias file created at:\n") + self.conf)

    def load_config(self):
        """Loads configuration variables and aliases from the config file."""
        self.aliases.clear()
        try:
            with open(self.conf, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("default_alias="):
                        self.default_alias = line.split("=", 1)[1].strip().strip('"')
                    elif line.startswith("cmd_prefix="):
                        self.cmd_prefix = line.split("=", 1)[1].strip().strip('"')
                    elif re.match(r"^[^#].*=", line):
                        match = re.match(r"^([^=]+)=(.*?)#\s*(.*)", line)
                        if match:
                            key, cmd, desc = match.groups()
                            self.aliases[key.strip()] = {"cmd": cmd.strip().strip('"'), "desc": desc.strip()}
        except FileNotFoundError:
            self.dialogs.show_message_box(_("❌ Error: Configuration file not found."), _("Error"), QMessageBox.Icon.Critical)
            sys.exit(1)

    def open_cmd(self, *args):
        """Executes a command with VERBOSE support."""
        cmd = [arg for arg in args if arg]
        if VERBOSE:
            print(_("Executing:"), " ".join(cmd))
            subprocess.run(cmd)
        else:
            subprocess.Popen(cmd, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# -------------------- Alias Management --------------------
    def show_aliases(self):
        """Displays a list of aliases to select from."""
        self.load_config()
        options = [_("DuckDuckGo ") + (_("🟢 (default)") if not self.default_alias else _("(default)"))]
        keys = [""]
        descs = [_("DuckDuckGo")]

        for key, value in self.aliases.items():
            desc = value['desc']
            if key == self.default_alias:
                desc += _(" 🟢 (current)")
            options.append(f"{desc} ({key})")
            keys.append(key)
            descs.append(desc)

        sel = self.dialogs.show_list_dialog(_("Available aliases"), _("Select an alias:"), options)
        if sel is None: return

        key = keys[options.index(sel)]
        desc = descs[options.index(sel)]

        query = self.dialogs.get_input(desc, _("Type your query:"))
        if query is None: return

        if key:
            self.process_search(f"{key}:{query}")
        else:
            self.duckduckgo_search(query)

    def create_alias(self):
        """Guides the user to create a new alias."""
        self.load_config()
        while True:
            key = self.dialogs.get_input(_("Alias key (no spaces or parentheses):"), _("🔑 Alias key:"))
            if key is None: return
            key = re.sub(r"[^a-zA-Z0-9_.@,+-]", "", key)
            if not key or key in self.aliases:
                msg = _("❌ Key is empty or contains invalid characters.") if not key else f"❌ {_('The key')} '{key}' {_('already exists in the alias file.')}"
                self.dialogs.show_message_box(msg, _("Error"), QMessageBox.Icon.Critical)
                continue
            break

        desc = self.dialogs.get_input(_(f"Description for '{key}':"), _("📘 Description:"))
        if not desc:
            self.dialogs.show_message_box(_("❌ Description cannot be empty."), _("Error"), QMessageBox.Icon.Critical)
            return

        template_text = _("⚙️ Enter the URL template with $query\n\n") + _("Examples:\n") + "- xdg-open https://example.com?q=$query\n" + "- firefox https://example.com?q=$query\n" + "- chromium --incognito https://example.com?q=$query"
        template = self.dialogs.get_input(_(f"URL template for '{key}':"), template_text)
        if template is None or not template or "$query" not in template:
            msg = _("❌ Template cannot be empty.") if not template else _("❌ Missing placeholder $query in the template.")
            self.dialogs.show_message_box(msg, _("Error"), QMessageBox.Icon.Critical)
            return

        first_word = template.split(maxsplit=1)[0].strip('"')
        if not self.allowed_programs_regex.match(first_word):
            self.dialogs.show_message_box(_(f"❌ Program not allowed in template: {first_word}"), _("Error"), QMessageBox.Icon.Critical)
            return

        if self.dialogs.show_yes_no_box(_(f"🔍 Preview:\n\n{key}=\"{template}\" # {desc}\n\nSave this alias?")):
            with open(self.conf, "a") as f:
                f.write(f"\n{key}=\"{template}\" # {desc}\n")
            self.dialogs.show_message_box(_(f"✅ Alias saved successfully: {key}"))
            self.load_config()

    def edit_alias(self):
        """Opens the alias file for manual editing using xdg-open."""
        try:
            subprocess.run(["xdg-open", self.conf], check=True)
        except (FileNotFoundError, subprocess.CalledProcessError) as e:
            msg = _("❌ The 'xdg-open' command was not found...") if isinstance(e, FileNotFoundError) else _("❌ An error occurred while trying to open the configuration file.")
            self.dialogs.show_message_box(msg, _("Error"), QMessageBox.Icon.Critical)

    def set_default_alias(self):
        """Sets a new default alias from the available list."""
        self.load_config()
        options = [f"{v['desc']} ({k})" for k, v in self.aliases.items()]
        keys = list(self.aliases.keys())
        options.append(_("🧹 Reset default alias (DuckDuckGo)"))
        keys.append("reset")

        sel = self.dialogs.show_list_dialog(_("Default alias"), _("Select a default alias:"), options)
        if sel is None: return

        key = keys[options.index(sel)]
        if key == "reset":
            self.reset_default_alias()
            return

        with open(self.conf, "r+") as f:
            content = f.read()
            f.seek(0)
            f.truncate()
            f.write(re.sub(r"^default_alias=.*$", f'default_alias="{key}"', content, flags=re.MULTILINE))
        self.dialogs.show_message_box(_(f"✅ Default alias updated to: {self.aliases[key]['desc']}"))
        self.load_config()

    def reset_default_alias(self):
        """Resets the default alias to DuckDuckGo."""
        with open(self.conf, "r+") as f:
            content = f.read()
            f.seek(0)
            f.truncate()
            f.write(re.sub(r'^default_alias=.*$', 'default_alias=""', content, flags=re.MULTILINE))
        self.dialogs.show_message_box(_("🔄 Default alias reset to DuckDuckGo"))
        self.load_config()

# -------------------- Search History --------------------
    def view_history(self):
        """Displays a list of recent searches to select and re-execute."""
        if not os.path.getsize(self.hist):
            self.dialogs.show_message_box(_("ℹ️ No search history available yet."))
            return
        with open(self.hist, "r") as f:
            history = [line.strip() for line in f if line.strip()]
        if not history:
            self.dialogs.show_message_box(_("ℹ️ No search history available yet."))
            return
        history.reverse()
        selected = self.dialogs.show_list_dialog(_("Search history"), _("Select a previous search:"), history)
        if selected:
            self.process_search(selected)

    def clear_history(self):
        """Clears the search history file."""
        if self.dialogs.show_yes_no_box(_("Are you sure you want to clear the search history?")):
            open(self.hist, 'w').close()
            self.dialogs.show_message_box(_("✅ Search history cleared successfully."))

# -------------------- URL-Related Functions --------------------
    def open_direct_url(self, url):
        """Helper function to open URLs, adding https if missing."""
        if not re.match(r'^[a-zA-Z]+://', url):
            url = f"https://{url}"
        print(_("🌐 Opening direct URL:"), url)
        self.open_cmd("xdg-open", url)

    def open_url_dialog(self):
        """Opens a URL based on user input from a dialog."""
        url = self.dialogs.get_input(_("Enter the URL to open:"), _("Enter the URL to open (e.g., example.com or https://example.com):"))
        if url: self.open_direct_url(url)

    def duckduckgo_search(self, query):
        """Performs a search using DuckDuckGo."""
        print(_("🔎 Performing DuckDuckGo search for"), f'"{query}"')
        url = f"https://duckduckgo.com/?q={quote_plus(query)}"
        self.open_cmd("xdg-open", url)

    def set_prefix(self):
        """Changes the prefix for opening URLs directly."""
        new_prefix = self.dialogs.get_input(_(f"Current symbol: {self.cmd_prefix}\n\nEnter new prefix to open URLs directly:"), _("Enter new prefix:"))
        if new_prefix is None or not new_prefix or ' ' in new_prefix:
            self.dialogs.show_message_box(_("Invalid prefix. No changes made."), _("Error"), QMessageBox.Icon.Warning)
            return

        with open(self.conf, "r+") as f:
            content = f.read()
            f.seek(0)
            f.truncate()
            f.write(re.sub(r'^cmd_prefix=.*$', f'cmd_prefix="{new_prefix}"', content, flags=re.MULTILINE))
        self.dialogs.show_message_box(_(f"✅ Prefix updated to: {new_prefix}"))
        self.load_config()

# -------------------- Backup Functions --------------------
    def backup_config(self):
        """Creates a backup of the configuration and/or history files."""
        options_map = [
            {"label": _("⚙️ Aliases (kwebsearch.conf)"), "files": [self.conf]},
            {"label": _("🕘 History (kwebsearch_history)"), "files": [self.hist]},
            {"label": _("📦 Both"), "files": [self.conf, self.hist]}
        ]

        dialog = QDialog()
        dialog.setWindowTitle(_("Export configuration"))
        layout = QVBoxLayout()
        layout.addWidget(QLabel(_("What do you want to export?")))
        radios = [QRadioButton(opt["label"]) for opt in options_map]
        radios[0].setChecked(True)
        for radio in radios: layout.addWidget(radio)
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(dialog.accept)
        buttons.rejected.connect(dialog.reject)
        layout.addWidget(buttons)
        dialog.setLayout(layout)

        if dialog.exec() == QDialog.DialogCode.Accepted:
            option_idx = [i for i, r in enumerate(radios) if r.isChecked()][0]
            selected_option = options_map[option_idx]
            timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
            file_names = [os.path.basename(f).replace('kwebsearch', '').replace('.', '_') for f in selected_option["files"]]
            dest_name = f"{timestamp}_kwebsearch_backup_{'_and_'.join(file_names)}"
            dest = os.path.join(self.backup_dir, dest_name)
            os.makedirs(dest, exist_ok=True)
            for file_path in selected_option["files"]:
                subprocess.run(["cp", file_path, dest])
            self.dialogs.show_message_box(_(f"✅ Aliases and history exported in:\n{dest}")) # Generalized message

    def restore_config(self):
        """Restores a backup of the configuration and/or history files."""
        backups = sorted([d for d in os.listdir(self.backup_dir) if d.startswith("20") and os.path.isdir(os.path.join(self.backup_dir, d))], reverse=True)
        if not backups:
            self.dialogs.show_message_box(_("❌ No backups found."), _("Error"), QMessageBox.Icon.Critical)
            return
        selected_backup_name = self.dialogs.show_list_dialog(_("Restore configuration"), _("Select backup to restore:"), backups)
        if not selected_backup_name: return

        full_path = os.path.join(self.backup_dir, selected_backup_name)
        has_conf = os.path.exists(os.path.join(full_path, "kwebsearch.conf"))
        has_hist = os.path.exists(os.path.join(full_path, "kwebsearch_history"))
        if not has_conf and not has_hist:
            self.dialogs.show_message_box(_("❌ Selected backup does not contain valid files."), _("Error"), QMessageBox.Icon.Critical)
            return

        restore_options = [
            (_("⚙️ Aliases (kwebsearch.conf)"), has_conf),
            (_("🕘 History (kwebsearch_history)"), has_hist)
        ]
        if has_conf and has_hist: restore_options.append((_("📦 Both"), True))

        selection = self.dialogs.show_list_dialog(_("Content detected"), _("Choose what to restore from backup:"), restore_options, radio=True)
        if selection:
            if selection == "1" and has_conf:
                subprocess.run(["cp", os.path.join(full_path, "kwebsearch.conf"), self.conf])
                self.dialogs.show_message_box(_("✅ Aliases restored successfully"))
            elif selection == "2" and has_hist:
                subprocess.run(["cp", os.path.join(full_path, "kwebsearch_history"), self.hist])
                self.dialogs.show_message_box(_("✅ History restored successfully"))
            elif selection == "3" and has_conf and has_hist:
                subprocess.run(["cp", os.path.join(full_path, "kwebsearch.conf"), self.conf])
                subprocess.run(["cp", os.path.join(full_path, "kwebsearch_history"), self.hist])
                self.dialogs.show_message_box(_("✅ Aliases and history restored successfully"))
            self.load_config()

# -------------------- Information and Help --------------------
    def show_help(self):
        help_text = _("""🧾 HELP - Using kwebsearch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔎 SEARCH METHODS:

🟢 !bang: Perform quick searches with DuckDuckGo aliases.
    → Example: !w solar energy     (search Wikipedia)
    → Example: !gh kwebsearch      (search GitHub)

🔎 alias:query: Use custom aliases defined by you.
    → Example: g:mechanical keyboard   (search Google)
    → Example: w:Linux             (search Wikipedia ES)

🌐 >url: Open a URL directly in the browser.
    → Example: >github.com
    → Example: >es.wikipedia.org/wiki/Bash

✏️ Internal commands (type in the prompt):
    _alias          → Select alias for searching
    _newalias       → Create new custom alias
    _edit           → Edit alias file manually
    _default        → Set default alias
    _resetalias     → Reset default alias to DuckDuckGo

    _history        → View recent search history
    _clear          → Clear history

    _prefix         → Change symbol for opening URLs directly (e.g., >)
    _backup         → Create backup of config and history
    _restore        → Restore existing backup

    _help           → Show this help
    _about          → About kwebsearch
    _exit           → Exit the program

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")
        self.dialogs.show_message_box(help_text, _("kwebsearch help"))

    def about_info(self):
        about_text = _("""🛠️ kwebsearch - Custom web search tool

Version: {VERSION}
Author: dmnmsc
Last updated: {last_updated}

📌 What is kwebsearch?
A simple and practical tool to perform fast searches and open web pages using customizable aliases and !bangs, with a user-friendly GUI.

⭐ Main features:
• Quick alias searches
• DuckDuckGo !bangs integration for versatile searches
• Direct URL opening with configurable prefix
• Local search history auto saved
• Configuration and history backup and restore

📂 Main files:
• Alias configuration: {conf}
• Search history: {hist}

🔗 More info and source code:
https://github.com/dmnmsc/kwebsearch
""").format(VERSION=VERSION, last_updated=datetime.now().strftime('%Y-%m-%d'), conf=self.conf, hist=self.hist)

        msg_box = QMessageBox(QMessageBox.Icon.Information, _("About kwebsearch"), about_text)

        # Corrected syntax for adding buttons
        yes_button = msg_box.addButton(QMessageBox.StandardButton.Yes)
        no_button = msg_box.addButton(QMessageBox.StandardButton.No)

        msg_box.setDefaultButton(QMessageBox.StandardButton.Yes)

        msg_box.exec()

        if msg_box.clickedButton() == yes_button:
            webbrowser.open("https://github.com/dmnmsc/kwebsearch")

# -------------------- Refactored Search Functions --------------------
    def execute_search(self, key, query):
        alias_data = self.aliases.get(key)
        if not alias_data:
            print(_("Alias not found:"), key)
            self.duckduckgo_search(query)
            return

        cmd_template = alias_data['cmd'].strip('"')
        query_encoded = quote_plus(query)
        cmd_template = re.sub(r'\$query', query_encoded, cmd_template)
        cmd_array = cmd_template.split()
        prog = cmd_array[0]
        if self.allowed_programs_regex.match(prog):
            print(_("🔎 Performing search for"), f'"{query}"', _("using alias"), f"'{key}'")
            self.open_cmd(*cmd_array)
        else:
            print(_("❌ Command not allowed:"), prog)
            self.duckduckgo_search(query)

    def process_search(self, input_str):
        self.load_config()
        with open(self.hist, "a+", encoding="utf-8") as f:
            f.seek(0)
            if input_str not in f.read().splitlines():
                f.write(input_str + "\n")

        if input_str.startswith(self.cmd_prefix):
            self.open_direct_url(input_str[len(self.cmd_prefix):])
        elif ":" in input_str:
            key, query = input_str.split(":", 1)
            # Validate if the key is a real alias
            if key.strip() in self.aliases:
                self.execute_search(key.strip(), query.strip())
            else:
                # If the alias is not found, treat the whole string as a normal search
                self.duckduckgo_search(input_str)
        else:
            if self.default_alias:
                self.execute_search(self.default_alias, input_str)
            else:
                self.duckduckgo_search(input_str)

# -------------------- New UI --------------------
class KWebSearchUI(QMainWindow):
    def __init__(self, app):
        super().__init__()
        self.app = app
        self.setWindowTitle(_("KWebSearch"))
        self.setGeometry(300, 300, 450, 150)
        self.app.dialogs.parent = self

        self.create_menu_bar()

        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        main_layout = QVBoxLayout()

        # --- Lógica para el ejemplo dinámico con los tres formatos ---
        random_queries = [_("Linux"), _("cats"), _("kitchen"), _("univers"), _("Python"), _("stock")]
        example_type = random.choice(['alias', 'bang', 'url'])
        dynamic_example = ""
        if example_type == 'alias':
            random_alias = random.choice(list(self.app.aliases.keys()))
            random_query = random.choice(random_queries)
            dynamic_example = f"{random_alias}:{random_query}"
        elif example_type == 'bang':
            bang_aliases = ["w", "yt", "g", "r"]
            random_bang = random.choice(bang_aliases)
            random_query = random.choice(random_queries)
            dynamic_example = f"!{random_bang} {random_query}"
        elif example_type == 'url':
            web_sites = ["github.com", "duckduckgo.com", "en.wikipedia.org"]
            random_site = random.choice(web_sites)
            dynamic_example = f"{self.app.cmd_prefix}{random_site}"

        info_text = (_("Explore the web your way! Use bangs, alias or open URLs.\n\n") + _(f"🟢 !bang   🔎 alias:query   🌐 >url   ✏️ _help   💡 {dynamic_example}"))
        info_label = QLabel(info_text)

        main_layout.addWidget(info_label)

        main_layout.addStretch()

        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText(_("🔎 Explore the web your way!"))
        self.search_input.returnPressed.connect(self.handle_input)
        main_layout.addWidget(self.search_input)
        main_widget.setLayout(main_layout)

    def handle_input(self):
        user_input = self.search_input.text().strip()
        if not user_input: return
        commands = {
            "_alias": self.app.show_aliases, "_newalias": self.app.create_alias, "_edit": self.app.edit_alias,
            "_default": self.app.set_default_alias, "_resetalias": self.app.reset_default_alias, "_history": self.app.view_history,
            "_clear": self.app.clear_history, "_prefix": self.app.set_prefix, "_backup": self.app.backup_config,
            "_restore": self.app.restore_config, "_help": self.app.show_help, "_about": self.app.about_info,
            "_exit": self.close
        }
        if user_input in commands:
            commands[user_input]()
        else:
            self.app.process_search(user_input)
        self.search_input.clear()

    def create_menu_bar(self):
        menu_bar = self.menuBar()
        menus = {
            "Search": [
                (_("Select alias..."), self.app.show_aliases),
                (_("View history"), self.app.view_history),
                ("---", None),
                (_("Clear history"), self.app.clear_history),
                (_("Open URL..."), self.app.open_url_dialog)
            ],
            "Alias": [
                (_("Create new alias..."), self.app.create_alias),
                (_("Edit alias file"), self.app.edit_alias),
                ("---", None),
                (_("Set default alias..."), self.app.set_default_alias),
                (_("Reset default alias"), self.app.reset_default_alias)
            ],
            "Settings": [
                (_("Change URL prefix..."), self.app.set_prefix),
                ("---", None),
                (_("Create backup..."), self.app.backup_config),
                (_("Restore backup..."), self.app.restore_config)
            ],
            "Help": [
                (_("Help"), self.app.show_help),
                (_("About..."), self.app.about_info)
            ]
        }
        for menu_name, actions in menus.items():
            menu = menu_bar.addMenu(_(menu_name))
            for action_name, handler in actions:
                if action_name == "---":
                    menu.addSeparator()
                else:
                    action = QAction(action_name, self)
                    action.triggered.connect(handler)
                    menu.addAction(action)

# ─────────────────── 🏁 MAIN EXECUTION ──────────────────────

def main():
    global VERBOSE
    if len(sys.argv) > 1 and sys.argv[1] in ("--help", "-h"):
        print(_("""kwebsearch - Custom web search tool

Usage:
    kwebsearch [options] [query]

Options:
    --help, -h       Show this help and exit.
    --verbose        Verbose mode (show executed commands).

Examples:
    kwebsearch --help
    kwebsearch '!g mechanical keyboard'
    kwebsearch '>github.com'
    kwebsearch 'g:cockatoo'
"""))
        sys.exit(0)
    if len(sys.argv) > 1 and sys.argv[1] == "--verbose":
        VERBOSE = True
        sys.argv.pop(1)

    qt_app = QApplication(sys.argv)
    app_logic = KWebSearchApp()

    if len(sys.argv) > 1:
        app_logic.process_search(" ".join(sys.argv[1:]))
        sys.exit(0)

    main_window = KWebSearchUI(app_logic)
    main_window.show()
    sys.exit(qt_app.exec())

if __name__ == "__main__":
    main()
