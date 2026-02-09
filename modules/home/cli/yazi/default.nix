{ lib
, pkgs
, config
, namespace
, ...
}:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.yazi;
in
{
  options.${namespace}.cli.yazi = {
    enable = mkBoolOpt false "Whether to enable yazi terminal file manager";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      plugins = { };
      settings = {
        keymap = {
          manager = {
            prepend_keymap = [
              {
                on = [ "<A-d>" ];
                run = ''shell -- ripdrag --no-click --and-exit --icon-size 64 --target --all "$@" | while read filepath; do cp -fR "$filepath" .; done'';
                desc = "Drag-n-drop files to and from Yazi";
              }
            ];
          };
        };
        yazi = {
          #TOML
          preview = {
            image_delay = 500;
          };
          opener = {
            edit = [
              { run = "$EDITOR '$@'"; block = true; for = "unix"; }
            ];
            imgviewer = [
              { run = "nsxiv '$@'"; block = true; for = "unix"; }
            ];
            okular = [
              { run = "okular '$@'"; orphan = true; for = "unix"; }
            ];
          };
          open = {
            prepend_rules = [
              # Prioritize over yazi defaults and fallbacks
              { name = "*.pdf"; use = "okular"; }
              { mime = "image/*"; use = "imgviewer"; }
            ];
            # rules = [
            #   # Rewrite the full default rules set
            #   { }
            # ];
            # append_rules = [
            #   # Set fallback rules after yazi defaults
            #   { }
            # ];
          };
        };
      };
    };
    home.packages = with pkgs; [
      imagemagick
      ffmpegthumbnailer
      fontpreview
      unar
      poppler
      ripdrag
    ];
  };
}
