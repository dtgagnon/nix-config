{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.shells.nushell;
in
{
  options.${namespace}.cli.shells.nushell = {
    enable = mkBoolOpt false "Enables nu shell";
  };

  config = mkIf cfg.enable {
    programs.nushell = {
      enable = true;

			extraConfig = ''
				$env.config = {
					show_banner: false,
				}
			'';

      # nu-abbr = {
      #   abbreviations = {
      #     #git
      #     ga = "git add";
      #     gaa = "git add --all .";
      #     gb = "git branch";
      #     gbd = "git branch -D";
      #     gcm = "git checkout main";
      #     gco = "git checkout";
      #     gcob = "git checkout -b";
      #     gd = "git diff";
      #     gdc = "git diff --cached";
      #     gds = "git diff --staged";
      #     gl = "git log";
      #     gm = "git commit -m";
      #     gma = "git commit --amend";
      #     gman = "git commit --amend --no-edit";
      #     gp = "git push";
      #     gpf = "git push --force";
      #     gph = "git push origin HEAD";
      #     gphu = "git push origin HEAD -u";
      #     gpm = "git pull origin main";
      #     gpuh = "git push upstream HEAD";
      #     gpt = "git push --tags";
      #     gs = "git status";
      #   };
      # };

      shellAliases = {
        # Build System
        rebuild = "nixos-rebuild switch --use-remote-sudo";
        update = "nix flake update --use-remote-sudo";
        nixdev = "nix develop --command nushell";

        # Navigate Shell
        "..." = "z ../../";
        "...." = "z ../../../";
        "....." = "z ../../../..";
        ll = "ls -la";
        l = "ls -a";
				lsa = "eza -la";
        la = "eza -a";
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
      enableNushellIntegration = true;
    };

    # programs.eza.enableNushellIntegration = true;
    programs.zoxide.enableNushellIntegration = true;
    programs.direnv.enableNushellIntegration = true;
  };
}
