#!/usr/bin/env python3
import sys
import time
import dbus


def import_svg(file_path):
    session_bus = dbus.SessionBus()
    try:
        inkscape = session_bus.get_object(
            "org.inkscape.Inkscape", "/org/inkscape/Inkscape"
        )
        iface = dbus.Interface(inkscape, "org.inkscape.Inkscape")
    except dbus.DBusException:
        print(
            "Inkscape DBus interface not found. Is Inkscape running with DBus enabled?"
        )
        sys.exit(1)

    # Call the Import method with the file path
    iface.Import(file_path)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: import_svg.py path/to/file.svg")
        sys.exit(1)
    import_svg(sys.argv[1])
