#!/bin/bash

set -euo pipefail

action=${1:-toggle}
workspace="special:niku-ai"
workspace_name="niku-ai"
window_class="NikuAI"
url="https://chatgpt.com/"
profile_dir="${XDG_DATA_HOME:-$HOME/.local/share}/niku-ai/brave-profile"

client_address() {
  hyprctl clients -j | jq -r '
    [.[] | select(
      ((.class // "") | ascii_downcase | contains("nikuai")) or
      ((.initialClass // "") | ascii_downcase | contains("nikuai")) or
      ((.class // "") | ascii_downcase | contains("chatgpt.com")) or
      ((.initialClass // "") | ascii_downcase | contains("chatgpt.com"))
    )] | first | .address // empty
  '
}

workspace_visible() {
  hyprctl monitors -j | jq -e --arg workspace "$workspace" \
    'any(.[]; .specialWorkspace.name == $workspace)' >/dev/null
}

hide_panel() {
  if workspace_visible; then
    hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$workspace_name\")" >/dev/null
  fi
}

if [[ $action == "status" ]]; then
  if workspace_visible; then
    printf 'visible\n'
  else
    printf 'hidden\n'
  fi
  exit 0
fi

if [[ $action == "quit" ]]; then
  address=$(client_address)
  if [[ -n $address ]]; then
    selector="address:$address"
    hyprctl dispatch "hl.dsp.window.close({ window = \"$selector\" })" >/dev/null
  fi
  exit 0
fi

if [[ $action == "close" ]]; then
  hide_panel
  exit 0
fi

if [[ $action == "toggle" ]] && workspace_visible; then
  hide_panel
  exit 0
fi

if [[ $action == "open" ]] && workspace_visible; then
  exit 0
fi

monitor=$(hyprctl monitors -j | jq -c '[.[] | select(.focused)] | first')
monitor_x=$(jq -r '.x' <<<"$monitor")
monitor_y=$(jq -r '.y' <<<"$monitor")
monitor_width=$(jq -r '(.width / .scale) | floor' <<<"$monitor")
monitor_height=$(jq -r '(.height / .scale) | floor' <<<"$monitor")

panel_width=520
(( panel_width > monitor_width - 48 )) && panel_width=$((monitor_width - 48))
panel_height=$((monitor_height - 64))
(( panel_height < 480 )) && panel_height=$((monitor_height - 48))
panel_x=$((monitor_x + monitor_width - panel_width - 12))
panel_y=$((monitor_y + 38))

address=$(client_address)
if [[ -z $address ]]; then
  setsid uwsm-app -- /opt/brave-bin/brave \
    --ozone-platform=wayland \
    --ozone-platform-hint=wayland \
    --password-store=gnome-libsecret \
    --app="$url" \
    --class="$window_class" \
    --user-data-dir="$profile_dir" \
    --no-first-run \
    --disable-session-crashed-bubble \
    >/dev/null 2>&1 &
  for _attempt in {1..80}; do
    sleep 0.1
    address=$(client_address)
    [[ -n $address ]] && break
  done
fi

[[ -n $address ]] || exit 1

selector="address:$address"
hyprctl dispatch "hl.dsp.window.float({ action = \"on\", window = \"$selector\" })" >/dev/null
hyprctl dispatch "hl.dsp.window.resize({ x = $panel_width, y = $panel_height, exact = true, window = \"$selector\" })" >/dev/null
hyprctl dispatch "hl.dsp.window.move({ x = $panel_x, y = $panel_y, exact = true, window = \"$selector\" })" >/dev/null
client_workspace=$(hyprctl clients -j | jq -r --arg address "$address" \
  '.[] | select(.address == $address) | .workspace.name')
if [[ $client_workspace != "$workspace" ]]; then
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"$workspace\", follow = false, window = \"$selector\" })" >/dev/null
fi

sleep 0.3
if ! workspace_visible; then
  hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$workspace_name\")" >/dev/null
fi
