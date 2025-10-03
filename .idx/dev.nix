{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"

  # Use https://search.nixos.org/packages to find packages
  packages = with pkgs; [
    ncurses      # Correctly adds the ncurses library
    autojump
    fzf
    rsync
    sqlite
    git
    curl
    jq
    gcc          # Includes the GCC compiler needed for ncurses development
  ];


  # Sets environment variables in the workspace
  env = {
    PATH = [
      "/home/user/Unlimited-Cloud-VM-Storage/bin"
      # The rest of the default PATH will be included automatically
    ];
  };

  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      # "vscodevim.vim"
      "google.gemini-cli-vscode-ide-companion"
    ];

    # Enable previews
    previews = {
      enable = true;
      previews = {
        # web = {
        #   # Example: run "npm run dev" with PORT set to IDX's defined port for previews,
        #   # and show it in IDX's web preview panel
        #   command = ["npm" "run" "dev"];
        #   manager = "web";
        #   env = {
        #     # Environment variables to set for your server
        #     PORT = "$PORT";
        #   };
        # };
      };
    };

    # Workspace lifecycle hooks
    workspace = {
      # Runs when a workspace is first created
      onCreate = {
        workspace-hook-on-create = "source $HOME/.config/workspace/workspace.sh";
        # Example: install JS dependencies from NPM
        # npm-install = "npm install";
      };
      # Runs when the workspace is (re)started
      onStart = {
        workspace-hook-on-start = "source $HOME/.config/workspace/workspace.sh";
      };
    };
  };
}
