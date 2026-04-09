{
  description = "Cross-platform development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    walls = {
      url = "github:hubertetcetera/walls-catppuccin-mocha";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    ...
  } @ inputs: let
    # ══════════════════════════════════════════════════════════════════════════
    # System Configuration
    # ══════════════════════════════════════════════════════════════════════════
    username = "batman";
    lib = nixpkgs.lib;

    # Optional features (toggle these on/off)
    features = {
      enableFunPackages = true; # Set to false to disable fun CLI tools
    };

    systems = {
      darwin = "aarch64-darwin";
      linux = "x86_64-linux";
    };

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

    # ══════════════════════════════════════════════════════════════════════════
    # Package Collections
    # ══════════════════════════════════════════════════════════════════════════

    sharedPackages = pkgs:
      with pkgs; [
        # Core tools
        neovim
        tmux
        git
        gh
        lazygit

        # Shell enhancements
        zsh-autosuggestions
        zsh-syntax-highlighting
        zoxide
        fzf

        # File tools
        fd
        ripgrep
        bat
        glow # markdown reader
        yazi
        lsd
        stow

        # Development
        nodejs
        rustup
        docker
        pnpm

        # Network tools
        xh

        # Utilities
        tree
        jq

        # Media & YouTube
        mpv # Media player
        ncspot
        youtube-tui

        # Message & Chat
        discordo

        # Other
        nerd-fonts.jetbrains-mono
        cmatrix
      ];

    # Fun CLI tools (optional - controlled by features.enableFunPackages)
    funPackages = pkgs:
      with pkgs; [
        cava
        clock-rs
        cowsay
        fortune
        figlet
        lolcat
        neofetch
      ];

    linuxOnlyPackages = pkgs:
      with pkgs; [
        brave # macOS uses Homebrew cask
        ghostty # macOS uses Homebrew cask
        xclip # Clipboard tool (macOS has pbcopy built-in)
      ];

    # ══════════════════════════════════════════════════════════════════════════
    # Home Manager Configuration
    # ══════════════════════════════════════════════════════════════════════════

    mkHomeConfig = pkgs: {
      home = {
        username = lib.mkForce username;
        homeDirectory = lib.mkForce (
          if pkgs.stdenv.isDarwin
          then "/Users/${username}"
          else "/home/${username}"
        );
        stateVersion = "25.05";

        # Dotfile symlinks
        file = {
          ".zshrc".source = ../zshrc/.zshrc;
          ".config/nvim".source = ../nvim;
          ".config/tmux/tmux.conf".source = ../tmux/tmux.conf;
          ".config/tmux/tmux.reset.conf".source = ../tmux/tmux.reset.conf;
          ".config/tmux/theme-auto-sync.sh".source = ../tmux/theme-auto-sync.sh;
          ".config/ghostty/config".source = ../ghostty/config;
          ".config/ghostty/themes".source = ../ghostty/themes;
          ".config/aerospace/aerospace.toml".source = ../aerospace/aerospace.toml;
          ".config/lazygit".source = ../lazygit;
          ".hammerspoon".source = ../hammerspoon;
          ".config/sketchybar".source = ../sketchybar;
          ".config/youtube-tui".source = ../youtube-tui;
        };

        # Packages
        packages =
          (sharedPackages pkgs)
          ++ (lib.optionals features.enableFunPackages (funPackages pkgs))
          ++ (lib.optionals pkgs.stdenv.isLinux (linuxOnlyPackages pkgs));
      };

      # Auto-install tmux plugin manager
      home.activation.installTpm = lib.mkAfter ''
        TPM_DIR="$HOME/.config/tmux/plugins/tpm"
        if [ ! -d "$TPM_DIR" ]; then
          ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        fi
      '';
    };

    # ══════════════════════════════════════════════════════════════════════════
    # macOS System Configuration
    # ══════════════════════════════════════════════════════════════════════════

    darwinSystemConfig = {
      nixpkgs = {
        hostPlatform = systems.darwin;
        config.allowUnfree = true;
      };

      nix.settings.experimental-features = ["nix-command" "flakes"];

      # System-level packages (user packages are in sharedPackages)
      environment.systemPackages = [];

      system = {
        primaryUser = username;
        configurationRevision = self.rev or self.dirtyRev or null;
        stateVersion = 6;
      };
    };

    darwinHomebrewConfig = {
      homebrew = {
        enable = true;

        taps = [
          "nikitabobko/tap"
          "FelixKratz/formulae"
        ];

        brews = [
          "dockutil"
          "sketchybar"
          "borders"
        ];

        casks = [
          # Terminal & Window Management
          "ghostty"
          "aerospace"

          # Utilities
          "sf-symbols"
          "raycast"
          "cleanshot"
          "betterdisplay"

          # Browsers & Communication
          "brave-browser"
          "superhuman"
          "beeper"

          # Productivity
          "obsidian"
          "numi"

          # Security & Privacy
          "1password"
          "mullvad-vpn"

          # File Management
          "cyberduck"
          "macfuse"
          "veracrypt"

          # Media & Entertainment
          "stremio"
          "fathom"

          # Other
          "todoist-app"
        ];

        caskArgs.appdir = "/Applications";

        onActivation = {
          autoUpdate = true;
          cleanup = "zap";
        };
      };
    };

    darwinSystemDefaults = {
      system.defaults = {
        dock = {
          autohide = true;
          show-recents = false;
          tilesize = 48;
          persistent-apps = [
            {app = "/System/Applications/Apps.app";}
            {app = "/Applications/Brave Browser.app";}
            {app = "/System/Applications/System Settings.app";}
            {app = "/Applications/Ghostty.app";}
          ];
        };

        screencapture.location = "~/Pictures/screenshots";
      };

      security.pam.services.sudo_local.touchIdAuth = true;
    };
  in {
    # ══════════════════════════════════════════════════════════════════════════
    # Home Manager Standalone Configurations
    # ══════════════════════════════════════════════════════════════════════════

    homeConfigurations = {
      "${username}@meow" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs systems.darwin;
        modules = [
          (mkHomeConfig (mkPkgs systems.darwin))
        ];
      };

      "${username}@linux-desktop" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs systems.linux;
        extraSpecialArgs = {inherit inputs;};
        modules = [
          (mkHomeConfig (mkPkgs systems.linux))
          ./modules/walls.nix
        ];
      };
    };

    # ══════════════════════════════════════════════════════════════════════════
    # macOS System Configuration (nix-darwin)
    # ══════════════════════════════════════════════════════════════════════════

    darwinConfigurations.meow = nix-darwin.lib.darwinSystem {
      system = systems.darwin;
      specialArgs = {inherit inputs username;};

      modules = [
        # System configuration
        darwinSystemConfig
        darwinHomebrewConfig
        darwinSystemDefaults

        # Home Manager integration
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {inherit inputs;};
            users.${username} = {
              imports = [
                (mkHomeConfig (mkPkgs systems.darwin))
                ./modules/walls.nix
              ];
            };
          };
        }
      ];
    };
  };
}
