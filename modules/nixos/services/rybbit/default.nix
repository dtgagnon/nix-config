{
  lib,
  config,
  namespace,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.services.rybbit;
in
{
  imports = [ inputs.rybbix.nixosModules.default ];

  options.${namespace}.services.rybbit = {
    enable = mkEnableOption "Rybbit privacy-focused analytics platform";
  };

  config = mkIf cfg.enable {
    # Sops secret containing at minimum: BETTER_AUTH_SECRET=<random-string>
    # Optionally: CLICKHOUSE_PASSWORD, POSTGRES_PASSWORD, MAPBOX_TOKEN
    sops.secrets.rybbit-env = {
      sopsFile = lib.snowfall.fs.get-file "secrets/rybbit/env.yaml";
      format = "binary";
      owner = "rybbit";
      group = "rybbit";
      mode = "0400";
    };

    # Enable upstream module with sops secret and sensible defaults
    services.rybbit = {
      enable = true;
      secretsFile = config.sops.secrets.rybbit-env.path;
      settings.disableSignup = lib.mkDefault true;
      settings.disableTelemetry = lib.mkDefault true;
    };
  };
}
