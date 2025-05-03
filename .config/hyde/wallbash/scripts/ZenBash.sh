#!/bin/bash

release_folder=$(find ~/.zen -maxdepth 1 -type d -name "*(*release*)*" | head -n 1)

if [[ -z "$release_folder" ]]; then
  echo "No folder containing (release) found in ~/.zen"
  exit 1
fi

chrome_folder="$release_folder/chrome"
mkdir -p "$chrome_folder"

escaped_path=$(echo "$chrome_folder" | sed 's/ /\\ /g; s/(/\\(/g; s/)/\\)/g')

content_file="$HOME/.config/hyde/wallbash/always/zen#Content.dcol"
content_line="${escaped_path}/userContent.css"
tmp_file=$(mktemp)
echo "$content_line" > "$tmp_file"
[[ -f "$content_file" ]] && cat "$content_file" >> "$tmp_file"
mv "$tmp_file" "$content_file"

chrome_file="$HOME/.config/hyde/wallbash/always/zen#Chrome.dcol"
chrome_line="${escaped_path}/userChrome.css"
tmp_file=$(mktemp)
echo "$chrome_line" > "$tmp_file"
[[ -f "$chrome_file" ]] && cat "$chrome_file" >> "$tmp_file"
mv "$tmp_file" "$chrome_file"
