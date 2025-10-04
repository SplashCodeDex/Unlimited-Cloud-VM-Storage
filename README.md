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
| **🧪 Automated Testing** | A full suite of tests ensures the stability and reliability of the project as it grows. |

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

The `workspace` command is designed to be intuitive and fast.

#### Create or Switch to a Workspace

```bash
# Use a full git URL, a project name, or a local path
workspace https://github.com/your-username/your-project.git
```

#### View Your Workspace History

Run `workspace` with no arguments to see your "frecency"-ranked list of projects in an interactive menu.

```bash
workspace
```

#### Syncing a Workspace

The `workspace` tool can automatically detect and move large, untracked directories (like `node_modules`) to ephemeral storage to save space. This scan is performed automatically when you create or open a workspace.

However, if you create a large directory after the initial scan, you can manually trigger the scan by running the `workspace sync` command from within your workspace directory.

```bash
workspace sync
```

#### Commands

*   `workspace sync`: Scans the current workspace for large, untracked directories and moves them to ephemeral storage.
*   `workspace warm`: Fetches the latest changes for all your Git-based workspaces.
*   `workspace doctor`: Runs a health check on your environment to diagnose and fix common issues.
*   `workspace --json`: Outputs a machine-readable list of all workspaces, used by the VS Code extension.

---

## The Road Ahead

We're just getting started. Our vision is to make `workspace` an indispensable part of the modern development workflow. Here's what we're thinking about for the future:

- [ ] **Workspace Templates:** Quickly start new projects (e.g., `workspace new --template=react-vite`) with pre-configured boilerplate.

Have an idea? We'd love to hear it!

## Contributing

Contributions are welcome and encouraged! Feel free to open an issue to report a bug or suggest a feature, or open a pull request to directly contribute to the codebase.