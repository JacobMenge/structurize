#!/usr/bin/env bash
# Structurize v4.0.0 – with dependency analysis & clean display mode

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
analyze_mode=""

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
  -a, --analyze TYPE      analyze dependencies: none (default), deps, imports
  --graph FORMAT          output dependency graph in: dot | mermaid (requires -a)
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
      -a|--analyze)   analyze_mode="$2"; shift 2;;
      --graph)        graph_format="$2"; shift 2;;
      --debug)        debug=true; shift;;
      -h|--help)      show_usage;;
      *) echo "❌ Unknown option '$1'" >&2; show_usage;;
    esac
  done
  
  # Validate analyze_mode
  if [[ -n "$analyze_mode" && "$analyze_mode" != "none" && "$analyze_mode" != "deps" && "$analyze_mode" != "imports" ]]; then
    echo "❌ Invalid analyze mode: $analyze_mode. Must be 'none', 'deps', or 'imports'" >&2
    exit 1
  fi
  
  # Validate graph_format if analyze_mode is set
  if [[ -n "$analyze_mode" && "$analyze_mode" != "none" && -n "${graph_format:-}" ]]; then
    if [[ "$graph_format" != "dot" && "$graph_format" != "mermaid" ]]; then
      echo "❌ Invalid graph format: $graph_format. Must be 'dot' or 'mermaid'" >&2
      exit 1
    fi
  fi
}

init_output() {
  : > "$project_dir/$output_file"
  if [[ $output_format == json ]]; then
    if [[ -n "$analyze_mode" && "$analyze_mode" != "none" ]]; then
      printf '{"nodes":[],"edges":[],"cycles":[],"stats":{}}' > "$project_dir/$output_file"
    else
      printf '[' > "$project_dir/$output_file"
    fi
  fi
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
    json)   
      if [[ -z "$analyze_mode" || "$analyze_mode" == "none" ]]; then
        printf '%s,' "$entry" >> "$project_dir/$output_file"
      else
        # For dependency analysis, we'll handle JSON differently
        # This is a placeholder for the analyze function
        :
      fi
      ;;
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

get_file_language() {
  local file="$1"
  local ext="${file##*.}"
  
  case "$ext" in
    js|jsx|mjs) echo "javascript" ;;
    ts|tsx) echo "typescript" ;;
    py) echo "python" ;;
    java) echo "java" ;;
    go) echo "go" ;;
    rb) echo "ruby" ;;
    php) echo "php" ;;
    rs) echo "rust" ;;
    c|cpp|cc|h|hpp) echo "c++" ;;
    cs) echo "csharp" ;;
    *) echo "unknown" ;;
  esac
}

