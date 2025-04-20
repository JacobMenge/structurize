# Structurize

**Structurize** is a clean, interactive Bash tool for project structure analysis. It exports the layout of your codebase in formats like **JSON**, **NDJSON**, **Markdown**, or **Text**, making it ideal for AI preprocessing, documentation, DevOps audits, and code reviews.

---

## 🌊 Features

- ✨ Export in **four formats**: `json`, `ndjson`, `markdown`, `text`
- ⏳ **Live progress bar** (clean, readable display)
- ⚡ **Lightweight** – only requires `bash`, `find`, `sed`, `stat`
- 🤖 **AI-ready**: NDJSON and Markdown are token-efficient
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
|        | `--debug`        | Show current file inline during export                    |
| `-h`   | `--help`         | Display help message                                      |

---

## 👀 Examples

### Export a React frontend
```bash
structurize -n --debug -m \
  -e node_modules,.git,public \
  -t js,jsx,ts,tsx,json \
  -s src \
  -o frontend.ndjson
```

### Export a Node.js backend
```bash
structurize -n --debug -m \
  -e node_modules,.git,tests \
  -t js,json \
  -s src \
  -o backend.ndjson
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

## 🚚 Use Cases

- 🤖 Preprocessing for AI (ChatGPT, LLMs, Copilots)
- 📄 Auto-documentation of codebases
- 📊 DevOps audits & compliance exports
- 📚 Developer onboarding & code reviews

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

