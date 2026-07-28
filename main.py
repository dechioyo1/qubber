import sys
import logging
import asyncio
import os
import signal
from PySide6.QtCore import QTimer
from PySide6.QtGui import QIcon, QFontDatabase, QFont
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
from qasync import QEventLoop

from roster_model import RosterModel
from chat_model import ChatModel
from backend import XmppBackend
from theme_manager import ThemeManager

def main():
    # Set default text rendering type to NativeTextRendering to support color emojis on Linux
    QQuickWindow.setTextRenderType(QQuickWindow.TextRenderType.NativeTextRendering)
    
    # Setup logging to see XMPP transactions
    logging.basicConfig(level=logging.INFO, format="%(levelname)-8s %(message)s")
    
    app = QApplication(sys.argv)
    app.setApplicationName("Qubber")
    app.setOrganizationName("Qubber")
    
    # Load and set application icon (used for dock / window switcher)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Load custom Open Sans fonts
    fonts_dir = os.path.join(script_dir, "fonts")
    if os.path.exists(fonts_dir):
        for font_file in os.listdir(fonts_dir):
            if font_file.endswith(".ttf"):
                font_path = os.path.join(fonts_dir, font_file)
                QFontDatabase.addApplicationFont(font_path)
    app_font = QFont()
    app_font.setFamilies(["Open Sans", "Noto Color Emoji", "Segoe UI Emoji", "Apple Color Emoji", "Emoji"])
    app.setFont(app_font)
    
    logo_path = os.path.join(script_dir, "logo.svg")
    app.setWindowIcon(QIcon(logo_path))
    
    # Setup loop
    loop = QEventLoop(app)
    asyncio.set_event_loop(loop)
    
    # Enable clean exit on Ctrl+C (SIGINT)
    signal.signal(signal.SIGINT, lambda *args: app.quit())
    
    # A dummy timer is required to let Python run periodically and catch signals
    sigint_timer = QTimer()
    sigint_timer.start(200)
    sigint_timer.timeout.connect(lambda: None)
    
    # Instantiate models, backend and theme manager
    theme_manager = ThemeManager()
    roster_model = RosterModel()
    chats_list_model = RosterModel()
    chat_model = ChatModel()
    backend = XmppBackend(roster_model, chats_list_model, chat_model)
    
    # Ensure clean XMPP disconnect on shutdown
    app.aboutToQuit.connect(backend.logout)
    
    # Initialize QML engine
    engine = QQmlApplicationEngine()
    
    # Set context properties
    context = engine.rootContext()
    context.setContextProperty("themeManager", theme_manager)
    context.setContextProperty("xmppBackend", backend)
    context.setContextProperty("rosterModel", roster_model)
    context.setContextProperty("chatsListModel", chats_list_model)
    context.setContextProperty("chatModel", chat_model)
    
    # Load UI
    engine.load("qml/main.qml")
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    # Trigger automatic login if remember me is enabled and credentials exist
    if backend.savedRememberMe and backend.savedJid and backend.savedPassword:
        logging.info("Initiating automatic login with saved credentials...")
        QTimer.singleShot(200, lambda: backend.login(
            backend.savedJid,
            backend.savedPassword,
            backend.savedHost,
            backend.savedPort,
            True
        ))
        
    # Start the qasync-managed event loop
    with loop:
        loop.run_forever()

if __name__ == "__main__":
    main()