analyze_file_dependencies() {
  local file="$1"
  local lang="$(get_file_language "$file")"
  local deps=()
  
  # Skip directories and unsupported languages
  [[ -d "$file" || "$lang" == "unknown" ]] && return
  
  case "$lang" in
    javascript|typescript)
      # Extract CommonJS require and ES6 imports
      while IFS= read -r line; do
        # Match ES6 import statements
        if [[ "$line" =~ import[[:space:]]+.*from[[:space:]]+[\"\'](\..*|\/.*)[\"\']\; ]]; then
          dep="${BASH_REMATCH[1]}"
          deps+=("$dep")
        # Match CommonJS require statements
        elif [[ "$line" =~ require\([[:space:]]*[\"\'](\..*|\/.*)[\"\']\) ]]; then
          dep="${BASH_REMATCH[1]}"
          deps+=("$dep")
        fi
      done < "$file"
      ;;
    python)
      # Extract Python imports
      while IFS= read -r line; do
        # Match from X import Y
        if [[ "$line" =~ ^[[:space:]]*from[[:space:]]+([^[:space:]]+)[[:space:]]+import ]]; then
          dep="${BASH_REMATCH[1]}"
          # Only include relative imports
          if [[ "$dep" == "." || "$dep" == ".."* ]]; then
            deps+=("$dep")
          fi
        # Match import X
        elif [[ "$line" =~ ^[[:space:]]*import[[:space:]]+([^[:space:],]+) ]]; then
          dep="${BASH_REMATCH[1]}"
          # Only include relative imports
          if [[ "$dep" == "." || "$dep" == ".."* ]]; then
            deps+=("$dep")
          fi
        fi
      done < "$file"
      ;;
    # Add more languages as needed
  esac
  
  # Resolve relative paths to full paths
  local dir="$(dirname "$file")"
  local resolved_deps=()
  
  for dep in "${deps[@]}"; do
    # Resolve the dependency path
    local resolved=""
    
    # Handle different types of imports
    if [[ "$dep" == "." ]]; then
      resolved="$dir"
    elif [[ "$dep" == "./"* ]]; then
      resolved="$dir/${dep:2}"
    elif [[ "$dep" == "../"* ]]; then
      # Handle parent directory traversal
      local parent_count=$(echo "$dep" | grep -o "\.\.\/" | wc -l)
      local current_dir="$dir"
      for ((i=0; i<parent_count; i++)); do
        current_dir="$(dirname "$current_dir")"
      done
      resolved="$current_dir/$(echo "$dep" | sed "s/\(\.\.\/\)\{$parent_count\}//")"
    else
      # For absolute paths or non-relative imports
      resolved="$dep"
    fi
    
    # For JavaScript/TypeScript, try to resolve with different extensions
    if [[ "$lang" == "javascript" || "$lang" == "typescript" ]]; then
      local found=false
      local extensions=(".js" ".jsx" ".ts" ".tsx" ".json")
      
      # Check if the resolved path exists with any of the extensions
      for ext in "${extensions[@]}"; do
        if [[ -f "$resolved$ext" ]]; then
          resolved_deps+=("$resolved$ext")
          found=true
          break
        fi
      done
      
      # Check if it's a directory with an index file
      if [[ ! $found && -d "$resolved" ]]; then
        for ext in "${extensions[@]}"; do
          if [[ -f "$resolved/index$ext" ]]; then
            resolved_deps+=("$resolved/index$ext")
            found=true
            break
          fi
        done
      fi
    else
      # For other languages, just add the resolved path
      resolved_deps+=("$resolved")
    fi
  done
  
  # Output dependencies in JSON format for further processing
  for dep in "${resolved_deps[@]}"; do
    echo "{\"source\":\"$file\",\"target\":\"$dep\"}"
  done
}

detect_cycles() {
  local deps_file="$1"
  local tmp_file="$project_dir/.structurize_cycles_tmp"
  
  # Use a simple DFS algorithm to detect cycles
  # This is a placeholder - in a real implementation, you'd use a more robust algorithm
  echo "[]" > "$tmp_file"
  
  # Return path to the tmp file
  echo "$tmp_file"
}

analyze_dependencies() {
  echo "🔍 Analyzing dependencies..."
  
  # Create a temporary file for dependency data
  local deps_file="$project_dir/.structurize_deps_tmp"
  : > "$deps_file"
  
  local total=${#paths[@]}
  local nodes=()
  local edges=()
  
  # Process each file
  for i in "${!paths[@]}"; do
    local n=$((i+1))
    local file="${paths[i]}"
    local rel="${file#$project_dir/}"
    local msg=$([[ $debug == true ]] && echo "Analyzing $rel" || echo "")
    show_progress "$n" "$total" "$msg"
    
    # Skip directories
    [[ -d "$file" ]] && continue
    
    # Get file language and size
    local lang="$(get_file_language "$file")"
    local size="$(wc -c < "$file" 2>/dev/null || echo "0")"
    
    # Add to nodes
    nodes+=("{\"id\":\"$rel\",\"type\":\"file\",\"language\":\"$lang\",\"size\":$size}")
    
    # Get dependencies if not in "none" mode
    if [[ "$analyze_mode" == "deps" || "$analyze_mode" == "imports" ]]; then
      while IFS= read -r dep; do
        [[ -z "$dep" ]] && continue
        edges+=("$dep")
      done < <(analyze_file_dependencies "$file")
    fi
  done
  
  # Process data and generate final output
  local cycles_file="$(detect_cycles "$deps_file")"
  
  # Prepare JSON output
  if [[ "$output_format" == "json" ]]; then
    # Start with empty structure
    echo "{" > "$project_dir/$output_file"
    
    # Add nodes
    echo "\"nodes\": [" >> "$project_dir/$output_file"
    for ((i=0; i<${#nodes[@]}; i++)); do
      if ((i == ${#nodes[@]} - 1)); then
        echo "${nodes[i]}" >> "$project_dir/$output_file"
      else
        echo "${nodes[i]}," >> "$project_dir/$output_file"
      fi
    done
    echo "]," >> "$project_dir/$output_file"
    
    # Add edges
    echo "\"edges\": [" >> "$project_dir/$output_file"
    for ((i=0; i<${#edges[@]}; i++)); do
      if ((i == ${#edges[@]} - 1)); then
        echo "${edges[i]}" >> "$project_dir/$output_file"
      else
        echo "${edges[i]}," >> "$project_dir/$output_file"
      fi
    done
    echo "]," >> "$project_dir/$output_file"
    
    # Add cycles (from the cycles file)
    echo "\"cycles\": $(cat "$cycles_file")," >> "$project_dir/$output_file"
    
    # Add statistics
    echo "\"stats\": {" >> "$project_dir/$output_file"
    echo "  \"totalFiles\": ${#nodes[@]}," >> "$project_dir/$output_file"
    echo "  \"totalDependencies\": ${#edges[@]}" >> "$project_dir/$output_file"
    echo "}" >> "$project_dir/$output_file"
    
    echo "}" >> "$project_dir/$output_file"
  elif [[ "$output_format" == "ndjson" ]]; then
    # NDJSON format: one JSON object per line
    for node in "${nodes[@]}"; do
      echo "{\"type\":\"node\",\"data\":$node}" >> "$project_dir/$output_file"
    done
    
    for edge in "${edges[@]}"; do
      echo "{\"type\":\"edge\",\"data\":$edge}" >> "$project_dir/$output_file"
    done
    
    # Add cycles and stats
    local cycles_content="$(cat "$cycles_file")"
    echo "{\"type\":\"cycles\",\"data\":$cycles_content}" >> "$project_dir/$output_file"
    echo "{\"type\":\"stats\",\"data\":{\"totalFiles\":${#nodes[@]},\"totalDependencies\":${#edges[@]}}}" >> "$project_dir/$output_file"
  fi
  
  # Generate graph if requested
  if [[ -n "${graph_format:-}" ]]; then
    generate_graph "$project_dir/$output_file" "$project_dir/${output_file%.*}_graph.${graph_format}"
  fi
  
  # Clean up temporary files
  rm -f "$deps_file" "$cycles_file"
}

generate_graph() {
  local input_file="$1"
  local output_file="$2"
  
  echo "📊 Generating dependency graph in ${graph_format} format..."
  
  if [[ "$graph_format" == "dot" ]]; then
    # Generate DOT format (Graphviz)
    echo "digraph DependencyGraph {" > "$output_file"
    echo "  node [shape=box];" >> "$output_file"
    
    # Add nodes
    if [[ "$output_format" == "json" ]]; then
      # Extract nodes from JSON
      local nodes=$(grep -o '"id":"[^"]*"' "$input_file" | cut -d'"' -f4)
      for node in $nodes; do
        echo "  \"$node\";" >> "$output_file"
      done
      
      # Extract edges from JSON
      local source=$(grep -o '"source":"[^"]*"' "$input_file" | cut -d'"' -f4)
      local target=$(grep -o '"target":"[^"]*"' "$input_file" | cut -d'"' -f4)
      paste <(echo "$source") <(echo "$target") | while read -r src tgt; do
        # Remove project directory prefix
        src="${src#$project_dir/}"
        tgt="${tgt#$project_dir/}"
        echo "  \"$src\" -> \"$tgt\";" >> "$output_file"
      done
    fi
    
    echo "}" >> "$output_file"
    
  elif [[ "$graph_format" == "mermaid" ]]; then
    # Generate Mermaid format
    echo "```mermaid" > "$output_file"
    echo "graph TD" >> "$output_file"
    
    # Add nodes and edges
    if [[ "$output_format" == "json" ]]; then
      # Extract nodes from JSON
      local nodes=$(grep -o '"id":"[^"]*"' "$input_file" | cut -d'"' -f4)
      for node in $nodes; do
        local clean_node=$(echo "$node" | tr -c '[:alnum:]' '_')
        echo "  $clean_node[\"$node\"]" >> "$output_file"
      done
      
      # Extract edges from JSON
      local source=$(grep -o '"source":"[^"]*"' "$input_file" | cut -d'"' -f4)
      local target=$(grep -o '"target":"[^"]*"' "$input_file" | cut -d'"' -f4)
      paste <(echo "$source") <(echo "$target") | while read -r src tgt; do
        # Remove project directory prefix and clean node names
        src="${src#$project_dir/}"
        tgt="${tgt#$project_dir/}"
        local clean_src=$(echo "$src" | tr -c '[:alnum:]' '_')
        local clean_tgt=$(echo "$tgt" | tr -c '[:alnum:]' '_')
        echo "  $clean_src --> $clean_tgt" >> "$output_file"
      done
    fi
    
    echo "```" >> "$output_file"
  fi
  
  echo "✅ Graph saved to: ${output_file}"
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

generate_ai_prompt() {
  # Generate a helpful prompt template for AI usage
  local prompt_file="${output_file%.*}_ai_prompt.txt"
  
  echo "Creating AI prompt template in $prompt_file..."
  
  cat <<EOF > "$project_dir/$prompt_file"
Here is the dependency structure of my project, analyzed with Structurize:
- \${totalFiles} files analyzed
- \${totalDependencies} dependencies found
- \${totalCycles} circular dependencies identified

The main modules are: \${topModules}

Please help me with the following:
1. How can I resolve the circular dependencies?
2. How can I improve the module structure?
3. What architectural patterns do you recommend for better organization?

[Attach the ${output_file} content below]
EOF

  echo "✅ AI prompt template saved to: $project_dir/$prompt_file"
}

# --- MAIN ---
parse_args "$@"
init_output
collect_paths

if [[ -n "$analyze_mode" && "$analyze_mode" != "none" ]]; then
  echo "📊 Starting dependency analysis → $output_file"
  analyze_dependencies
  generate_ai_prompt
else
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
fi

echo -e "\n✅ Export completed: $project_dir/$output_file"
