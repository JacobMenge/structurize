# Structurize

**Structurize** is an interactive Bash tool for project structure and dependency analysis. It exports the layout and relationships of your codebase in formats like **JSON**, **NDJSON**, **Markdown**, or **Text**, making it ideal for AI preprocessing, documentation, DevOps audits, and code reviews.

---

## 🌊 Features

- ✨ Export in **four formats**: `json`, `ndjson`, `markdown`, `text`
- 🧩 **Dependency analysis**: Detect imports and module relationships
- 📊 **Graph visualization**: Generate dependency graphs in DOT or Mermaid format
- 🔍 **Cycle detection**: Identify circular dependencies
- ⏳ **Live progress bar** (clean, readable display)
- ⚡ **Lightweight** – only requires `bash`, `find`, `sed`, `stat`
- 🤖 **AI-ready**: NDJSON and Markdown are token-efficient with included prompt templates
- ⚙️ **Advanced filtering**: file types, subdirectories, exclusions
- 📅 Optional: **Metadata export** (file size, timestamps)
- 🪄 Optional `--debug` mode for transparent file tracking

---

## 🚀 Quickstart

### 1. Installation (local or global)

#### Local usage:
```bash
chmod +x structurize.sh
./structurize.sh --help
```

#### Global CLI usage:
```bash
sudo mv structurize.sh /usr/local/bin/structurize
structurize --help
```

Now you can call the tool from anywhere via `structurize`.

---

## 🔧 CLI Options

| Short | Long             | Description                                                |
|--------|------------------|------------------------------------------------------------|
| `-d`   | `--directory`    | Base directory (default: current directory)               |
| `-o`   | `--output`       | Output file path (default: `project_structure.json`)      |
| `-f`   | `--format`       | Output format: `text`, `markdown`, `json`, `ndjson`       |
| `-n`   | `--ndjson`       | Shortcut for `-f ndjson`                                  |
| `-m`   | `--meta`         | Include file size and modification timestamp              |
| `-e`   | `--exclude`      | Comma-separated paths or glob patterns to exclude         |
| `-s`   | `--select`       | Comma-separated subdirectories to include                 |
| `-t`   | `--types`        | Comma-separated file extensions (e.g. `js,ts,json`)       |
| `-a`   | `--analyze`      | Analyze dependencies: none (default), deps, imports       |
|        | `--graph`        | Output dependency graph in: dot | mermaid (requires -a)   |
|        | `--debug`        | Show current file inline during export                    |
| `-h`   | `--help`         | Display help message                                      |

---

## 👀 Examples

### Basic Structure Export

```bash
structurize -n --debug -m \
  -e node_modules,.git,public \
  -t js,jsx,ts,tsx,json \
  -s src \
  -o frontend.ndjson
```

### Dependency Analysis for JavaScript/TypeScript

```bash
structurize -n --debug -m \
  -e node_modules,.git,tests \
  -t js,jsx,ts,tsx \
  -s src \
  -a deps \
  -o project_deps.ndjson
```

### Generate Dependency Graph (Mermaid)

```bash
structurize -f json -a deps \
  -e node_modules,.git \
  -t js,ts \
  --graph mermaid \
  -o project_deps.json
```

### Export fullstack project (Docker + Backend + Frontend)

```bash
structurize -n --debug -m \
  -e node_modules,.git,tests \
  -t js,ts,json,yml,yaml,conf,dockerignore,env \
  -o project.ndjson
```

Optional: Markdown format for documentation:
```bash
structurize -f markdown -m -o structure.md
```

---

## 🔄 Dependency Analysis

The dependency analysis feature helps you:

1. **Track imports/requires** between files
2. **Visualize module relationships** with graph output
3. **Detect circular dependencies** that could cause issues
4. **Generate AI-ready prompts** for architecture improvements

Currently supported languages for dependency analysis:
- JavaScript (ES6 imports, CommonJS require)  
- TypeScript (imports)
- Python (import, from...import)

More languages will be added in future versions.

---

## 📊 Graph Visualization

Generate visual representations of your project's dependencies:

- **DOT format**: Compatible with Graphviz for high-quality graphs
- **Mermaid format**: Embed in Markdown and GitHub

Example:
```bash
structurize -a deps --graph mermaid -t js,ts -o deps.json
```

This creates:
1. `deps.json` with detailed dependency data
2. `deps_graph.mermaid` with Mermaid-formatted graph
3. `deps_ai_prompt.txt` with an AI prompt template

---

## 🤖 AI-Integration

When running in dependency analysis mode, Structurize automatically generates an AI prompt template to help you:

1. Improve your architecture
2. Resolve circular dependencies
3. Optimize module structure

Simply attach the output file to the generated prompt and send to your preferred AI assistant.

---

## 🚚 Use Cases

- 🤖 Preprocessing for AI (ChatGPT, LLMs, Copilots)
- 📄 Auto-documentation of codebases
- 📊 DevOps audits & compliance exports
- 📚 Developer onboarding & code reviews
- 🧩 Architecture analysis and improvements
- 🔍 Dependency management and optimization

---

## 💼 License

MIT License. Free to use and modify.

---

## ✨ Pro Tip

Run with `--debug` first to see what gets included:
```bash
structurize -n --debug -o check.ndjson
```

If nothing is exported: double-check your filters (`-t`, `-s`, `-e`) or remove them for testing.
