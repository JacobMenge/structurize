#!/usr/bin/env bash
# export_structure.sh v3.5
# 1) Removes UTF‑8 BOM and any CRLF endings from itself
# 2) Then generates a structured overview (text/markdown/json/ndjson)
#    of your programming project with filters & a progress bar.

# --- SELF‑CLEAN: strip BOM + CRLF, then re‑exec once ---
sed -i '1s/^\xEF\xBB\xBF//' "$0" 2>/dev/null || true
sed -i 's/\r$//' "$0" 2>/dev/null || true
if [[ -z "${_CLEANED:-}" ]]; then
  export _CLEANED=1
  exec bash "$0" "$@"
fi

set -euo pipefail

# --- DEFAULTS ---
project_dir="."
output_file="project_structure.json"
output_format="json"    # text | markdown | json | ndjson
include_meta=false      # include file size & mtime
exclude_patterns=()     # glob patterns (relative to project_dir)
select_dirs=()          # only these subdirs
type_filters=()         # file extensions (no dot), e.g. "js,py"
paths=()                # collected paths

# --- USAGE ---
show_usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

  -d, --directory DIR     Base directory (default: "$project_dir")
  -o, --output FILE       Output file (default: "$output_file")
  -f, --format FORMAT     text | markdown | json | ndjson (default: $output_format)
  -n, --ndjson            shorthand for "-f ndjson"
  -m, --meta              include file metadata (size & timestamp)
  -e, --exclude PATTERNS  comma-separated glob patterns to exclude
  -s, --select DIRS       comma-separated list of subdirs to include
  -t, --types EXTENSIONS  comma-separated list of file extensions
  -h, --help              display this help message
EOF
  exit 0
}

# --- PARSE ARGS ---
parse_args() {
  while (( $# )); do
    case "$1" in
      -d|--directory) project_dir="$2"; shift 2;;
      -o|--output)    output_file="$2"; shift 2;;
      -f|--format)    output_format="$2"; shift 2;;
      -n|--ndjson)    output_format="ndjson"; shift;;
      -m|--meta)      include_meta=true; shift;;
      -e|--exclude)   IFS=',' read -r -a exclude_patterns <<< "$2"; shift 2;;
      -s|--select)    IFS=',' read -r -a select_dirs     <<< "$2"; shift 2;;
      -t|--types)     IFS=',' read -r -a type_filters    <<< "$2"; shift 2;;
      -h|--help)      show_usage;;
      *) echo "Error: Unknown option '$1'" >&2; show_usage;;
    esac
  done
}

# --- INIT OUTPUT ---
init_output() {
  : > "$project_dir/$output_file"
  [[ $output_format == json ]] && printf '[' > "$project_dir/$output_file"
}

# --- GET METADATA ---
get_metadata() {
  stat --printf '%s bytes, %y' "$1" 2>/dev/null || echo ""
}

# --- COLLECT PATHS ---
collect_paths() {
  local file
  while IFS= read -r -d '' file; do
    [[ $file == $project_dir/$output_file ]] && continue
    for pat in "${exclude_patterns[@]}"; do
      [[ $file == $project_dir/$pat* ]] && continue 2
    done
    if ((${#select_dirs[@]})); then
      local keep=false
      for sel in "${select_dirs[@]}"; do
        [[ $file == $project_dir/$sel* ]] && keep=true
      done
      $keep || continue
    fi
    if ((${#type_filters[@]}) && [[ -f $file ]]); then
      local ext="${file##*.}"
      [[ ! " ${type_filters[*]} " =~ " $ext " ]] && continue
    fi
    paths+=("$file")
  done < <(find "$project_dir" -print0 | sort -z)
}

# --- OUTPUT ONE ENTRY ---
output_entry() {
  local file="$1"
  local rel="${file#$project_dir/}"
  local is_dir=false
  [[ -d $file ]] && is_dir=true

  local entry
  if $is_dir; then
    entry="{\"type\":\"directory\",\"path\":\"$rel\"}"
  else
    local content meta=""
    content="$(sed 's/"/\\\\\"/g' "$file")"
    $include_meta && meta=",\"meta\":\"$(get_metadata "$file" | sed 's/"/\\\\\"/g')\""
    entry="{\"type\":\"file\",\"path\":\"$rel\"$meta,\"content\":\"$content\"}"
  fi

  case "$output_format" in
    json)   printf '%s,'   "$entry" >> "$project_dir/$output_file";;
    ndjson) printf '%s\n' "$entry" >> "$project_dir/$output_file";;
    text)
      if $is_dir; then
        printf 'DIR: %s\n' "$rel" >> "$project_dir/$output_file"
      else
        printf 'FILE: %s\n' "$rel" >> "$project_dir/$output_file"
        $include_meta && printf 'META: %s\n' "${meta#*,}" >> "$project_dir/$output_file"
        sed 's/^/    /' "$file" >> "$project_dir/$output_file"
      fi;;
    markdown)
      if $is_dir; then
        printf '## 📁 %s\n' "$rel" >> "$project_dir/$output_file"
      else
        printf '### 📄 %s\n' "$rel" >> "$project_dir/$output_file"
        $include_meta && printf '**Meta:** %s\n' "${meta#*,}" >> "$project_dir/$output_file"
        printf '```\n' >> "$project_dir/$output_file"
        sed '' "$file" >> "$project_dir/$output_file"
        printf '```\n' >> "$project_dir/$output_file"
      fi;;
  esac
}

# --- PROGRESS BAR ---
show_progress() {
  local cur=$1 tot=$2 width=40 filled percent
  if (( tot>0 )); then
    filled=$(( cur * width / tot ))
    percent=$(( cur * 100 / tot ))
  else
    filled=0; percent=0
  fi
  local bar=$(printf '%*s' "$filled" '' | tr ' ' '#')
  bar=$(printf '%-40s' "$bar")
  printf '\r[%s] %3d%%' "$bar" "$percent"
}

# --- MAIN ---
parse_args "$@"
init_output
collect_paths

echo "Starting export ($output_format) → $output_file"

total=${#paths[@]}
(( total == 0 )) && { echo "No files matched filters. Exiting."; exit 0; }

for i in "${!paths[@]}"; do
  ((n=i+1))
  show_progress $n $total
  output_entry "${paths[i]}"
done

[[ $output_format == json ]] && {
  truncate -s-2 "$project_dir/$output_file"
  printf '\n]' >> "$project_dir/$output_file"
}

echo -e "\nExport completed: $project_dir/$output_file"
