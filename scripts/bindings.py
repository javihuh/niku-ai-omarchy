#!/usr/bin/env python3
"""Install or remove Niku AI's managed Hyprland bindings."""

from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time


BEGIN = "-- BEGIN Niku AI managed bindings"
END = "-- END Niku AI managed bindings"
BINDINGS = Path.home() / ".config" / "hypr" / "bindings.lua"

BLOCK = r'''-- BEGIN Niku AI managed bindings
-- SUPER+G is Omarchy's default grouping toggle.
hl.unbind("SUPER + G")
o.bind("SUPER + G", "Niku AI", "omarchy-shell cibo.niku-ai toggle")

-- Escape hides Niku AI only while its window has focus.
local niku_escape = hl.bind(
  "ESCAPE",
  hl.dsp.exec_cmd([[bash "$HOME/.config/omarchy/plugins/cibo.niku-ai/toggle.sh" close]]),
  { description = "Hide Niku AI" }
)
local niku_click = hl.bind(
  "mouse:272",
  hl.dsp.exec_cmd([[bash "$HOME/.config/omarchy/plugins/cibo.niku-ai/toggle.sh" close-if-pointer-outside]]),
  { non_consuming = true }
)

local niku_was_focused = false

local function update_niku_focus(window)
  local class = window and string.lower(window.class or "") or ""
  local initial_class = window and string.lower(window.initial_class or "") or ""
  local is_niku = class:find("nikuai", 1, true) ~= nil
    or initial_class:find("nikuai", 1, true) ~= nil
    or class:find("chatgpt.com", 1, true) ~= nil
    or initial_class:find("chatgpt.com", 1, true) ~= nil
  niku_escape:set_enabled(is_niku)
  niku_click:set_enabled(is_niku)
  local should_hide = niku_was_focused and not is_niku
  niku_was_focused = is_niku
  if should_hide then
    hl.exec_cmd([[bash "$HOME/.config/omarchy/plugins/cibo.niku-ai/toggle.sh" close]])
  end
end

update_niku_focus(hl.get_active_window())
hl.on("window.active", update_niku_focus)
-- END Niku AI managed bindings
'''


def managed_range(text: str) -> tuple[int, int] | None:
    start = text.find(BEGIN)
    if start < 0:
        return None
    end = text.find(END, start)
    if end < 0:
        raise RuntimeError(f"found {BEGIN!r} without {END!r}")
    end += len(END)
    if end < len(text) and text[end] == "\n":
        end += 1
    return start, end


def without_managed_block(text: str) -> tuple[str, bool]:
    bounds = managed_range(text)
    if bounds is None:
        return text, False
    start, end = bounds
    if start > 0 and text[start - 1] == "\n" and end == len(text):
        start -= 1
    return text[:start] + text[end:], True


def super_g_binding() -> str | None:
    result = subprocess.run(
        ["omarchy", "menu", "keybindings", "--print"],
        check=True,
        capture_output=True,
        text=True,
        timeout=10,
    )
    for line in result.stdout.splitlines():
        left, separator, description = line.partition("→")
        normalized = " ".join(left.replace("+", " + ").split()).upper()
        if separator and normalized == "SUPER + G":
            return description.strip()
    return None


def write_file(path: Path, text: str, label: str) -> Path:
    timestamp = time.strftime("%Y%m%d%H%M%S")
    unique = time.time_ns() % 1_000_000_000
    backup = path.with_name(f"{path.name}.bak.niku-ai-{timestamp}-{unique:09d}")
    shutil.copy2(path, backup)

    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent, prefix=f".{path.name}.", delete=False
    ) as temporary:
        temporary.write(text)
        temporary.flush()
        temp_path = Path(temporary.name)
    temp_path.chmod(path.stat().st_mode & 0o777)
    temp_path.replace(path)
    print(f"{label} (backup: {backup})")
    return backup


def reload_hyprland() -> None:
    subprocess.run(["hyprctl", "reload"], check=True, timeout=10)
    errors = subprocess.run(
        ["hyprctl", "configerrors"], check=True, capture_output=True, text=True, timeout=10
    ).stdout.strip()
    if errors not in ("", "ok"):
        print(errors, file=sys.stderr)
        raise RuntimeError("Hyprland reported configuration errors")


def install(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    current = managed_range(text)
    if current is not None and text[current[0] : current[1]].rstrip() == BLOCK.rstrip():
        print("Niku AI bindings are already installed.")
        return

    base, owned = without_managed_block(text)
    if path == BINDINGS and not owned:
        description = super_g_binding()
        if description not in (None, "Toggle window grouping"):
            raise RuntimeError(f"SUPER + G is already bound to {description!r}; refusing to replace it")

    separator = "" if not base or base.endswith("\n\n") else "\n" if base.endswith("\n") else "\n\n"
    write_file(path, base + separator + BLOCK, "Installed Niku AI bindings")
    if path == BINDINGS:
        reload_hyprland()


def remove(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    updated, changed = without_managed_block(text)
    if not changed:
        print("No managed Niku AI bindings found.")
        return
    write_file(path, updated, "Removed Niku AI bindings")
    if path == BINDINGS:
        reload_hyprland()


def status(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    print("installed" if managed_range(text) is not None else "not installed")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("install", "remove", "status"))
    parser.add_argument("--file", type=Path, default=BINDINGS, help=argparse.SUPPRESS)
    args = parser.parse_args()

    try:
        if not args.file.is_file() or args.file.is_symlink():
            raise RuntimeError(f"refusing to modify non-regular file: {args.file}")
        {"install": install, "remove": remove, "status": status}[args.action](args.file)
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"bindings.py: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
