# Unlimited-Cloud-VM-Storage: The Intelligent Ephemeral Workspace Manager To Increase Your Google Cloudshell, GitHub Codespaces, Gitpod, Firebase Studio free 5GB and 15GB to Unlimited and avoid the 'Not enough Space/Storage' problem.

**Tired of hitting storage limits on Google Cloud Shell? Juggling projects across GitHub Codespaces, Gitpod, Firebase Studio and other remote VMs? `Unlimited-Cloud-VM-Storage` is the seamless solution for a clean, efficient, and unified workflow.**

`Unlimited-Cloud-VM-Storage` is a powerful command-line tool for creating and managing ephemeral development environments. It keeps your home directory pristine and your workflow laser-focused by creating temporary, isolated workspaces for each of your projects. Its intelligent history system learns your habits, always presenting your most relevant projects first, no matter the platform.

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Language](https://img.shields.io/badge/Language-Shell-blue.svg)
![Platforms](https://img.shields.io/badge/Platforms-Codespaces%20%7C%20Cloud%20Shell%20%7C%20Gitpod%20%7C%20Remote%20VMs-blueviolet)

---

> You're in a GitHub Codespace, you've just finished a feature and want to switch to a different project. You have to find the project, open a new Codespace, wait for it to build, and then finally get to work. With `Unlimited-Cloud-VM-Storage`, you can switch between projects in seconds, without ever leaving your terminal.

<br>

## Your Universal Dev Environment Companion

`Unlimited-Cloud-VM-Storage` is the ultimate workspace manager for developers who work in a variety of ephemeral environments. Its lightweight and portable nature means you can have a consistent and efficient workflow, no matter where you code.

- **GitHub Codespaces:** Instantly switch between projects without the delay of creating and provisioning new Codespaces. Keep your environment clean and your productivity high.
- **Google Cloud Shell & Firebase:** Say goodbye to the 5GB storage limit. `Unlimited-Cloud-VM-Storage` manages all your projects in temporary storage, keeping your home directory lean and your sessions fast.
- **Gitpod:** Supercharge Gitpod's "fresh workspace" philosophy. `Unlimited-Cloud-VM-Storage` gives you an intelligent, persistent history of your projects, ready to be checked out in an instant.
- **AWS Cloud9 & Any Remote VM:** Standardize your development workflow across all your remote machines. `Unlimited-Cloud-VM-Storage` provides a consistent, powerful, and portable experience everywhere.

---

## Key Features

| Feature | Description |
| --- | --- |
| **⚡️ Ephemeral Workspaces** | Creates clean, isolated project directories in temporary storage. This keeps your `$HOME` directory pristine and elegantly sidesteps storage limitations on any platform. |
| **🧠 Intelligent History** | Uses a "frecency" (frequency + recency) algorithm to rank your projects. The workspaces you use most often are always just a keypress away. |
| **🌐 Platform Agnostic** | Excels in any modern, cloud-based development environment, including GitHub Codespaces, Google Cloud Shell, Firebase, Gitpod, AWS Cloud9, and any other remote VM. |
| **📌 Pinned Projects** | Pin your most important projects to keep them at the top of the list and ensure they are always "warm" (pre-cloned and ready to go) in the background. |
| **✅ Git-Aware Health** | Provides a "health check" that warns you about uncommitted changes or if your local branch is behind the remote, preventing you from losing work. |
| **🚀 Simple & Portable** | A single, portable shell script with minimal, common dependencies. The robust installer handles dependency checks and integrates with your shell, while the uninstaller ensures a clean removal. |
| **🧪 Automated Testing** | A full suite of tests ensures the stability and reliability of the project as it grows, guaranteeing that new features don't break existing functionality. |
| **👁️ Git-Aware UI** | The interactive menu shows you the current Git branch and status of each workspace, so you can see what you were working on at a glance. |
| **🤖 Smart Integration** | Seamlessly integrates with your existing tools. It can use `autojump` to find projects outside the standard workspace directory, and `fzf` for a powerful interactive menu. |
| **🩺 Health Checks** | The `workspace doctor` command runs a full suite of diagnostics to ensure your environment is healthy and your configuration is correct. |
| **🚀 Non-Invasive Installation** | The smart installer respects your existing shell configuration (`.bashrc`, `.zshrc`, etc.) and adds itself in a non-destructive way. Uninstallation is just as clean. |
| **🧪 Automated Testing** | A full suite of tests ensures the stability and reliability of the project as it grows, guaranteeing that new features don\'t break existing functionality. |

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

The installer is designed to be robust and resilient. It will:

*   **Check for dependencies** and offer to install them for you.
   **Guide you through a first-time setup** to configure your workspace directory.
*   **Non-invasively integrate with your shell** for a seamless experience.

### Uninstallation

We believe a great tool should be as easy to remove as it is to install. The uninstaller will:

*   **Remove all traces of the tool** from your system.
*   **Cleanly unload the shell function**, making the removal immediate.
*   **Optionally remove all user data**, including your workspace history and cached repositories.

```bash
# Navigate to the project directory and run the installer with the --uninstall flag
./install.sh --uninstall
```

---

## Usage

The `workspace` command is designed to be intuitive and fast.

#### Create or Switch to a Workspace

```bash
# You can use a full git URL
workspace https://github.com/your-username/your-project.git

# Or just the project name
workspace your-project

# Or a local path
workspace /path/to/my/existing/project
```
The script will clone the repo into an ephemeral workspace and drop you into the directory. If you run the same command again, it will instantly take you back to that same workspace.

#### View Your Workspace History

Simply run `workspace` with no arguments to see your "frecency"-ranked list of projects.
Simply run `workspace` with no arguments to see your "frecency"-ranked list of projects in a beautiful, interactive `fzf` menu.

```bash
workspace
```
Output:
```
    >   [✓] (main)         your-most-important-project  /home/user/Workspaces/your-most-important-project
      [!M] (feature/new-ui) another-frequent-project   /home/user/Workspaces/another-frequent-project
      [✓] (develop)      less-used-project            /home/user/Workspaces/less-used-project
```

#### Commands

`workspace` also comes with a few helpful sub-commands:

*   `workspace warm`: Fetches the latest changes for all your Git-based workspaces in the background.
*   `workspace doctor`: Runs a health check on your environment to diagnose and fix common issues.

---

## The Road Ahead

We're just getting started. Our vision is to make `workspace` an indispensable part of the modern development workflow. Here's what we're thinking about for the future:

- [ ] **Workspace Templates:** Quickly start new projects (e.g., `workspace new --template=react-vite`) with pre-configured boilerplate.
- [ ] **VS Code Extension:** A graphical user interface within your favorite editor to manage your workspaces.

Have an idea? We'd love to hear it!

## Contributing

Contributions are welcome and encouraged! Feel free to open an issue to report a bug or suggest a feature, or open a pull request to directly contribute to the codebase.