{ lib
, host
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.shells.nushell;

  inherit (config.lib.stylix) colors;
  # Helper function to create conditional Nushell integrations
  mkNushellIntegration = name: mkIf config.${namespace}.cli.${name}.enable true;
in
{
  options.${namespace}.cli.shells.nushell = {
    enable = mkBoolOpt false "Enables nu shell";
  };

  config = mkIf cfg.enable {
    programs.nushell = {
      enable = true;
      plugins = with pkgs.nushellPlugins; [
        query
        gstat
        highlight
        desktop_notifications
      ];

      extraConfig = ''
        $env.config = {
        	show_banner: false,
        	edit_mode: "vi"
        	render_right_prompt_on_last_line: true
        	highlight_resolved_externals: true
        	color_config: {
        		shape_external: { fg: "${colors.base0D}" }
        		shape_external_resolved: { fg: "${colors.base0C}" }
        		shape_internal: { fg: "${colors.base08}" }
        		shape_unknown: { fg: "${colors.base0E}" }
        	}
        }
      '';

      shellAliases = {
        # Nix Stuff
        rebuild = "nixos-rebuild switch --sudo --flake .#${host}";
        test = "nixos-rebuild test --sudo --flake .#${host}";
        update = "nix flake update";
        nixdev = "nix develop --command nushell";
        nr = "nix repl .#nixosConfigurations.DG-PC";

        # Navigate Shell
        "..." = "z ../../";
        "...." = "z ../../../";
        "....." = "z ../../../..";
        l = "ls";
        la = "ls -a";
        ll = "ls -la";
        ea = "eza -a --icons";
        ela = "eza -la --icons --git";
        tr = "eza -Ta --icons --git -L 3";
        trl = "eza -Ta --icons --git -L";
        h = "history";
        c = "clear";

        # Application aliases
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

    programs = {
      atuin.enableNushellIntegration = mkNushellIntegration "atuin";
      broot.enableNushellIntegration = mkNushellIntegration "broot";
      carapace.enableNushellIntegration = mkNushellIntegration "carapace";
      direnv.enableNushellIntegration = mkNushellIntegration "direnv";
      yazi.enableNushellIntegration = mkNushellIntegration "yazi";
      zoxide.enableNushellIntegration = mkNushellIntegration "zoxide";
    };

    home.sessionVariables.SHELL = "nushell";
  };
}

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
