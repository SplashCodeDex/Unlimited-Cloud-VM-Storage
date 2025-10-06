const vscode = require('vscode');
const { exec } = require('child_process');

class WorkspaceProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }

    refresh() {
        this._onDidChangeTreeData.fire(undefined);
    }

    getTreeItem(element) {
        return element;
    }

    getChildren(element) {
        if (element) {
            return Promise.resolve([]);
        } else {
            return this.getWorkspaces();
        }
    }

    getWorkspaces() {
        return new Promise((resolve, reject) => {
            exec('workspace --json', (error, stdout, stderr) => {
                if (error) {
                    console.error(`exec error: ${error}`);
                    vscode.window.showErrorMessage(`Error fetching workspaces: ${stderr}`);
                    return resolve([]); // Resolve with empty array on error
                }

                try {
                    const workspaces = JSON.parse(stdout);
                    const workspaceItems = workspaces.map(ws => 
                        new Workspace(
                            ws.name,
                            ws.status,
                            ws.branch,
                            ws.last_commit,
                            ws.path,
                            vscode.TreeItemCollapsibleState.None
                        )
                    );
                    resolve(workspaceItems);
                } catch (parseError) {
                    console.error(`Error parsing JSON: ${parseError}`);
                    vscode.window.showErrorMessage('Error parsing workspace data.');
                    resolve([]); // Resolve with empty array on parse error
                }
            });
        });
    }
}

class Workspace extends vscode.TreeItem {
    constructor(label, status, branch, last_commit, path, collapsibleState) {
        super(label, collapsibleState);
        this.path = path;
        this.tooltip = `${this.path} - ${last_commit}`;
        this.description = `[${status}] ${branch}`;
        this.command = {
            command: 'workspaces.open',
            title: 'Open Workspace',
            arguments: [this.path],
        };
        this.contextValue = 'workspace';
    }
}

function getWorkspaceBaseDir() {
    return new Promise((resolve, reject) => {
        exec('workspace --get-base-dir', (error, stdout, stderr) => {
            if (error) {
                console.error(`exec error: ${error}`);
                return reject(stderr);
            }
            resolve(stdout.trim());
        });
    });
}

function activate(context) {
    const workspaceProvider = new WorkspaceProvider();
    vscode.window.createTreeView('workspacesView', { treeDataProvider: workspaceProvider });


    const openCommand = vscode.commands.registerCommand('workspaces.open', (path) => {
        if (path) {
            const uri = vscode.Uri.file(path);
            vscode.commands.executeCommand('vscode.openFolder', uri, { forceNewWindow: true });
        }
    });

    const refreshCommand = vscode.commands.registerCommand('workspaces.refreshEntry', () => {
        workspaceProvider.refresh();
    });

    const warmCommand = vscode.commands.registerCommand('workspaces.warm', (workspace) => {
        if (workspace) {
            const terminal = vscode.window.createTerminal(`Workspace: ${workspace.label}`);
            terminal.sendText(`workspace warm`);
            terminal.show();
        }
    });

    const doctorCommand = vscode.commands.registerCommand('workspaces.doctor', (workspace) => {
        const terminal = vscode.window.createTerminal(`Workspace Doctor`);
        terminal.sendText('workspace doctor');
        terminal.show();
    });

    const deleteCommand = vscode.commands.registerCommand('workspaces.delete', async (workspace) => {
        if (workspace) {
            const confirm = await vscode.window.showWarningMessage(`Are you sure you want to delete the workspace "${workspace.label}"?`, { modal: true }, 'Delete');
            if (confirm === 'Delete') {
                try {
                    // This check is kept as a client-side validation, even though the CLI is now safer.
                    const baseDir = await getWorkspaceBaseDir();
                    if (!workspace.path.startsWith(baseDir)) {
                        vscode.window.showErrorMessage('Cannot delete a workspace outside of the workspace base directory.');
                        return;
                    }

                    // Sanitize the name to prevent shell command injection.
                    const workspaceName = workspace.label;
                    const sanitizedName = workspaceName.replace(/'/g, "'\\''");

                    const terminal = vscode.window.createTerminal(`Deleting: ${workspace.label}`);
                    // Use the new, safer name-based delete command.
                    terminal.sendText(`workspace delete '${sanitizedName}'`);
                    terminal.show();
                    
                    // Add a small delay to give the CLI time to delete the entry, then refresh.
                    setTimeout(() => workspaceProvider.refresh(), 1000);

                } catch (error) {
                    vscode.window.showErrorMessage(`Error deleting workspace: ${error}`);
                    workspaceProvider.refresh();
                }
            }
        }
    });

    context.subscriptions.push(openCommand, refreshCommand, warmCommand, doctorCommand, deleteCommand);
}

function deactivate() {}

module.exports = {
    activate,
    deactivate,
};
