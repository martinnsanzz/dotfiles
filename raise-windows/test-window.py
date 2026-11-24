#!/usr/bin/env python3
"""Opens a small window to check raise-windows brings it to the front.

Run it from a Ghostty tab, a tmux pane or with F5 in VS Code:
    python3 ~/Projects/Claude/dotfiles/raise-windows/test-window.py
The window should open in front of Ghostty, say "has focus" in green, and
show the keys you type without clicking it first. Esc (or closing it) quits.
"""
import tkinter as tk

root = tk.Tk()
root.title("raise-windows test")
root.geometry("420x160")

status = tk.Label(root, font=("Menlo", 14), text="waiting for focus...")
status.pack(expand=True)
typed = tk.Label(root, font=("Menlo", 14), text="type here (Esc quits)")
typed.pack(expand=True)

root.bind("<FocusIn>", lambda e: status.config(text="has focus", fg="green"))
root.bind("<FocusOut>", lambda e: status.config(text="no focus", fg="red"))
root.bind("<Key>", lambda e: typed.config(text=f"typed: {e.keysym}"))
root.bind("<Escape>", lambda e: root.destroy())

root.mainloop()
