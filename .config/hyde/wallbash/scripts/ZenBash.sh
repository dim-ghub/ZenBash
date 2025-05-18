#!/bin/bash

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

chrome_line="'${chrome_folder}/userChrome.css'"
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
