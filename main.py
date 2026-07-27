import sys
import logging
import asyncio
import os
from PySide6.QtCore import QTimer
from PySide6.QtGui import QIcon
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from qasync import QEventLoop

from roster_model import RosterModel
from chat_model import ChatModel
from backend import XmppBackend

def main():
    # Setup logging to see XMPP transactions
    logging.basicConfig(level=logging.INFO, format="%(levelname)-8s %(message)s")
    
    app = QApplication(sys.argv)
    app.setApplicationName("Qubber")
    app.setOrganizationName("Qubber")
    
    # Load and set application icon (used for dock / window switcher)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    logo_path = os.path.join(script_dir, "logo.svg")
    app.setWindowIcon(QIcon(logo_path))
    
    # Setup loop
    loop = QEventLoop(app)
    asyncio.set_event_loop(loop)
    
    # Instantiate models and backend
    roster_model = RosterModel()
    chats_list_model = RosterModel()
    chat_model = ChatModel()
    backend = XmppBackend(roster_model, chats_list_model, chat_model)
    
    # Initialize QML engine
    engine = QQmlApplicationEngine()
    
    # Set context properties
    context = engine.rootContext()
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
