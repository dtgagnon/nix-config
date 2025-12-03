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
        	keybindings: [
        		{
        			name: fzf_file_search
        			modifier: control
        			keycode: char_t
        			mode: [emacs vi_insert vi_normal]
        			event: {
        				send: executehostcommand
        				cmd: "commandline edit --insert (fzf-file-widget)"
        			}
        		}
        		{
        			name: fzf_dir_search
        			modifier: alt
        			keycode: char_c
        			mode: [emacs vi_insert vi_normal]
        			event: {
        				send: executehostcommand
        				cmd: "cd (fzf-dir-widget); commandline edit --replace '''"
        			}
        		}
        	]
        }

        # Helper function to find git root directory
        def --env get-git-root [] {
          let result = (do -i { git rev-parse --show-toplevel } | complete)
          if $result.exit_code == 0 {
            $result.stdout | str trim
          } else {
            $env.PWD
          }
        }

        # Context-aware fzf file search (searches from git root if in a repo)
        def --env fzf-file-widget [] {
          let root = (get-git-root)
          cd $root
          let selection = (fd --hidden --strip-cwd-prefix --max-depth 6 --exclude .git --exclude result --exclude .result --exclude 'result-*' --exclude .direnv --exclude .cache --exclude node_modules --exclude target --exclude dist --exclude dist-newstyle --exclude .stack-work --exclude __pycache__ --exclude .pytest_cache --exclude .mypy_cache --exclude .cargo --exclude .venv --exclude venv | fzf --preview 'if (ls {} | get type.0) == "dir" { eza --tree --color=always {} | head -200 } else { bat -n --color=always --line-range :500 {} }')
          if ($selection | is-not-empty) {
            $selection
          }
        }

        # Context-aware fzf directory search (searches from git root if in a repo)
        def --env fzf-dir-widget [] {
          let root = (get-git-root)
          cd $root
          let selection = (fd --type=d --hidden --strip-cwd-prefix --max-depth 6 --exclude .git --exclude result --exclude .result --exclude 'result-*' --exclude .direnv --exclude .cache --exclude node_modules --exclude target --exclude dist --exclude dist-newstyle --exclude .stack-work --exclude __pycache__ --exclude .pytest_cache --exclude .mypy_cache --exclude .cargo --exclude .venv --exclude venv | fzf --preview 'eza --tree --color=always {} | head -200')
          if ($selection | is-not-empty) {
            cd $selection
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
      # fzf doesn't have enableNushellIntegration - using custom widgets instead
      yazi.enableNushellIntegration = mkNushellIntegration "yazi";
      zoxide.enableNushellIntegration = mkNushellIntegration "zoxide";
    };

    home = {
      extraDependencies = config.programs.nushell.plugins;
      sessionVariables.SHELL = "nushell";
    };
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
