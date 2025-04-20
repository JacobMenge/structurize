# Structurize

**Structurize** is a versatile Bash utility that exports a full, machine‑readable snapshot of any programming project. It can output directory structures, file contents, and optional metadata in **JSON**, **NDJSON**, **Markdown**, or **plain text**, making it ideal for:

- **AI pipelines** and token‑efficient project ingestion
- **Documentation**, READMEs, or code review supplements
- **Automated audits**, static analysis, and tooling integration

---

## 🚀 Features

- **Multi‑format export**
  - **JSON**: compact array of objects
  - **NDJSON**: one JSON object per line, perfect for streaming
  - **Markdown**: human‑readable sections with code fences
  - **Plain text**: simple indented listing

- **Real‑time progress bar** for large codebases
- **Flexible filtering**
  - Exclude arbitrary glob patterns (e.g. `node_modules`, `.git`)
  - Restrict to specific subdirectories (e.g. `src`, `lib`)
  - Limit to chosen file extensions (e.g. `js`, `py`)

- **Optional metadata**: file size & modification timestamp
- **Self‑healing**:
  - Strips Windows CRLF line endings and UTF‑8 BOM on launch
  - Works unmodified on native Linux and WSL environments

- **Zero dependencies** beyond standard Unix utilities (`bash`, `find`, `sed`, `stat`, etc.)
- **Clean, modular code** with clear English comments

---

## 📦 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/<YOUR_USER>/structurize.git
   cd structurize
   ```

2. **Make the script executable**
   ```bash
   chmod +x structurize.sh
   ```

3. *(Optional)* **Install globally**
   ```bash
   sudo mv structurize.sh /usr/local/bin/structurize
   ```

---

## 🛠️ Usage

Run the script from any project directory:

```bash
./structurize.sh [OPTIONS]
```

If installed globally:

```bash
structurize [OPTIONS]
```

By default, it scans the current directory and writes a JSON array to `project_structure.json`.

---

## ⚙️ Command‑Line Options

| Short | Long         | Description                                                              | Default                        |
|:-----:|--------------|--------------------------------------------------------------------------|--------------------------------|
| `-d`  | `--directory`| Base directory to scan                                                   | `.`                            |
| `-o`  | `--output`   | Output file path                                                         | `project_structure.json`       |
| `-f`  | `--format`   | `text` \| `markdown` \| `json` \| `ndjson`                               | `json`                         |
| `-n`  | `--ndjson`   | Shortcut for `-f ndjson`                                                 | —                              |
| `-m`  | `--meta`     | Include file size and modification time                                  | Off                            |
| `-e`  | `--exclude`  | Comma‑separated glob patterns (relative) to exclude                      | —                              |
| `-s`  | `--select`   | Comma‑separated subdirectories to include exclusively                    | —                              |
| `-t`  | `--types`    | Comma‑separated file extensions (without `.`)                            | —                              |
| `-h`  | `--help`     | Display this help message                                                | —                              |

---

## 📚 Examples

1. **Default JSON export**  
   ```bash
   ./structurize.sh
   ```

2. **NDJSON, excluding `node_modules` & `.git`**  
   ```bash
   ./structurize.sh -n \
     -e node_modules,.git \
     -o project.ndjson
   ```

3. **Markdown with metadata**  
   ```bash
   ./structurize.sh \
     -f markdown \
     -m \
     -o structure.md
   ```

4. **Plain text, only `src` and `lib`, limit to `.js` files**  
   ```bash
   ./structurize.sh \
     -f text \
     -s src,lib \
     -t js \
     -o src-index.txt
   ```

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a new branch: `git checkout -b feature/my-feature`
3. Make changes, follow existing code style
4. Commit and push your branch
5. Open a Pull Request

Please include tests, examples, or updated documentation where applicable.

---

## 📄 License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for full text.

---

> **Structurize**: export your project’s structure and content quickly, clearly, and in AI‑friendly formats.
