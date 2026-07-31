import os
import logging
from PySide6.QtCore import QObject, Property, Signal, Slot, QSettings

def parse_qubber_theme(file_path):
    """Parses a Qubber key-value theme file and resolves key references."""
    if not os.path.exists(file_path):
        logging.error(f"Theme file does not exist at {file_path}")
        return {}

    raw_dict = {}
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("//") or line.startswith("#"):
                    continue
                # Remove inline comments
                if "//" in line:
                    line = line.split("//")[0].strip()
                if ":" in line:
                    key, val = line.split(":", 1)
                    key = key.strip()
                    val = val.strip().rstrip(";")
                    raw_dict[key] = val
    except Exception as e:
        logging.error(f"Error reading theme file at {file_path}: {e}")

    # Resolve key references
    resolved = {}
    def resolve_val(val, depth=0):
        if depth > 10:
            return val
        val = val.strip()
        if val in raw_dict:
            return resolve_val(raw_dict[val], depth + 1)
        return val

    for k, v in raw_dict.items():
        resolved[k] = resolve_val(v)

    def convert_color(hex_str):
        hex_str = hex_str.strip()
        if not hex_str.startswith("#"):
            return hex_str
        # Convert 8-digit hex #RRGGBBAA to #AARRGGBB if needed
        if len(hex_str) == 9:
            r = hex_str[1:3]
            g = hex_str[3:5]
            b = hex_str[5:7]
            a = hex_str[7:9]
            return f"#{a}{r}{g}{b}"
        return hex_str

    return {k: convert_color(v) for k, v in resolved.items()}


class ThemeManager(QObject):
    themeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.settings = QSettings("Qubber", "Theme")
        self.project_dir = os.path.dirname(os.path.abspath(__file__))
        self.user_theme_dir = os.path.expanduser("~/.config/Qubber")
        
        self.built_in_themes = {
            "light": os.path.join(self.project_dir, "themes", "lighttheme"),
            "dark": os.path.join(self.project_dir, "themes", "darktheme")
        }
        
        self._current_theme_name = self.settings.value("current_theme", "light")
        self._colors = {}
        self.load_theme()

    @Property(str, notify=themeChanged)
    def currentTheme(self):
        return self._current_theme_name

    @Slot(str)
    def selectTheme(self, theme_name):
        """Switch between built-in themes ('light', 'dark') or a custom path."""
        if not theme_name:
            return
        self._current_theme_name = theme_name
        self.settings.setValue("current_theme", theme_name)
        self.load_theme()
        logging.info(f"Theme switched to: {theme_name}")

    @Slot(str)
    def loadThemeFromFile(self, file_path):
        import shutil
        import urllib.parse
        import urllib.request
        if file_path.startswith("file://"):
            parsed = urllib.parse.urlparse(file_path)
            file_path = urllib.request.url2pathname(parsed.path)
            
        try:
            custom_theme_path = os.path.join(self.user_theme_dir, "custom_theme")
            os.makedirs(os.path.dirname(custom_theme_path), exist_ok=True)
            shutil.copyfile(file_path, custom_theme_path)
            self.selectTheme("custom")
        except Exception as e:
            logging.error(f"Failed to load custom theme from file: {e}")

    @Slot()
    def reloadTheme(self):
        self.load_theme()

    def load_theme(self):
        theme_path = ""
        if self._current_theme_name in self.built_in_themes:
            theme_path = self.built_in_themes[self._current_theme_name]
        elif self._current_theme_name == "custom":
            theme_path = os.path.join(self.user_theme_dir, "custom_theme")
        elif os.path.exists(self._current_theme_name):
            theme_path = self._current_theme_name

        if not os.path.exists(theme_path):
            # Fall back to default light theme
            theme_path = self.built_in_themes["light"]

        self._colors = parse_qubber_theme(theme_path)
        self.themeChanged.emit()

    def get_color(self, key, fallback):
        val = self._colors.get(key)
        if val and val.startswith("#"):
            return val
        return fallback

    # --- QML Property Getters ---
    @Property(str, notify=themeChanged)
    def colBg(self):
        return self.get_color('colBg', '#ffffff')

    @Property(str, notify=themeChanged)
    def colCard(self):
        return self.get_color('colCard', '#f8fafc')

    @Property(str, notify=themeChanged)
    def colInputBg(self):
        return self.get_color('colInputBg', '#f1f5f9')

    @Property(str, notify=themeChanged)
    def colText(self):
        return self.get_color('colText', '#0f172a')

    @Property(str, notify=themeChanged)
    def colMuted(self):
        return self.get_color('colMuted', '#64748b')

    @Property(str, notify=themeChanged)
    def colBorder(self):
        return self.get_color('colBorder', '#e2e8f0')

    @Property(str, notify=themeChanged)
    def colPrimary(self):
        return self.get_color('colPrimary', '#2563eb')

    @Property(str, notify=themeChanged)
    def colPrimaryDark(self):
        return self.get_color('colPrimaryDark', '#1d4ed8')

    @Property(str, notify=themeChanged)
    def colAccent(self):
        return self.get_color('colAccent', '#7c3aed')

    @Property(str, notify=themeChanged)
    def colHover(self):
        return self.get_color('colHover', '#f1f5f9')

    @Property(str, notify=themeChanged)
    def colActive(self):
        return self.get_color('colActive', '#e2e8f0')

    @Property(str, notify=themeChanged)
    def colActiveFg(self):
        return self.get_color('colActiveFg', '#0f172a')

    @Property(str, notify=themeChanged)
    def topBarBg(self):
        return self.get_color('topBarBg', '#f8fafc')

    @Property(str, notify=themeChanged)
    def topBarFg(self):
        return self.get_color('topBarFg', '#0f172a')

    @Property(str, notify=themeChanged)
    def sidebarBg(self):
        return self.get_color('sidebarBg', '#f8fafc')

    @Property(str, notify=themeChanged)
    def sidebarHeaderBg(self):
        return self.get_color('sidebarHeaderBg', '#f1f5f9')

    @Property(str, notify=themeChanged)
    def sidebarBgOver(self):
        return self.get_color('sidebarBgOver', '#e2e8f0')

    @Property(str, notify=themeChanged)
    def sidebarBgActive(self):
        return self.get_color('sidebarBgActive', '#2563eb')

    @Property(str, notify=themeChanged)
    def msgInBg(self):
        return self.get_color('msgInBg', '#f1f5f9')

    @Property(str, notify=themeChanged)
    def msgInText(self):
        return self.get_color('msgInText', '#0f172a')

    @Property(str, notify=themeChanged)
    def msgOutBg(self):
        return self.get_color('msgOutBg', '#e0e7ff')

    @Property(str, notify=themeChanged)
    def msgOutText(self):
        return self.get_color('msgOutText', '#1e1b4b')

    @Property(str, notify=themeChanged)
    def colDanger(self):
        return self.get_color('colDanger', '#ef4444')

    @Property(str, notify=themeChanged)
    def colSuccess(self):
        return self.get_color('colSuccess', '#10b981')

    @Property(str, notify=themeChanged)
    def colWarning(self):
        return self.get_color('colWarning', '#f59e0b')
