#!/bin/bash

run_browser=false

while getopts "r" opt; do
  case $opt in
    r)
      run_browser=true
      ;;
  esac
done

release_folder=$(find ~/.zen -maxdepth 1 -type d -name "*(*release*)*" | head -n 1)
if [[ -z "$release_folder" ]]; then
  release_folder=$(find ~/.zen -maxdepth 1 -type d -name "*(*alpha*)*" | head -n 1)
  if [[ -z "$release_folder" ]]; then
    echo "No folder containing (release) or (alpha) found in ~/.zen"
    exit 1
  fi
fi

chrome_folder="$release_folder/chrome"
mkdir -p "$chrome_folder"

content_line="'${chrome_folder}/userContent.css'"
content_file="$HOME/.config/hyde/wallbash/always/zen#Content.dcol"
tmp_file=$(mktemp)

if [[ -f "$content_file" ]]; then
  read -r first_line < "$content_file"
  if [[ "$first_line" != *"@media {"* ]]; then
    tail -n +2 "$content_file" > "$tmp_file"
  else
    cp "$content_file" "$tmp_file"
  fi
fi

echo "$content_line" > "$content_file"
cat "$tmp_file" >> "$content_file"
rm "$tmp_file"

chrome_line="'${chrome_folder}/userChrome.css'|$HOME/.config/hyde/wallbash/scripts/ZenBash.sh -r"
chrome_file="$HOME/.config/hyde/wallbash/always/zen#Chrome.dcol"
tmp_file=$(mktemp)

if [[ -f "$chrome_file" ]]; then
  read -r first_line < "$chrome_file"
  if [[ "$first_line" != *"@media {"* ]]; then
    tail -n +2 "$chrome_file" > "$tmp_file"
  else
    cp "$chrome_file" "$tmp_file"
  fi
fi

echo "$chrome_line" > "$chrome_file"
cat "$tmp_file" >> "$chrome_file"
rm "$tmp_file"

color.set.sh --single ~/.config/hyde/wallbash/always/zen\#Chrome.dcol
color.set.sh --single ~/.config/hyde/wallbash/always/zen\#Content.dcol

if $run_browser && pgrep -x zen-bin > /dev/null; then
  zen_id=$(hyprctl clients -j | jq -r '.[] | select(.class == "zen") | .address' | head -n 1)
  workspace=$(hyprctl clients -j | jq -r --arg addr "$zen_id" '.[] | select(.address == $addr) | .workspace.id')
  monitor=$(hyprctl clients -j | jq -r --arg addr "$zen_id" '.[] | select(.address == $addr) | .monitor')

  pkill zen-bin
  zen-browser & disown

  # Wait up to 5 seconds for the new window to appear
  for i in {1..10}; do
    sleep 0.5
    zen_window=$(hyprctl clients -j | jq -r '.[] | select(.class == "zen") | .address' | head -n 1)
    [[ -n "$zen_window" ]] && break
  done

  if [[ -n "$zen_window" && -n "$workspace" ]]; then
    hyprctl dispatch movetoworkspacesilent "$workspace,address:$zen_window"
  fi
fi
