{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.${namespace}.services.comfyui;
in
{
  options.${namespace}.services.comfyui = {
    enable = mkEnableOption "ComfyUI node-based image generation interface";
    package = mkOption {
      type = types.package;
      default = pkgs.${namespace}.comfyui;
      description = "The ComfyUI package to use";
    };
    port = mkOption {
      type = types.port;
      default = 8188;
      description = "Port for the ComfyUI web interface";
    };
    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind the ComfyUI server to";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/comfyui";
      description = "Directory for ComfyUI models, outputs, custom nodes, and user data";
    };
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command-line arguments passed to ComfyUI";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.comfyui = {
      description = "ComfyUI - Node-based AI image generation";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "comfyui";
        Group = "comfyui";
        WorkingDirectory = cfg.dataDir;
        StateDirectory = "comfyui";
        Restart = "on-failure";
        RestartSec = 5;
        ExecStart = lib.concatStringsSep " " (
          [
            "${cfg.package}/bin/comfyui"
            "--listen ${cfg.listenAddress}"
            "--port ${toString cfg.port}"
            "--output-directory ${cfg.dataDir}/output"
            "--input-directory ${cfg.dataDir}/input"
          ]
          ++ cfg.extraArgs
        );
      };

      environment = {
        HOME = cfg.dataDir;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/models 0755 comfyui comfyui -"
      "d ${cfg.dataDir}/input 0755 comfyui comfyui -"
      "d ${cfg.dataDir}/output 0755 comfyui comfyui -"
      "d ${cfg.dataDir}/custom_nodes 0755 comfyui comfyui -"
      "d ${cfg.dataDir}/user 0755 comfyui comfyui -"
    ];

    users.users.comfyui = {
      isSystemUser = true;
      group = "comfyui";
      extraGroups = [ "video" "render" ];
      home = cfg.dataDir;
    };
    users.groups.comfyui = { };

    ${namespace}.system.preservation.extraSysDirs = [
      cfg.dataDir
    ];
  };
}
