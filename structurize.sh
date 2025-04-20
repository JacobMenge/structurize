#!/usr/bin/env bash
# Structurize v3.9.2 – clean display mode & portable

sed -i '1s/^\xEF\xBB\xBF//' "$0" 2>/dev/null || true
sed -i 's/\r$//' "$0" 2>/dev/null || true
if [[ -z "${_CLEANED:-}" ]]; then
  export _CLEANED=1
  exec bash "$0" "$@"
fi

set -u

project_dir="."
output_file="project_structure.json"
output_format="json"
include_meta=false
exclude_patterns=()
select_dirs=()
type_filters=()
paths=()
debug=false

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
  --debug                 print current file inline during export
  -h, --help              display this help message
EOF
  exit 0
}

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
      --debug)        debug=true; shift;;
      -h|--help)      show_usage;;
      *) echo "❌ Unknown option '$1'" >&2; show_usage;;
    esac
  done
}

init_output() {
  : > "$project_dir/$output_file"
  [[ $output_format == json ]] && printf '[' > "$project_dir/$output_file"
}

get_metadata() {
  stat --format '%s bytes, %y' "$1" 2>/dev/null || echo "unknown"
}

collect_paths() {
  echo "📦 Scanning project files in '$project_dir'..."
  while IFS= read -r -d '' file; do
    [[ $file == $project_dir/$output_file ]] && continue
    for pat in "${exclude_patterns[@]}"; do
      [[ $file == $project_dir/$pat* ]] && continue 2
    done
    if ((${#select_dirs[@]})); then
      keep=false
      for sel in "${select_dirs[@]}"; do
        [[ $file == $project_dir/$sel* ]] && keep=true
      done
      $keep || continue
    fi
    if ((${#type_filters[@]})) && [[ -f $file ]]; then
      ext="${file##*.}"
      [[ ! " ${type_filters[*]} " =~ " $ext " ]] && continue
    fi
    paths+=("$file")
  done < <(find "$project_dir" -print0 | sort -z)
}

output_entry() {
  file="$1"
  rel="${file#$project_dir/}"
  is_dir=false
  [[ -d $file ]] && is_dir=true

  if $is_dir; then
    entry="{\"type\":\"directory\",\"path\":\"$rel\"}"
  else
    content="$(sed 's/"/\\\\\"/g' "$file" 2>/dev/null || echo "")"
    meta=""
    $include_meta && meta=",\"meta\":\"$(get_metadata "$file" | sed 's/"/\\\\\"/g')\""
    entry="{\"type\":\"file\",\"path\":\"$rel\"$meta,\"content\":\"$content\"}"
  fi

  case "$output_format" in
    json)   printf '%s,' "$entry" >> "$project_dir/$output_file";;
    ndjson) printf '%s\n' "$entry" >> "$project_dir/$output_file";;
    text)
      $is_dir && printf 'DIR: %s\n' "$rel" >> "$project_dir/$output_file" || {
        printf 'FILE: %s\n' "$rel" >> "$project_dir/$output_file"
        $include_meta && printf 'META: %s\n' "${meta#*,}" >> "$project_dir/$output_file"
        sed 's/^/    /' "$file" >> "$project_dir/$output_file"
      };;
    markdown)
      $is_dir && printf '## 📁 %s\n' "$rel" >> "$project_dir/$output_file" || {
        printf '### 📄 %s\n' "$rel" >> "$project_dir/$output_file"
        $include_meta && printf '**Meta:** %s\n' "${meta#*,}" >> "$project_dir/$output_file"
        printf '```\n' >> "$project_dir/$output_file"
        sed '' "$file" >> "$project_dir/$output_file"
        printf '```\n' >> "$project_dir/$output_file"
      };;
  esac
}

show_progress() {
  cur=$1
  tot=$2
  msg="${3:-}"
  width=40
  filled=$(( tot > 0 ? cur * width / tot : 0 ))
  percent=$(( tot > 0 ? cur * 100 / tot : 0 ))
  bar=$(printf '%*s' "$filled" '' | tr ' ' '#')
  bar=$(printf '%-40s' "$bar")
  printf "\r🔄 [%s] %3d%% %s" "$bar" "$percent" "$msg"
}

# --- MAIN ---
parse_args "$@"
init_output
collect_paths

echo "📁 Starting export ($output_format) → $output_file"

total=${#paths[@]}
if (( total == 0 )); then
  echo -e "\n⚠️  No files matched the filters!"
  echo "👉 Tipp: Probiere das Skript ohne -t oder -s und aktiviere --debug, um zu sehen, was passiert."
  exit 0
fi

for i in "${!paths[@]}"; do
  n=$((i+1))
  path="${paths[i]}"
  rel="${path#$project_dir/}"
  msg=$([[ $debug == true ]] && echo "$rel" || echo "")
  show_progress "$n" "$total" "$msg"
  output_entry "$path"
done

[[ $output_format == json ]] && {
  truncate -s-2 "$project_dir/$output_file"
  printf '\n]' >> "$project_dir/$output_file"
}

echo -e "\n✅ Export completed: $project_dir/$output_file"
