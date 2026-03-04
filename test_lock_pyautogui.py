import pyautogui
import time

print("Testing pyautogui lock in 3 seconds...")
time.sleep(3)
try:
    pyautogui.hotkey('win', 'l')
    print("Command executed.")
except Exception as e:
    print(f"Error: {e}")
