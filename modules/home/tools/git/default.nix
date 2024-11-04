{ lib
, config
, namespace
, ...
}:

let
  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.${namespace}) mkOpt enabled;
  cfg = config.${namespace}.tools.git;
  user = config.${namespace}.user;
in
{

  options.${namespace}.tools.git = {
    enable = mkEnableOption "Git";
    userName = mkOpt types.str user.name "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    signingKey = mkOpt types.str "${config.${namespace}.user.home}/.ssh/dtgagnon-ssh.pub" "The key ID to sign commits with.";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
  };

  config = mkIf cfg.enable {

    #TODO: Not sure how to reference the access-token inside my secrets file.
    # sops.secrets."github/access-token" = {
    #			mode = "400";
    # 		owner = config.users.users.dtgagnon.name;
    # 		inherit (config.users.users.dtgagnon) group;
    # };

    programs.git = {
      enable = true;
      inherit (cfg) userName userEmail;
      lfs = enabled;

      signing = {
        key = cfg.signingKey;
        inherit (cfg) signByDefault;
      };

      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core = {
          whitespace = "trailing-space,space-before-tab";
        };
      };
    };
  };
}
