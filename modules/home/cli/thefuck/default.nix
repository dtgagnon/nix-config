{
  config,
  lib,
  namespace,
  ...
}:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.thefuck;
in {
  options.${namespace}.cli.thefuck = {
    enable = mkBoolOpt false "Whether to enable thefuck command correction tool";
  };

  config = mkIf cfg.enable {
    programs.thefuck = {
      enable = true;
      
      settings = {
        rules = ["cd_parent" "git_push" "mkdir_p" "sudo"];
        wait_command = 3;  # Seconds to wait for command to finish
        require_confirmation = true;
        no_colors = false;
        priority = {
          "git_push:force_with_lease" = 900;
          "git_checkout_main" = 800;
          "cd_parent" = 100;
        };
        exclude_rules = ["git_add_force"];  # Potentially dangerous rules to exclude
      };
    };
  };
}
