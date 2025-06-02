#!/bin/bash

run_browser=false

while getopts "r" opt; do
  [[ $opt == "r" ]] && run_browser=true
done

set -e

release_folder=$(find ~/.zen -maxdepth 1 -type d -name "*(*release*)*" | head -n1)
release_folder=${release_folder:-$(find ~/.zen -maxdepth 1 -type d -name "*(*alpha*)*" | head -n1)}

if [[ -z "$release_folder" ]]; then
  echo "No (release) or (alpha) folder found in ~/.zen"
  exit 1
fi

chrome_dir="$release_folder/chrome"
zenbash_dir="$chrome_dir/ZenBash"
mkdir -p "$zenbash_dir"

content_path="$HOME/.config/hyde/wallbash/always/zen#Content.dcol"
content_entry="'${zenbash_dir}/zenbashContent.css'"
tmp_content=$(mktemp)

if [[ -f "$content_path" ]]; then
  read -r line < "$content_path"
  [[ "$line" != *"@media {"* ]] && tail -n +2 "$content_path" > "$tmp_content" || cp "$content_path" "$tmp_content"
fi

echo "$content_entry" > "$content_path"
cat "$tmp_content" >> "$content_path"
rm "$tmp_content"

chrome_path="$HOME/.config/hyde/wallbash/always/zen#Chrome.dcol"
chrome_entry="'${zenbash_dir}/zenbashChrome.css'|$HOME/.config/hyde/wallbash/scripts/ZenBash.sh -r"
tmp_chrome=$(mktemp)

if [[ -f "$chrome_path" ]]; then
  read -r line < "$chrome_path"
  [[ "$line" != *"@media {"* ]] && tail -n +2 "$chrome_path" > "$tmp_chrome" || cp "$chrome_path" "$tmp_chrome"
fi

echo "$chrome_entry" > "$chrome_path"
cat "$tmp_chrome" >> "$chrome_path"
rm "$tmp_chrome"

user_chrome="$chrome_dir/userChrome.css"
import_chrome='@import "ZenBash/zenbashChrome.css";'
touch "$user_chrome"
if ! grep -Fxq "$import_chrome" "$user_chrome"; then
  tmp=$(mktemp)
  echo "$import_chrome" > "$tmp"
  cat "$user_chrome" >> "$tmp"
  mv "$tmp" "$user_chrome"
fi

user_content="$chrome_dir/userContent.css"
import_content='@import "ZenBash/zenbashContent.css";'
touch "$user_content"
if ! grep -Fxq "$import_content" "$user_content"; then
  tmp=$(mktemp)
  echo "$import_content" > "$tmp"
  cat "$user_content" >> "$tmp"
  mv "$tmp" "$user_content"
fi

if ! $run_browser; then
  rules_file="$HOME/.config/hypr/windowrules.conf"
  target_rule='windowrulev2 = opacity 1.00 $& 0.80 1,class:^(zen)$'

  if [[ -f "$rules_file" ]]; then
    if grep -q "class:^(zen)" "$rules_file" && ! grep -Fxq "$target_rule" "$rules_file"; then
      tmp_rules=$(mktemp)
      inserted=false
      while IFS= read -r line; do
        if [[ "$line" == *"class:^(zen)"* ]]; then
          echo "# $line" >> "$tmp_rules"
          if ! $inserted; then
            echo "$target_rule" >> "$tmp_rules"
            inserted=true
          fi
        else
          echo "$line" >> "$tmp_rules"
        fi
      done < "$rules_file"
      mv "$tmp_rules" "$rules_file"
      echo "[ZenBash] Updated Hyprland window rules for zen"
    else
      echo "[ZenBash] No changes to Hyprland windowrules.conf needed"
    fi
  fi
fi

if $run_browser; then
  if pgrep -x zen-bin > /dev/null; then
    (
      set -euo pipefail
      echo "[ZenBash] Restarting zen-browser..."

      zen_id=$(hyprctl clients -j | jq -r '.[] | select(.class == "zen") | .address' | head -n1)
      workspace=$(hyprctl clients -j | jq -r --arg addr "$zen_id" '.[] | select(.address == $addr) | .workspace.id')

      pkill zen-bin
      zen-browser & disown

      for _ in {1..10}; do
        sleep 0.5
        new_zen=$(hyprctl clients -j | jq -r '.[] | select(.class == "zen") | .address' | head -n1)
        [[ -n "$new_zen" ]] && break
      done

      if [[ -n "$new_zen" && -n "$workspace" ]]; then
        hyprctl dispatch movetoworkspacesilent "$workspace,address:$new_zen"
      fi
    ) || echo "[ZenBash] ERROR: Failed to restart zen-browser"
  else
    echo "[ZenBash] zen-bin not running, checking for other zen processes..."

    zen_pids=$(pgrep -f zen || true)

    if [[ -n "$zen_pids" ]]; then
      echo "[ZenBash] Killing other zen-related processes: $zen_pids"
      kill $zen_pids
      sleep 1
      echo "[ZenBash] Starting zen-browser..."
      zen-browser & disown
    else
      echo "[ZenBash] No zen processes found, not starting zen-browser."
    fi
  fi
fi