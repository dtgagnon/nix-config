{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.terminals.wezterm;

  toLuaTable = with builtins; value:
    if isBool value
    then
      if value
      then "true"
      else "false"
    else if isString value
    then toJSON value
    else if isInt value || isFloat value
    then toString value
    else if isList value
    then ''{ ${concatStringsSep ", " (map toLuaTable value)} }''
    else if isAttrs value
    then ''{ ${concatStringsSep ", " (map (k: ''["${k}"] = ${toLuaTable value.${k}}'') (attrNames value))} }''
    else throw "Unsupported type: ${typeOf value}";
in
{
  options.${namespace}.apps.terminals.wezterm = {
    enable = mkBoolOpt false "Enable wezterm terminal emulator";
    alias = mkOpt (types.listOf types.str) [ ] "List of aliases";
    font = mkOpt (types.nullOr types.str) null "Optionally declare the wezterm font";
    themes = mkOpt (types.attrsOf types.str) { } "An attribute set of strings for wezterm theme declaration";
    settings = mkOpt types.attrs { } "An attribute set for wezterm settings";
    extraConfig = mkOpt types.str "" "Additional lua for wezterm configuration";
  };

  config = mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      # package = mkIf pkgs.stdenv.isLinux (
      #   let
      #     term = ''${pkgs.wezterm}/bin/wezterm "$@"'';
      #     aliases = map (n: pkgs.writeShellScriptBin n term) cfg.alias;
      #   in
      #   [ pkgs.wezterm ] ++ aliases
      # );
      # colorSchemes = {
      #   myCoolTheme = {
      #     ansi = [
      #       "#222222"
      #       "#D14949"
      #       "#48874F"
      #       "#AFA75A"
      #       "#599797"
      #       "#8F6089"
      #       "#5C9FA8"
      #       "#8C8C8C"
      #     ];
      #     brights = [
      #       "#444444"
      #       "#FF6D6D"
      #       "#89FF95"
      #       "#FFF484"
      #       "#97DDFF"
      #       "#FDAAF2"
      #       "#85F5DA"
      #       "#E9E9E9"
      #     ];
      #     background = "#1B1B1B";
      #     cursor_bg = "#BEAF8A";
      #     cursor_border = "#BEAF8A";
      #     cursor_fg = "#1B1B1B";
      #     foreground = "#BEAF8A";
      #     selection_bg = "#444444";
      #     selection_fg = "#E9E9E9";
      #   };
      # };
      extraConfig =
        let
          wayland_scheme = ''
            local themes = ${toLuaTable cfg.themes}

            function get_appearance()
              if wezterm.gui then
                return wezterm.gui.get_appearance()
              end
              return "Dark"
            end

            function scheme_for_appearance(appearance)
              if appearance:find 'Dark' then
                return themes.Dark or ""
              else
                return themes.Light or ""
              end
            end

            config.color_scheme = scheme_for_appearance(get_appearance())
          '';
        in
        ''
          local wezterm = require "wezterm"
          local config = ${toLuaTable cfg.settings}
          ${cfg.extraLua}

          ${
            if cfg.font != null
            then ''config.font = wezterm.font("${cfg.font}")''
            else ""
          }

          ${
            if pkgs.stdenv.isLinux
            then wayland_scheme
            else ""
          }

          return config
        '';
    };
    home.sessionVariables.TERMINAL = "wezterm";
  };
}
