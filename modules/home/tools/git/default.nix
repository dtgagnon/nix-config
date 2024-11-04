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
    # signingKey = mkOpt types.str "9762169A1B35EA68" "The key ID to sign commits with.";
    # signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
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

      #TODO: Look into signing, what is this, should I set it up for myself? What's the value?
      # signing = {
      #   key = cfg.signingKey;
      #   inherit (cfg) signByDefault;
      # };

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
