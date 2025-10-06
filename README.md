# Unlimited-Cloud-VM-Storage: The Intelligent Ephemeral Workspace Manager

**Tired of hitting storage limits on Google Cloud Shell? Juggling projects across GitHub Codespaces, Gitpod, or other remote VMs? `Unlimited-Cloud-VM-Storage` is the seamless solution for a clean, efficient, and unified workflow.**

`Unlimited-Cloud-VM-Storage` is a powerful command-line tool for creating and managing ephemeral development environments. It keeps your home directory pristine and your workflow laser-focused by creating temporary, isolated workspaces for each of your projects. Its intelligent history system learns your habits, always presenting your most relevant projects first, no matter the platform.

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Language](https://img.shields.io/badge/Language-Shell-blue.svg)
![Platforms](https://img.shields.io/badge/Platforms-Codespaces%20%7C%20Cloud%20Shell%20%7C%20Gitpod%20%7C%20Remote%20VMs-blueviolet)

---

> You're in a GitHub Codespace, you've just finished a feature and want to switch to a different project. You have to find the project, open a new Codespace, wait for it to build, and then finally get to work. With `Unlimited-Cloud-VM-Storage`, you can switch between projects in seconds, without ever leaving your terminal.

<br>

## Your Universal Dev Environment Companion

`Unlimited-Cloud-VM-Storage` is the ultimate workspace manager for developers who work in a variety of ephemeral environments. Its lightweight and portable nature means you can have a consistent and efficient workflow, no matter where you code.

- **GitHub Codespaces:** Instantly switch between projects without the delay of creating and provisioning new Codespaces.
- **Google Cloud Shell & Firebase:** Say goodbye to the 5GB storage limit. `Unlimited-Cloud-VM-Storage` manages all your projects in temporary storage.
- **Gitpod:** Supercharge Gitpod's "fresh workspace" philosophy with an intelligent, persistent history of your projects.
- **AWS Cloud9 & Any Remote VM:** Standardize your development workflow across all your remote machines.

---

## Key Features

| Feature | Description |
| --- | --- |
| **🎨 VS Code Extension** | A rich, graphical UI to manage workspaces directly within VS Code. View, open, warm, and manage your projects without leaving the editor. |
| **⚡️ Ephemeral Workspaces** | Creates clean, isolated project directories in temporary storage, elegantly sidestepping storage limitations on any platform. |
| **🧠 Intelligent History** | Uses a "frecency" (frequency + recency) algorithm to rank your projects so your most used workspaces are always a keypress away. |
| **🌐 Platform Agnostic** | Excels in any modern, cloud-based development environment, including GitHub Codespaces, Google Cloud Shell, and any other remote VM. |
| **👁️ Git-Aware UI** | The interactive menu shows you the current Git branch and status of each workspace, so you can see what you were working on at a glance. |
| **🤖 Smart Integration** | Seamlessly integrates with existing tools like `autojump` to find projects and `fzf` for a powerful interactive menu. |
| **🩺 Health Checks** | The `workspace doctor` command runs a full suite of diagnostics to ensure your environment is healthy and configured correctly. |
| **🚀 Non-Invasive Installation**| The smart installer respects your existing shell configuration and adds itself non-destructively. Uninstallation is just as clean. |
| **🚀 Automatic Symlinking** | Automatically detects and moves large, untracked directories (like `node_modules`) to ephemeral storage to save space. |

---

## ✨ Now with a VS Code Extension!

Take your workflow to the next level with the official **Unlimited-Cloud-VM-Storage VS Code Extension**. It brings the power of the `workspace` command directly into your editor with a rich, graphical interface.

- **Workspace Tree View:** See all your available workspaces in the VS Code sidebar.
- **Rich Git Status:** Instantly know the branch and status (clean, modified, behind) of every project.
- **One-Click Actions:** Open, warm, or delete workspaces directly from the context menu.
- **Seamless Integration:** The extension uses the `workspace --json` command for a fast and reliable experience.

Find it in the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=your-publisher.unlimited-cloud-vm-storage) (placeholder link).

---

## Getting Started

### Installation

Getting started is as simple as running our smart installer. It handles dependency checks, sets up the executable, and cleanly integrates with your shell (`bash` or `zsh`).

```bash
# Clone the repository
git clone https://github.com/SplashCodeDex/Unlimited-Cloud-VM-Storage.git
cd Unlimited-Cloud-VM-Storage

# Run the installer
./install.sh

# Restart your shell or source your profile to complete the installation
source ~/.bashrc  # or ~/.zshrc, ~/.bash_profile
```

### Uninstallation

```bash
# Navigate to the project directory and run the installer with the --uninstall flag
./install.sh --uninstall
```

---

## Usage

The `workspace` command is the main entry point for interacting with your workspaces.

### Interactive Mode

Running `workspace` without any arguments will launch an interactive menu (using `fzf` if installed) that displays your recent workspaces, ranked by "frecency" (frequency and recency).

```bash
workspace
```

### Direct Mode

You can also interact with workspaces directly:

*   `workspace <n>`: Switch to the nth most recent workspace.
*   `workspace <name>`: Create or switch to a local workspace named `<name>`.
*   `workspace <git_url>`: Clone a git repository and create a new workspace.

### Options

*   `workspace <name> --open` or `workspace <name> -o`: After switching into a workspace, an interactive menu will appear, allowing you to open the project in your editor of choice.

### Commands

*   `workspace warm`: Manually refresh all Git-based workspaces by fetching the latest changes.
*   `workspace doctor`: Check for common problems and offer solutions.
*   `workspace sync`: Scans the current workspace for large, untracked directories and moves them to ephemeral storage.
*   `workspace --json`: Output a JSON list of workspaces for machine consumption.
*   `workspace --help`: Show this help message.

---

## Configuration

The tool is configured via files in the `scripts` and `~/.config/workspace` directories.

### Main Configuration

The main configuration file is located at `scripts/config.sh`. You can modify this file to change the default behavior of the workspace tool.

**Available Options:**

*   `WORKSPACE_BASE_DIR`: The base directory for your workspaces.
*   `EPHEMERAL_CACHE_DIR`: The directory where large directories are symlinked to.
*   `DB_FILE`: The database file for workspace history.
*   `WORKSPACE_CONFIGS_FILE`: The main configuration file for dotfile symlinks.
*   `WARMING_LOG_FILE`: The log file for the warming script.
*   `WARMING_PROJECT_COUNT`: The number of projects to pre-warm in the background.
*   `LARGE_DIR_THRESHOLD_KB`: The threshold for detecting large, untracked directories (in KB).
*   `DISABLE_AUTO_SYMLINK`: Disable automatic symlinking of large directories.

### Editor Configuration

To use the `--open` feature, you can configure your preferred editors in the `~/.config/workspace/editors.conf` file. The installer creates this file with a list of common editors.

The format is simple: `DISPLAY_NAME:COMMAND`. The command will be executed within the project's directory.

**Default `editors.conf`:**
```
# Add your custom editor commands here.
# The format is <NAME>:<COMMAND>
VS Code:code .
Vim:vim .
IntelliJ IDEA:idea .
GoLand:goland .
PyCharm:pycharm .
```
The tool is smart enough to only show you editors from this list that are actually installed on your system.

---

## Automatic Symlinking

The workspace tool automatically detects and symlinks large directories to ephemeral storage. This is done by a set of detector scripts located in `scripts/detectors`.

**Detected Directories:**

*   `build`: If a `build.gradle`, `pom.xml`, or `CMakeLists.txt` file is present.
*   `dist`: If a `package.json` file is present.
*   `.idea`, `.vscode`, `.gradle`: If these directories exist.
*   `.next`: If a `next.config.js` file is present.
*   `node_modules`: If a `package.json` file is present.
*   `.nuxt`: If a `nuxt.config.js` file is present.
*   `target`: If a `Cargo.toml` or `pom.xml` file is present.
*   `vendor`: If a `Gemfile`, `go.mod`, or `composer.json` file is present.

You can also manually specify directories to be symlinked by creating a `.workspace_symlinks` file in the root of your project and listing the directory names within it.

---

## Bash Customizations

The installation script also adds some useful aliases and functions to your shell.

**Aliases:**

*   `ll`: `ls -alF`
*   `la`: `ls -A`
*   `l`: `ls -CF`
*   `alert`: An alias for sending a notification for long-running commands.
*   `clean_vscode`: Cleans up the vscode-server cache.

**Functions:**

*   `workspace`: The main function for interacting with workspaces.

---

## The Road Ahead

We're just getting started. Our vision is to make `workspace` an indispensable part of the modern development workflow. Here's what we're thinking about for the future:

- [ ] **Workspace Templates:** Quickly start new projects (e.g., `workspace new --template=react-vite`) with pre-configured boilerplate.

Have an idea? We'd love to hear it!

## Contributing

Contributions are welcome and encouraged! Feel free to open an issue to report a bug or suggest a feature, or open a pull request to directly contribute to the codebase.