{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.monitors;
in
{
  options.${namespace}.hardware.monitors = {
    pip = {
      enable = mkBoolOpt false "Enable PiP monitor toggle feature";

      dgpuMonitor = mkOpt
        (
          types.nullOr (
            types.submodule {
              options = {
                name = mkOpt types.str "" "GPU input port for monitor (e.g., HDMI-A-5, DP-1)";
                spec = mkOpt types.str "" "Hyprland monitor spec (resolution@refresh,position,scale)";
              };
            }
          )
        )
        null "Monitor connected to dGPU";

      igpuMonitor = mkOpt
        (
          types.nullOr (
            types.submodule {
              options = {
                name = mkOpt types.str "" "Monitor name (e.g., DP-1)";
                spec = mkOpt types.str "" "Hyprland monitor spec (resolution@refresh,position,scale)";
              };
            }
          )
        )
        null "Monitor connected to iGPU";
    };
  };

  config = mkIf (cfg.pip.enable && cfg.pip.dgpuMonitor != null && cfg.pip.igpuMonitor != null) {
    # Generate JSON config file for scripts to read
    environment.etc."hyprland-pip-monitors.json".text = builtins.toJSON {
      dgpuMonitor = {
        name = cfg.pip.dgpuMonitor.name;
        spec = cfg.pip.dgpuMonitor.spec;
      };
      igpuMonitor = {
        name = cfg.pip.igpuMonitor.name;
        spec = cfg.pip.igpuMonitor.spec;
      };
    };
  };
}
