{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) concatMapStringsSep concatStringsSep isList mapAttrs mapAttrsToList mkOption toString types;
  cfg = config.${namespace}.system.env;
in
{
  options.${namespace}.system.env = mkOption {
    type = with types; attrsOf (oneOf [ str path (listOf (either str path)) ]);
    apply = mapAttrs (n: v: if isList v then concatMapStringsSep ":" (x: toString x) v else (toString v));
    default = { };
    description = "Set environment variables for systems";
  };

  config.environment = {
    sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_BIN_HOME = "$HOME/.local/bin";
      XDG_DESKTOP_DIR = "$HOME";
    };
    variables = {
      # To make some programs "XDG" compliant:
      LESSHISTFILE = "$HOME/.cache/less.history";
      WGETRC = "$HOME/.config/wgetrc";
    };
    extraInit = concatStringsSep "\n" (mapAttrsToList (n: v: ''export ${n}="${v}"'') cfg);
  };
}
