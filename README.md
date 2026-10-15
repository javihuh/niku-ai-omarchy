# Niku AI for Omarchy

A persistent ChatGPT side panel for the Omarchy bar. Niku AI opens ChatGPT in
an isolated Brave app profile, keeps the login and conversation state between
opens, and stays out of the way when hidden.

## Features

- Native Omarchy bar widget.
- Persistent, isolated Brave profile for ChatGPT.
- Opens as a floating panel on the current monitor.
- Left-click toggles the panel; right-click quits it completely.
- Optional `Super+G` shortcut from anywhere.
- Optional `Esc` shortcut that hides the panel only while ChatGPT has focus.
- Hides automatically when focus moves to another window.
- Uses ChatGPT's native appearance and does not inject CSS.

## Requirements

- Omarchy 4.0 or newer with shell plugin support.
- Brave at `/opt/brave-bin/brave`, as provided by Omarchy.
- `jq`, `hyprctl`, `uwsm-app`, and `setsid` from the standard Omarchy install.

## Install

Install and enable the widget:

```bash
omarchy plugin add https://github.com/javihuh/niku-ai-omarchy.git --enable
```

The widget works immediately by clicking its bar icon. To also install the
`Super+G` and focus-aware `Esc` shortcuts, run:

```bash
python3 ~/.config/omarchy/plugins/cibo.niku-ai/scripts/bindings.py install
```

`Super+G` replaces Omarchy's default window-grouping toggle. The helper checks
the existing binding before making that change, creates a timestamped backup
of `~/.config/hypr/bindings.lua`, and reloads Hyprland.

## Usage

| Action | Result |
| --- | --- |
| Left-click | Show or hide Niku AI |
| Right-click | Quit Niku AI completely |
| `Super+G` | Show or hide Niku AI when shortcuts are installed |
| `Esc` | Hide Niku AI while its window has focus |
| Click another window | Hide Niku AI automatically |

Hiding the panel keeps Brave running so the page and login remain available.
Quitting closes the isolated Brave process. The profile is stored locally at
`~/.local/share/niku-ai/brave-profile` and is never part of this repository.

## Commands

```bash
omarchy-shell cibo.niku-ai open
omarchy-shell cibo.niku-ai close
omarchy-shell cibo.niku-ai toggle
omarchy-shell cibo.niku-ai quit
```

Update an installed copy:

```bash
omarchy plugin update cibo.niku-ai
```

## Remove

Remove the managed shortcuts first, then remove the plugin:

```bash
python3 ~/.config/omarchy/plugins/cibo.niku-ai/scripts/bindings.py remove
omarchy plugin remove cibo.niku-ai
```

Removing the plugin does not delete the isolated Brave profile. Remove
`~/.local/share/niku-ai/brave-profile` separately only if you also want to
erase its ChatGPT login and local browser data.

## Development

```bash
omarchy plugin validate .
qmllint BarWidget.qml
bash -n toggle.sh
```

## License

[MIT](LICENSE)
