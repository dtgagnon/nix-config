{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.shells.fish;
in
{
  options.${namespace}.cli.shells.fish = {
    enable = mkBoolOpt false "Enables fish shell";
  };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;

      preferAbbrs = true;
      shellAbbrs = {
        #flakes
        rebuild = "nixos-rebuild switch --use-remote-sudo";
        flakeup = "nix flake update";
        nixsh = "nix-shell -p ";
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

      shellAliases = {
        # Build System
        # update = "nixos-rebuild switch --use-remote-sudo";
        # flakeup = "nix flake update --use-remote-sudo";
        nixdev = "nix develop --command fish";

        # Navigate Shell
        "..." = "z ../../";
        "...." = "z ../../../";
        "....." = "z ../../../..";
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
      # enableFishIntegration = true;
    };
    programs.dircolors.enableFishIntegration = true;
    # programs.direnv.enableFishIntegration = true;
    programs.eza.enableFishIntegration = true;
    programs.fzf.enableFishIntegration = true;
    programs.nix-index.enableFishIntegration = true;
    programs.zoxide.enableFishIntegration = true;
  };

}
