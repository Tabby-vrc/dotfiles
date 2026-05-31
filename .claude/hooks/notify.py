import sys
import win32gui
import win32process
import psutil
from winotify import Notification, audio

MESSAGES = {
    "stop": "タスク完了",
    "notification": "確認が必要です",
}

def is_windows_terminal_active() -> bool:
    hwnd = win32gui.GetForegroundWindow()
    _, pid = win32process.GetWindowThreadProcessId(hwnd)
    try:
        name = psutil.Process(pid).name().lower()
        return name in ("windowsterminal.exe", "wt.exe")
    except psutil.NoSuchProcess:
        return False

def notify(message: str):
    toast = Notification(
        app_id="Claude Code",
        title=message,
        msg="",
        duration="short",
    )
    toast.set_audio(audio.Default, loop=False)
    toast.show()

if __name__ == "__main__":
    if is_windows_terminal_active():
        sys.exit(0)
    event = sys.argv[1] if len(sys.argv) > 1 else "stop"
    message = MESSAGES.get(event, event)
    notify(message)
