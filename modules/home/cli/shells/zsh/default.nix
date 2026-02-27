{
  lib,
  host,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.shells.zsh;

  # Helper function to create conditional Zsh integrations
  mkZshIntegration = name: mkIf config.${namespace}.cli.${name}.enable true;
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

      dotDir = "${config.xdg.configHome}/zsh";
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
        # Nix Stuff
        rebuild = "nixos-rebuild switch --sudo --flake .#${host}";
        test = "nixos-rebuild test --sudo --flake .#${host}";
        update = "nix flake update";
        nixdev = "nix develop --command zsh";
        nr = "nix repl .#nixosConfigurations.DG-PC";

        # Navigate Shell
        "..." = "z ../../";
        "...." = "z ../../../";
        "....." = "z ../../../..";
        ls = "eza";
        l = "eza -lag";
        la = "eza -a";
        ll = "eza -la";
        ea = "eza -a --icons";
        ela = "eza -la --icons --git";
        tr = "eza -Ta --icons --git -L 3";
        trl = "eza -Ta --icons --git -L";
        h = "history";
        c = "clear";

        # Application aliases
        vi = "vim";
        svi = "sudo nvim";

        # Git aliases
        ga = "git add .";
        gph = "git push";
        gpl = "git pull";
      };
    };

    programs = {
      starship.enableZshIntegration = mkIf config.${namespace}.cli.shells.addons.starship.enable true;
      atuin.enableZshIntegration = mkZshIntegration "atuin";
      broot.enableZshIntegration = mkZshIntegration "broot";
      carapace.enableZshIntegration = mkZshIntegration "carapace";
      direnv.enableZshIntegration = mkZshIntegration "direnv";
      eza.enableZshIntegration = true;
      fzf.enableZshIntegration = mkZshIntegration "fzf";
      yazi.enableZshIntegration = mkZshIntegration "yazi";
      zoxide.enableZshIntegration = mkZshIntegration "zoxide";
    };

    home.sessionVariables.SHELL = lib.mkDefault "zsh";
  };
}
