# Unlimited Cloud VM Storage VS Code Extension

This VS Code extension provides a rich, graphical user interface for managing your ephemeral workspaces. It complements the `workspace` command-line tool, providing a seamless and intuitive experience for creating, managing, and switching between your development environments.

## Features

*   **Workspace Tree View:** The extension adds a new "Workspaces" view to the VS Code sidebar. This view displays a tree of all your available workspaces, making it easy to see and interact with them.
*   **Rich Workspace Information:** The tree view displays rich information about each workspace, including its Git status, current branch, and last commit.
*   **One-Click Workspace Opening:** You can open any workspace in a new VS Code window with a single click.
*   **Context Menu Commands:** The extension provides a context menu for each workspace, allowing you to perform the following actions:
    *   **Open Workspace:** Open the workspace in a new VS Code window.
    *   **Warm Workspace:** Run the `workspace warm` command on the workspace to fetch the latest changes from the remote repository.
    *   **Run Doctor:** Run the `workspace doctor` command to check for common problems with your workspace setup.
    *   **Delete Workspace:** Delete the workspace from your local machine.

## Installation

1.  **Install the `workspace` tool:** Before you can use this extension, you must first install the `workspace` command-line tool. You can do this by running the following command in your terminal:

    ```bash
    bash <(curl -s https://raw.githubusercontent.com/your-username/unlimited-cloud-vm-storage/main/install.sh)
    ```

2.  **Install the extension:** Once you have installed the `workspace` tool, you can install the VS Code extension by following these steps:

    *   Open the Extensions view in VS Code (click the Extensions icon in the Activity Bar on the side of the window).
    *   Search for "Unlimited Cloud VM Storage".
    *   Click the "Install" button.

## Usage

Once you have installed the extension, you will see a new "Workspaces" view in the sidebar. This view will display a list of all your available workspaces.

To interact with a workspace, simply right-click on it in the tree view and select the desired command from the context menu.

## Contributing

Contributions are welcome! If you have any ideas for new features or improvements, please open an issue or submit a pull request on the [GitHub repository](https://github.com/your-username/unlimited-cloud-vm-storage).
