{ lib
, host
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
      # extraEnv = ''
      #   	let EDITOR = "nvim"
      # '';
      extraConfig = ''
        				$env.config = {
        					edit_mode: "vi"
        					render_right_prompt_on_last_line: true
        					highlight_resolved_externals: true
        					color_config: {
        						shape_external: { fg: "cyan" }
        						shape_external_resolved: { fg: "blue" }
        						shape_internal: { fg: "green" }
        						shape_unknown: { fg: "red" }
        					}

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
        # Flake Stuff
        rebuild = "nixos-rebuild switch --use-remote-sudo --flake .#${host}";
        update = "nix flake update --use-remote-sudo";
        nixdev = "nix develop --command nushell";

        # Navigate Shell
        "..." = "z ../../";
        "...." = "z ../../../";
        "....." = "z ../../../..";
        l = "ls";
        la = "ls -a";
        ll = "ls -la";
        ea = "eza -a --icons";
        ela = "eza -la --icons --git";
        tr = "eza -Ta -L 3 --icons --git";
        trl = "eza -Ta -L --icons --git";
        h = "history";
        c = "clear";

        # Application aliases
        wsf = "windsurf";
        vi = "vim";
        svi = "sudo nvim";
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

    home.sessionVariables.SHELL = "nushell";
  };
}
