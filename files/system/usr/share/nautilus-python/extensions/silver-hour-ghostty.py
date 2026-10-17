# Nautilus extension: "Terminal" context-menu entry that opens Ghostty in the
# selected folder. Nautilus is patched downstream to hardcode its own terminal;
# this restores an entry that launches the silver-hour default terminal.
import os
import shutil
from urllib.parse import unquote

from gi.repository import GObject, Nautilus


class TerminalExtension(GObject.GObject, Nautilus.MenuProvider):
    def _open(self, _menu, folder):
        uri = folder.get_uri() if folder else None
        if not uri or not uri.startswith("file://"):
            return
        path = unquote(uri[len("file://"):])
        ghostty = shutil.which("ghostty")
        if not ghostty:
            return
        os.system(f"{ghostty} --working-directory='{path}' &")

    def _item(self, name, folder):
        item = Nautilus.MenuItem(
            name=name,
            label="Terminal",
            tip="Open a terminal in this folder",
        )
        item.connect("activate", self._open, folder)
        return item

    def get_background_items(self, *args):
        folder = args[-1] if args else None
        if folder is None:
            return []
        return [self._item("SilverHourTerminal::OpenBackground", folder)]

    def get_file_items(self, *args):
        files = args[-1] if args else []
        if len(files) != 1 or not files[0].is_directory():
            return []
        return [self._item("SilverHourTerminal::OpenFolder", files[0])]
