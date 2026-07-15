# Prevent Supply Chain Attack (Guide)

This guide describes safety verification procedures and how to set up a global execution environment to prevent supply chain attacks when installing any npm package — especially packages suggested or installed by an AI coding agent such as **Claude Code**.

---

## 1. Overview and Background

Supply chain attacks targeting the open-source ecosystem (NPM) are becoming increasingly sophisticated. When working with an AI coding agent like Claude Code, package installation commands can be proposed and run quickly, so it's important to verify a package's safety before installing it.
This guide helps you verify the safety of packages before installing them in your application development environment.

---

## 2. Global Execution Environment and Alias Setup

By storing the safety check script (`pkg-supply-chain-check.sh`) in the global `C:\Users\sdok1\projects` path, you can easily call and use it from any subdirectory of your projects.

### A. WSL (Windows Subsystem for Linux) / Git Bash Environment
Register the alias in your `~/.bashrc` or `~/.zshrc` file:
```bash
# ~/.bashrc or ~/.zshrc

# For Git Bash (Windows):
alias pkg-check='bash /c/Users/sdok1/projects/pkg-supply-chain-check.sh'

# For WSL (Linux):
alias pkg-check='bash /mnt/c/Users/sdok1/projects/pkg-supply-chain-check.sh'
```
Apply the settings:
```bash
source ~/.bashrc
```

### B. Windows PowerShell Environment
Add the following function to your PowerShell profile (`$PROFILE`):
```powershell
# Edit PowerShell Profile: notepad $PROFILE
function pkg-check {
    bash C:\Users\sdok1\projects\pkg-supply-chain-check.sh $args
}
```

---

## 3. Usage of `pkg-supply-chain-check.sh`

Once the global alias is set up, you can run it immediately in the terminal regardless of your project folder path. A package name is required.

```bash
# 1) Inspect the latest version of a package
pkg-check chalk

# 2) Inspect a specific version of a package
pkg-check chalk 5.0.0

# 3) Inspect any other package Claude Code proposes installing
pkg-check <package_name>
pkg-check <package_name> <version>
```

---

## 4. Summary of the 8-Step Security Inspection Process

When executed, the script safely performs the following 8 checks in a temporary directory:

### 1) Inspect NPM Metadata
- Retrieves the package's release times, registered maintainers, and list of recent versions to verify if there are any sudden changes in maintainers or abnormal release patterns.

### 2) Download Tarball and Verify File List
- Uses `npm pack` to download the package archive (`.tgz`) locally and inspects the file list without extracting it (`tar -tzf`).
- Filters out any unfamiliar executable files (`.exe`, `.dll`, `.sh`, etc.) or obfuscated scripts that do not fit the package's purpose.

### 3) Review package.json Key Fields
- Extracts `scripts`, `dependencies`, and `devDependencies` to inspect the internal dependency structure.

### 4) Check for Suspicious Lifecycle Scripts
- Checks if lifecycle scripts that run automatically upon package installation (such as `preinstall`, `install`, `postinstall`, `prepare`) are defined.
- If they exist, the command log forces you to manually review the commands to be executed.

### 5) Scan for Historically Problematic Packages
- Scans if utility packages that were historically hijacked or used as channels for malware distribution (e.g., `chalk`, `debug`, `ansi-styles`, `strip-ansi`, `colors`, `braces`) are directly included in the dependencies of the target version.

### 6) Generate package-lock with `--ignore-scripts`
- When running a mock installation to verify the dependency tree, it applies `--ignore-scripts` and `--package-lock-only` options to safely retrieve only the dependency list (`package-lock.json`) without executing any malicious scripts.

### 7) Run NPM Audit (Known Vulnerabilities Check)
- Evaluates whether `HIGH` or `CRITICAL` security flaws are reported in the current package and its dependency tree against the known vulnerability database.

### 8) Network and Manual Analysis Guide
- Outputs additional inspection tips, such as suspicious command patterns and vulnerability mitigation guidelines.

---

## 5. Proposed Security Workflow for Developers

1. **Initialize New Project**: Create `C:\Users\sdok1\projects\my-new-app` directory and run `npm init`.
2. **Perform Pre-inspection**: Before installing any library — including one proposed by Claude Code — run `pkg-check <package_name>` first.
3. **Review Results**: If no errors or warnings are found, proceed with confidence by running `npm install <package_name>`.
4. **Regular Audits**: Whenever updating libraries, pass the target version to inspect it (`pkg-check <package_name> <version>`).
