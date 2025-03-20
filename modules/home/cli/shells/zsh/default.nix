{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.shells.zsh;
in
{
  options.${namespace}.cli.shells.zsh = {
    enable = mkBoolOpt false "Enables zsh shell";
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;

      autocd = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      dotDir = ".config/zsh/";
      history = {
        size = 10000;
        path = "$HOME/.config/zsh/.zsh_history";
        expireDuplicatesFirst = true;
        ignoreAllDups = true;
      };

      plugins = [
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.4.0";
            sha256 = "037wz9fqmx0ngcwl9az55fgkipb745rymznxnssr3rx9irb6apzg";
          };
        }
      ];

      zsh-abbr = {
        enable = true;
        abbreviations = {
          #git
          ga = "git add";
          gaa = "git add --all .";
          gb = "git branch";
          gbd = "git branch -D";
          gcm = "git checkout main";
          gco = "git checkout";
          gcob = "git checkout -b";
          gd = "git diff";
          gdc = "git diff --cached";
          gds = "git diff --staged";
          gl = "git log";
          gm = "git commit -m";
          gma = "git commit --amend";
          gman = "git commit --amend --no-edit";
          gp = "git push";
          gpf = "git push --force";
          gph = "git push origin HEAD";
          gphu = "git push origin HEAD -u";
          gpm = "git pull origin main";
          gpuh = "git push upstream HEAD";
          gpt = "git push --tags";
          gs = "git status";
        };
      };

      shellAliases = {
        # Build System
        rebuild = "nixos-rebuild switch --use-remote-sudo";
        update = "nix flake update --use-remote-sudo";
        nixdev = "nix develop --command zsh";

        # Navigate Shell
        "..." = "z ../../";
        "...." = "z ../../../";
        "....." = "z ../../../..";
        l = "eza -lag";
        ls = "eza";
        la = "eza -a";
        ll = "eza -la";
        tr = "eza -Ta -L 3";
        trl = "eza -Ta -L";
        svi = "sudo nvim";
        h = "history";
        c = "clear";

        # Application aliases
        vi = "vim";
      };
      initExtra = ''
        eval "$(zoxide init zsh)"
        eval "$(direnv hook zsh)"
      '';
    };

    programs.starship = {
      enable = true;
      settings = {
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red) ";
          vicmd_symbol = "[](bold blue) ";
        };
      };
    };
    programs.eza.enableZshIntegration = true;
    home.sessionVariables.EDITOR = "nvim";
  };
}
